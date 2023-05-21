#Requires AutoHotkey v1.1.35+

class AuraSyncAction extends MicrophoneAction {
    static TypeName := "AuraSync", AuraServiceFilePath:= A_ScriptDir "\Lib\AuraService.ahk"
        , AuraServiceName := "AuraService"
        , AuraServicePID:=""
        , AuraServiceHwnd:=""

    __New(muteColor, unmuteColor, releaseDelay){
        this.muteColor := muteColor
        this.unmuteColor := unmuteColor
        this.releaseDelay := releaseDelay
        this.serviceRunCommand := this._formatAction()

        if (!AuraSyncAction.AuraServicePID) {
            this.initAuraService()
            OnExit(ObjBindMethod(this, "_stopAuraService"))
        }
    }

    run(controller) {
        if(!AuraSyncAction.AuraServicePID || !AuraSyncAction.AuraServiceHwnd){
            util_log("[AuraSyncAction] AuraService is not running, skipping action")
            return
        }

        if (!controller.shouldCallFeedback)
            return

        pushedDelay := controller.isPushToTalk? 0 : this.releaseDelay
        if (controller.state) {
            color := this.muteColor
            releaseDelay := controller.isInverted? pushedDelay : this.releaseDelay
        } else {
            color := this.unmuteColor
            releaseDelay := controller.isInverted? this.releaseDelay : pushedDelay
        }

        data := JSON.Dump({ type: "setAllDevicesColor", color: color, releaseDelay: releaseDelay})

        IPC_Send(AuraSyncAction.AuraServiceHwnd, data)
    }

    initAuraService(){
        try {
            util_log("[AuraSyncAction] Starting AuraService with command: " this.serviceRunCommand)

            Run, % this.serviceRunCommand, A_ScriptDir, Hide, childPID
            AuraSyncAction.AuraServicePID := childPID

            DetectHiddenWindows, On

            WinWait, % "ahk_pid " AuraSyncAction.AuraServicePID, , 1

            WinGet, winHwnd, ID, % "ahk_pid " AuraSyncAction.AuraServicePID " ahk_class AutoHotkey"
            AuraSyncAction.AuraServiceHwnd := winHwnd

            DetectHiddenWindows, Off

            util_log("[AuraSyncAction] Started AuraService with PID: " AuraSyncAction.AuraServicePID " and HWND: " AuraSyncAction.AuraServiceHwnd)
        } catch e {
            util_log("[AuraSyncAction] Failed to start AuraService : " e.Message)
            return false
        }
        return true
    }

    _stopAuraService(){
        util_log("[AuraSyncAction] Stopping AuraService with PID: " AuraSyncAction.AuraServicePID)
        IPC_Send(AuraSyncAction.AuraServiceHwnd, JSON.Dump({ type: "stopService" }))
        Sleep, 100

        DetectHiddenWindows, On
        if (WinExist("ahk_pid " AuraSyncAction.AuraServicePID)) {
            util_log("[AuraSyncAction] Killing AuraService with PID: " AuraSyncAction.AuraServicePID)
            Process, Close, % AuraSyncAction.AuraServicePID
        }
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
}