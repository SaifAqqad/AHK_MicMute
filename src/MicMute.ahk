#Requires AutoHotkey v1.1.36+

;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-Let UI = %A_ScriptDir%\UI\config
;@Ahk2Exe-Let Version = 1.3.1
;@Ahk2Exe-IgnoreBegin
    U_Version:= "1.3.1"
;@Ahk2Exe-IgnoreEnd
;@Ahk2Exe-SetMainIcon %U_Res%\icons\1000.ico
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-SetDescription MicMute
;@Ahk2Exe-Base ..\AutoHotkeyU64.exe

#NoEnv
SetBatchLines -1
SetWorkingDir %A_ScriptDir%

#InstallMouseHook
#InstallKeybdHook
#SingleInstance force
#MaxThreadsPerHotkey 1

; /Lib
#Include, <WinUtils>
#Include, <StackSet>
#Include, <AuraSync>
#Include, <SoundPlayer>
#Include, <DisplayDevices>
#Include, <B64>
#Include, <IPC>

; ahkpm
#Include, %A_ScriptDir%\..\ahkpm-modules\github.com\
#Include, G33kDude\Neutron.ahk\Neutron.ahk
#Include, SaifAqqad\cJson.ahk\Dist\JSON.ahk
#Include, SaifAqqad\VA.ahk\VA.ahk
#Include, SaifAqqad\VMR.ahk\dist\VMR.ahk
#Include, mmikeww\AHKv2-Gdip\Gdip_All.ahk

; MicMute scripts
#Include, %A_ScriptDir%
#Include, HotkeyManager.ahk
#Include, ResourcesManager.ahk
#Include, MicrophoneController.ahk
#Include, VoicemeeterController.ahk
#Include, Updater.ahk

#Include, %A_ScriptDir%\actions
#Include, MicrophoneAction.ahk
#Include, PowershellAction.ahk
#Include, ProgramAction.ahk
#Include, AuraSyncAction.ahk

#Include, %A_ScriptDir%\config
#Include, ProfileTemplate.ahk
#Include, MicrophoneTemplate.ahk
#Include, Config.ahk

#Include, %A_ScriptDir%\UI
#Include, OSD.ahk
#Include, Overlay.ahk
#Include, Tray.ahk

#Include, %A_ScriptDir%\UI\config
#Include, HotkeyPanel.ahk
#Include, UITemplates.ahk
#Include, UI.ahk
#Include, UpdaterUI.ahk

#Include, %A_ScriptDir%\UI\config\actions
#Include, ActionEditor.ahk
#Include, PowershellActionEditor.ahk
#Include, ProgramActionEditor.ahk
#Include, AuraSyncActionEditor.ahk

Global A_startupTime:= A_TickCount
    , config_obj
    , current_profile
    , mic_controllers
    , mute_sound
    , unmute_sound
    , ptt_on_sound
    , ptt_off_sound
    , watched_profiles
    , watched_profile
    , mic_actions
    , last_modif_time
    , arg_isDebug:=0
    , arg_profile:=""
    , arg_noUI:=0
    , arg_reload:= 0
    , arg_logFile:="*"
    , arg_isUpdater:=0
    , arg_installPath:=""
    , args_str:=""
    , resources_obj:= new ResourcesManager()
    , isFirstLaunch:=0
    , isAfterUpdate:=0
    , A_Version:= A_IsCompiled? util_getFileSemVer(A_ScriptFullPath) : U_Version
    , sound_player
    , osd_wnd
    , overlay_wnd
    , A_log:=""
    , A_DebuggerName:= A_DebuggerName
    , updater_obj:= new Updater(A_ScriptDir, Func("util_log"))
    , updater_UI:=""
    , WM_SETTINGCHANGE:= 0x001A
    , WM_DEVICECHANGE := 0x0219

; parse cli args
parseArgs()
tray_defaults()
util_log("MicMute v" . A_Version)
util_log(Format("[Main] Running as user {}, A_IsAdmin = {}", A_UserName, A_IsAdmin))
OnError(Func("util_log"))
if(arg_isUpdater){
    util_log("[Main] Updater mode")
    tray_init_updater()
    updater_UI:= new UpdaterUI()
    return
}else{
    try FileDelete, %A_Temp%\MicMuteUpdater.exe
}
; create config gui window
if(!arg_noUI)
    UI_create(Func("reloadMicMute"))
