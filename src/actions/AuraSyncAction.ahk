#Requires AutoHotkey v1.1.35+

class AuraSyncAction extends MicrophoneAction {
    static TypeName := "AuraSync", AuraServiceFilePath:= A_ScriptDir "\AuraService.ahk"
        , AuraServiceName := "AuraService"
        , AuraServicePID := ""
        , AuraServiceHwnd := ""
        , AuraServiceCommand := AuraSyncAction._formatAction()
        , ServiceEnabled := true
        , AuraReady := false

    __New(muteColor, unmuteColor, releaseDelay){
        this.muteColor := muteColor
        this.unmuteColor := unmuteColor
        this.releaseDelay := releaseDelay

        if (!AuraSyncAction.AuraServicePID) {
            AuraSyncAction.initAuraService()
        }
    }

    run(controller) {
        if(!AuraSyncAction.AuraServicePID || !AuraSyncAction.AuraServiceHwnd || !AuraSyncAction.AuraReady){
            util_log("[AuraSyncAction] Aura Sync is not initialized yet, skipping action")
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

            OnMessage(536, ObjBindMethod(AuraSyncAction, "__OnPowerChange")) ; WM_POWERBROADCAST=536
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
        local debug := Arg_isDebug || A_DebuggerName ? "/debug" : ""
            , command:= A_IsCompiled ? "/script *" AuraSyncAction.AuraServiceName : """" AuraSyncAction.AuraServiceFilePath """"

        return Format("""{}"" {} {} {}", A_AhkPath, command, DllCall("GetCurrentProcessId"), debug)
    }

    getConfig(){
        return { "Type": this.TypeName, "MuteColor": this.muteColor, "UnmuteColor": this.unmuteColor, "ReleaseDelay": this.releaseDelay }
    }

    __Delete(){
        this.sendAction("pauseService",,, 1)
    }

    __OnPowerChange(wParam){
        static lastReset := ""

        if(wParam = 0x12){
            if(lastReset && A_TickCount - lastReset < 2000)
                return

            util_log("[AuraSyncAction] Detected a power state change, resetting AuraService")
            lastReset := A_TickCount

            resetMethod := ObjBindMethod(AuraSyncAction, "sendAction", "resetService")
            SetTimer, % resetMethod, -1000
        }
    }
}