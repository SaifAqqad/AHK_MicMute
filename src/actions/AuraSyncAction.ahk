#Requires AutoHotkey v1.1.35+

class AuraSyncAction extends MicrophoneAction {
    static TypeName := "AuraSync", AuraServiceFilePath:= A_ScriptDir "\AuraService.ahk"
        , AuraServiceName := "AuraService"
        , AuraServicePID := ""
        , AuraServiceHwnd := ""
        , AuraServiceCommand := AuraSyncAction._formatAction()
        , ServiceEnabled := true

    __New(muteColor, unmuteColor, releaseDelay){
        this.muteColor := muteColor
        this.unmuteColor := unmuteColor
        this.releaseDelay := releaseDelay

        if (!AuraSyncAction.AuraServicePID) {
            AuraSyncAction.initAuraService()
        }
    }

    run(controller) {
        if(!AuraSyncAction.AuraServicePID || !AuraSyncAction.AuraServiceHwnd){
            util_log("[AuraSyncAction] AuraService is not running, skipping action")
            return
        }

        if (!AuraSyncAction.ServiceEnabled || (this.releaseDelay > 0 && !controller.shouldCallFeedback))
            return

        pushedDelay := controller.isPushToTalk? 0 : this.releaseDelay
        if (controller.state) {
            color := this.muteColor
            releaseDelay := controller.isInverted? pushedDelay : this.releaseDelay
        } else {
            color := this.unmuteColor
            releaseDelay := controller.isInverted? this.releaseDelay : pushedDelay
        }

        this.sendAction("setAllDevicesColor", color, releaseDelay, 50)
    }

    sendAction(type, color:="", releaseDelay:="", timeout:=500){
        data := JSON.Dump({ type: type, color: color, releaseDelay: releaseDelay})

        if (!IPC_Send(AuraSyncAction.AuraServiceHwnd, data, timeout))
            util_log("[AuraSyncAction] Failed to send data to AuraService in " timeout " ms")
    }

    initAuraService(){
        try {
            util_log("[AuraSyncAction] Starting AuraService with command: " AuraSyncAction.AuraServiceCommand)
            Run, % this.AuraServiceCommand, A_ScriptDir, Hide, childPID

            AuraSyncAction.AuraServicePID := childPID
            AuraSyncAction.AuraServiceHwnd := util_getMainWindowHwnd(AuraSyncAction.AuraServicePID)

            util_log("[AuraSyncAction] Started AuraService with PID: " AuraSyncAction.AuraServicePID " and HWND: " AuraSyncAction.AuraServiceHwnd)
            OnExit(ObjBindMethod(AuraSyncAction, "stopAuraService"))
        } catch e {
            util_log("[AuraSyncAction] Failed to start AuraService : " e.Message)
            return false
        }
        return true
    }

    stopAuraService(){
        DetectHiddenWindows, On

        util_log("[AuraSyncAction] Stopping AuraService with PID: " AuraSyncAction.AuraServicePID)
        AuraSyncAction.sendAction("stopService")
        Sleep, 100

        if (WinExist("ahk_pid " AuraSyncAction.AuraServicePID)) {
            util_log("[AuraSyncAction] Killing AuraService with PID: " AuraSyncAction.AuraServicePID)
            Process, Close, % AuraSyncAction.AuraServicePID
        }

        AuraSyncAction.AuraServicePID:= ""
        AuraSyncAction.AuraServiceHwnd:= ""
        DetectHiddenWindows, Off
    }

    _formatAction(){
        return A_IsCompiled
            ? Format("""{}"" /script *{} {}", A_AhkPath, AuraSyncAction.AuraServiceName, DllCall("GetCurrentProcessId"))
            : Format("""{}"" ""{}"" {}", A_AhkPath, AuraSyncAction.AuraServiceFilePath, DllCall("GetCurrentProcessId"))
    }

    getConfig(){
        return { "Type": this.TypeName, "MuteColor": this.muteColor, "UnmuteColor": this.unmuteColor, "ReleaseDelay": this.releaseDelay }
    }

    __Delete(){
        this.sendAction("pauseService",,, 1)
    }
}