; initilize micmute
initilizeMicMute(arg_profile)
OnExit(Func("exitMicMute"), -1)
; listen for sys theme changes
OnMessage(WM_SETTINGCHANGE, "updateSysTheme")
; listen for window changes
registerWindowHook()
; run the update checker once, 10 seconds after launching
if(A_IsCompiled && !arg_reload && config_obj.AllowUpdateChecker=1){
    cfunc:= ObjBindMethod(updater_obj, "CheckForUpdates")
    SetTimer, % cfunc, -10000
}
A_startupTime:= A_TickCount - A_startupTime
util_log("[Main] MicMute startup took " A_startupTime "ms")

initilizeMicMute(default_profile:="", exportConfig:=1){
    util_log("[Main] Initilizing MicMute")

    ;make sure hotkeys are disabled before reinitilization
    if(mic_controllers)
        for _i,mic in mic_controllers
            mic.disableController()

    ;destroy existing guis
    overlay_wnd.destroy()
    osd_wnd.destroy()

    ;initilize globals
    config_obj:= new Config()
        , osd_wnd:=""
        , overlay_wnd:=""
        , mic_controllers:=""
        , watched_profiles:= Array()
        , current_profile:=""
        , watched_profile:=""
        , mute_sound:=""
        , unmute_sound:=""
        , ptt_on_sound:=""
        , ptt_off_sound:=""
        , mic_actions:=""
        , last_modif_time:= ""
        , sound_player:=""
        , auraServiceEnabled:= ""

    tray_defaults()
    for _i,profile in config_obj.Profiles {
        ; Add profiles with linked apps to watched_profiles
        if (profile.LinkedApp)
            watched_profiles.Push(profile)
        ; Check if AuraSyncAction is used in any profile and initilize AuraService
        for _j, action in profile.MicrophoneActions {
            if (action.Type = AuraSyncAction.TypeName && !AuraSyncAction.AuraServicePID) {
                auraServiceEnabled := true
                break
            }
        }
    }

    ; export the processed config object
    if(exportConfig)
        config_obj.exportConfig()

    ;enable linked apps timer
    SetTimer, checkLinkedApps, % watched_profiles.Length()? 3000 : "Off"
    ;enable checkConfigDiff timer
    setTimer, checkConfigDiff, 3000

    ;update theme variables
    updateSysTheme()
    if(config_obj.AllowUpdateChecker==-1){
        MsgBox, 36, MicMute, Allow MicMute to connect to the internet and check for updates on startup?
        IfMsgBox, Yes
            config_obj.AllowUpdateChecker:= 1
        IfMsgBox, No
            config_obj.AllowUpdateChecker:= 0
    }

    ;on first launch -> immediately call editConfig()
    if(isFirstLaunch){
        current_profile:= config_obj.Profiles[1]
        editConfig()
        return
    }

    ;switch to the default profile
    switchProfile(default_profile)

    if(auraServiceEnabled)
        SetTimer, initAuraService, -20
}

