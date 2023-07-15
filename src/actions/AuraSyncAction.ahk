#Requires AutoHotkey v1.1.36+

class AuraSyncAction extends MicrophoneAction {
    static TypeName := "AuraSync", AuraServiceFilePath:= A_ScriptDir "\AuraService.ahk"
        , AuraServiceName := "AuraService"
        , AuraServicePID := ""
        , AuraServiceHwnd := ""
        , AuraServiceCommand := AuraSyncAction._formatAction()
        , ServiceEnabled := true
        , AuraReady := false
        , InitialState := ""

    __New(muteColor, unmuteColor){
        this.muteColor := muteColor
        this.unmuteColor := unmuteColor

        if (!AuraSyncAction.AuraServicePID) {
            AuraSyncAction.initAuraService()
        }
    }

    run(controller) {
        if (!AuraSyncAction.ServiceEnabled)
            return

        color := controller.state ? this.muteColor : this.unmuteColor

        if (!AuraSyncAction.AuraServicePID || !AuraSyncAction.AuraServiceHwnd || !AuraSyncAction.AuraReady) {
            util_log("[AuraSyncAction] Aura Sync is not initialized yet, skipping action")
            AuraSyncAction.InitialState := { color: color }
            return
        }
        
        if (AuraSyncAction.InitialState) {
            color := AuraSyncAction.InitialState.color
            AuraSyncAction.InitialState := ""
        }

        this.sendAction("setAllDevicesColor", color, 50)
    }

    sendAction(type, color:="", timeout:=500){
        data := JSON.Dump({ type: type, color: color})

        if (!IPC_Send(AuraSyncAction.AuraServiceHwnd, data, timeout))
            util_log("[AuraSyncAction] Failed to send data to AuraService in " timeout " ms")
    }

    initAuraService(){
        try {
            util_log("[AuraSyncAction] Starting AuraService with command: " AuraSyncAction.AuraServiceCommand)
            Run, % this.AuraServiceCommand, A_ScriptDir, Hide, childPID

            AuraSyncAction.AuraServicePID := childPID
            AuraSyncAction.AuraServiceHwnd := util_getAhkMainWindowHwnd(AuraSyncAction.AuraServicePID)

            util_log("[AuraSyncAction] Started AuraService with PID: " AuraSyncAction.AuraServicePID " and HWND: " AuraSyncAction.AuraServiceHwnd)
            OnExit(ObjBindMethod(AuraSyncAction, "stopAuraService"), -1)

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
        return { "Type": this.TypeName, "MuteColor": this.muteColor, "UnmuteColor": this.unmuteColor }
    }

    __Delete(){
        this.sendAction("pauseService",, 1)
    }

    __OnPowerChange(wParam){
        static lastReset := ""

        if(wParam = 0x12){
            if(lastReset && A_TickCount - lastReset < 2000)
                return

            util_log("[AuraSyncAction] Detected a power state change, resetting AuraService")
            lastReset := A_TickCount

            resetMethod := ObjBindMethod(AuraSyncAction, "sendAction", "resetService",, 1)
            SetTimer, % resetMethod, -1000
        }
    }
}