switchProfile(p_name:=""){
    Critical, On

    ;turn off profile-specific timers
    try SetTimer, checkIsIdle, Off

    ;destroy existing guis
    overlay_wnd.destroy()
    osd_wnd.destroy()
    sound_player.__free()

    ;reset tray menu
    tray_init()

    ;uncheck the profile in the tray menu
    Menu, profiles, Uncheck, % current_profile.ProfileName

    ;unmute and disable hotkeys for all existing microphones
    if(mic_controllers){
        for _i, mic in mic_controllers{
            mic.setMuteState(0, 0)
            mic.disableController()
        }
    }

    ;set current_profile to the new profile
    try current_profile:= config_obj.getProfile(p_name)
    catch err{
        current_profile:= config_obj.Profiles[1]
        configMsg(err)
        return
    }
    util_log("[Main] Switching to profile '" current_profile.ProfileName "'")

    ; create a new resource object
    resources_obj:= new ResourcesManager()
    if(current_profile.SoundFeedbackUseCustomSounds)
        resources_obj.loadCustomSounds()

    ;create a new OSD object for the profile
    osd_wnd:= new OSD(current_profile.OSDPos, current_profile.ExcludeFullscreen)
    osd_wnd.setTheme(util_getSystemTheme().Apps)

    ;initilize mic_controllers
    mic_controllers:= Array()
    for _i, mic in current_profile.Microphone {
        Try {
            ;create a new MicrophoneController object for each mic
            if(InStr(mic.Name, "VMR_") = 1){
                if(config_obj.VoicemeeterIntegration)
                    controller:= new VoicemeeterController(mic, config_obj.VoicemeeterPath, current_profile.PTTDelay, config_obj.ForceMicrophoneState, current_profile.MicrophoneVolumeLock, Func("showFeedback"), Func("onUpdateState"))
                else
                    throw Exception("Voicemeeter integration is disabled")
            }else{
                controller:= new MicrophoneController(mic, current_profile.PTTDelay, config_obj.ForceMicrophoneState, current_profile.MicrophoneVolumeLock, Func("showFeedback"), Func("onUpdateState"))
            }
            ; mute mics on startup
            if(config_obj.MuteOnStartup)
                controller.setMuteState(1, 0)
            controller.enableController()
            controller.onUpdateState()
            if(controller.isMicrophoneArray){
                while(ctrlr:= mic_controllers.Pop()){ ; disable and remove previously added controllers
                    ctrlr.disableController()
                }
                mic_controllers.Push(controller)
                break
            }
            mic_controllers.Push(controller)
        }Catch, err {
            util_log(err)
            configMsg(err)
            return
        }
    }

    ;check the profile in the tray menu
    Menu, profiles, Check, % current_profile.ProfileName

    ;handle tray toggle option
    tray_add("Toggle microphone", ObjBindMethod(mic_controllers[1],"setMuteState",-2))
    tray_setToggleMic(1)
    if(mic_controllers[1].isPushToTalk && !mic_controllers[1].isHybridPTT)
        tray_setToggleMic(0)

    ; setup sound player
    if(current_profile.SoundFeedback){
        sound_player:= new SoundPlayer()
        if(!sound_player.setDevice(current_profile.SoundFeedbackDevice))
            sound_player.setDevice("Default")
        ; test playback to remove initial pop
        sound_player.play(resources_obj.getSoundFile(0),0)
    }

    ;handle multiple microphones
    if(mic_controllers.Length()>1){
        MicrophoneController.isUsingMultipleMicrophones:= 1
        tray_setToggleMic(0)
        ; handle multiple microphones with the same hotkey
        for _hotkeyStr, registrations in HotkeyManager.registeredHotkeys {
            if(registrations.Length()>1){
                for _i, registration in registrations {
                    registration.callbackObj.force_current_state:= 1
                }
            }
        }
    }else{
        if(current_profile.OnscreenOverlay.Enabled){
            overlay_wnd:= new Overlay({size: current_profile.OnscreenOverlay.Size
                , theme: current_profile.OnscreenOverlay.Theme
                , pos: current_profile.OnscreenOverlay.Position
                , showOn: current_profile.OnscreenOverlay.ShowOnState
                , useCustomIcons: current_profile.OnscreenOverlay.UseCustomIcons}, mic_controllers[1].state)

        }
    }

    mic_actions:=""
    auraSyncEnabled:=""
    ; Register microphone actions
    if(current_profile.MicrophoneActions.Length() > 0){
        mic_actions:= Array()
        for i, action in current_profile.MicrophoneActions {
            if (action.Type == "AuraSync") {
                if (auraSyncEnabled) {
                    util_log("[Main] Multiple Aura Sync actions detected, Ignoring Aura Sync action [" i "]")
                    continue
                } else if (!AuraSync.isInstalled() ) {
                    util_log("[Main] Aura Sync is either not installed or has been disabled, Ignoring Aura Sync action")
                    continue
                }
                auraSyncEnabled:= 1
            }
            mic_actions.Push(MicrophoneAction.Create(action))
            util_log("[Main] Registered " action.Type " action")
        }
    }

    if (!auraSyncEnabled)
        tray_remove("Aura Sync")

    if (current_profile.afkTimeout)
        SetTimer, checkIsIdle, 1000

    ;show switching-profile OSD
    if(config_obj.SwitchProfileOSD)
        osd_wnd.showAndHide(Format("Profile: {}", current_profile.ProfileName))

    onUpdateState(mic_controllers[1])
    Critical, Off
}

showFeedback(microphone){
    if (current_profile.SoundFeedback){
        file:= resources_obj.getSoundFile(microphone.state, microphone.isPushToTalk)
        sound_player.play(file)
    }

    if (current_profile.OnscreenFeedback)
        osd_wnd.showAndHide(microphone.getStateString(), !microphone.state)
}

editConfig(){
    ; Check if shift is pressed or noUI arg is enabled
    ; and open the config file with the default program
    if(GetKeyState("Shift", "P") || arg_noUI){
        if(progPath:=util_GetFileAssoc("json"))
            Run, %progPath% "%A_ScriptDir%\config.json",
        else
            Run, notepad.exe "%A_ScriptDir%\config.json",
        return
    }

    try osd_wnd.destroy()
    Thread, NoTimers, 1
    if(current_profile){
        for _i, mic in mic_controllers
            mic.disableController()
        overlay_wnd.destroy()
        SetTimer, checkIsIdle, Off
        SetTimer, checkLinkedApps, Off
    }
    setTimer, checkConfigDiff, Off
    last_modif_time:= ""
    tray_setToggleMic(0)
    tray_defaults()
    UI_show(current_profile.ProfileName)
}

checkIsIdle(){
    static wasIdle:= 0
    if (A_TimeIdlePhysical < current_profile.afkTimeout * 60000){
        wasIdle:=0
        return
    }

    if(!wasIdle)
        util_log("[Main] User is idle")
    wasIdle:= 1
    for _i, mic in mic_controllers
        if(!mic.isPushToTalk)
            mic.setMuteState(1)
}

;checks for changes to the config file
checkConfigDiff(){
    FileGetTime, modif_time, config.json
    if(last_modif_time && modif_time!=last_modif_time){
        util_log("[Main] Detected changes to config file")
        last_modif_time:= ""
        setTimer, checkConfigDiff, Off
        initilizeMicMute(current_profile.ProfileName, false)
    }
    last_modif_time:= modif_time
}

checkLinkedApps(){
    if(watched_profile){
        if(!isAppActive(watched_profile.LinkedApp)){
            util_log("[Main] Linked app closed: " . watched_profile.LinkedApp)
            watched_profile:=""
            switchProfile(config_obj.DefaultProfile)
        }
        return
    }

    for _i, p in watched_profiles {
        if(isAppActive(p.LinkedApp)){
            util_log("[Main] Detected linked app: " . p.LinkedApp)
            watched_profile:= p
            switchProfile(p.ProfileName)
            break
        }
    }
}

isAppActive(appFile){
    if (current_profile.ForegroundAppsOnly) {
        windowExists := WinExist("ahk_exe " . appFile)
        WinGet, minState, MinMax, ahk_exe %appFile%

        ; An app is active in the foreground if it has a window that's not hidden
        ; Minimized windows are considered hidden
        return windowExists && minState !== "" && minState !== -1
    } else {
        _hiddenValue := A_DetectHiddenWindows
        DetectHiddenWindows, On

        ; Try to get the PID
        WinGet, appPid, PID, ahk_exe %appFile%

        DetectHiddenWindows, %_hiddenValue%
        return appPid !== ""
    }
}

onUpdateState(microphone){
    if (mic_controllers.Length() == 1) {
        overlay_wnd.setState(microphone.state)
        tray_update(microphone)
    } else {
        tray_defaults()
    }

    for _i, action in mic_actions {
        action.run(microphone)
    }
}

updateMicrophonesState(){
    if(mic_controllers){
        for _i, mic in mic_controllers{
            onUpdateState(mic)
        }
    }
}

updateSysTheme(_wParam:="", lParam:=""){
    if(!lParam || StrGet(lParam) == "ImmersiveColorSet"){
        themes:= util_getSystemTheme()
        osd_wnd.setTheme(themes.Apps)
        UI_updateTheme()
        Sleep, 100
        onUpdateState(mic_controllers[1])
    }
}

exitMicMute(){
    util_log("[Main] Exiting MicMute")
    config_obj.exportConfig()
    for _i, mic in mic_controllers {
        mic.disableController()
        mic.setMuteState(0, 0)
    }
}

reloadMicMute(p_profile:=""){
    args:= Format("/reload=1 ""/profile={1:}"" /debug={2:} /noui={3:} ""/logFile={4:}"""
        , p_profile, arg_isDebug, arg_noUI, arg_logFile)
    util_log("[Main] Reloading MicMute with args (" args ")")
    if(A_IsCompiled)
        Run "%A_ScriptFullPath%" /r %args%
    else
        Run "%A_AhkPath%" /r "%A_ScriptFullPath%" %args%
}

parseArgs(){
    arg_regex:= "i)[\/\-]?([\w]+)(=(.+))?"
    for _i, arg in A_Args {
        match:= RegExMatch(arg, arg_regex, val)
        if(!match)
            continue
        switch val1 {
            case "debug":
                arg_isDebug:= (val3=""? 1 : val3)
                args_str.= val " "
            case "noui":
                arg_noUI:= (val3=""? 1 : val3)
                args_str.= val " "
            case "profile":
                arg_profile:= val3
                args_str.= val " "
            case "reload": arg_reload:= (val3=""? 1 : val3)
            case "logFile":
                arg_logFile:= val3
                args_str.= val " "
            case "updater": arg_isUpdater:= (val3=""? 1 : val3)
            case "installPath": arg_installPath:= val3
        }
    }
}

registerWindowHook(){
    DllCall( "RegisterShellHookWindow", UInt,A_ScriptHwnd )
    MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
    OnMessage( MsgNum, "onWindowChange" )
}

onWindowChange(wParam, _lParam){
    if(wParam=1)
        showElevatedWarning()
}

showElevatedWarning(){
    static lastP:=""
    WinGet, pid, pid, A
    WinGet, pName, ProcessName, A
    if(A_IsAdmin || !pName || pName == lastP)
        return
    if(util_isProcessElevated(pid)){
        util_log("[Main] Detected elevated app: " pName " (" pid ")")
        TrayTip, MicMute, Detected an application running with administrator privileges. You need to run MicMute as administrator for the hotkeys to work with it.
        lastP:= pName
        onUpdateState(mic_controllers[1])
    }
}

configMsg(err){
    Thread, NoTimers, 1
    MsgBox, 65, MicMute, % (IsObject(err)? err.Message : err) . "`nClick OK to edit configuration"
    IfMsgBox, OK
        editConfig()
    IfMsgBox, Cancel
        ExitApp, -2
}

runUpdater(){
    if(!A_IsCompiled)
        return
    util_log("[Main] Restarting MicMute in updater mode")
    FileCopy, %A_ScriptFullPath%, %A_Temp%\MicMuteUpdater.exe, 1
    Run, "%A_Temp%\MicMuteUpdater.exe" "/updater=1" "/installPath=%A_ScriptDir%"
    ExitApp, 1
}

initAuraService(){
    IPC_SetHandler(Func("OnAuraServiceMessage"))
    AuraSyncAction.initAuraService()
}

OnAuraServiceMessage(parentHwnd, msg){
    if(msg == "auraReady"){
        AuraSyncAction.AuraReady:= 1
        for _i, action in mic_actions {
            ; Run AuraSyncAction with initialState
            if(action.TypeName == AuraSyncAction.TypeName)
                return action.run("")
        }
        ; There's no auraSyncAction in the current profile
        return AuraSyncAction.sendAction("pauseService")
    }

    util_log("[AuraService] " msg)
}