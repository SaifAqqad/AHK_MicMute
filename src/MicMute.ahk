;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-Let UI = %A_ScriptDir%\UI\config
;@Ahk2Exe-Let Version = 1.2.1
;@Ahk2Exe-IgnoreBegin
    U_Version:= "1.2.1"
;@Ahk2Exe-IgnoreEnd
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-SetDescription MicMute
;@Ahk2Exe-Bin Unicode 64*
/*@Ahk2Exe-Keep
FileInstall, Lib\bass.dll, %A_ScriptDir%\bass.dll
*/

#NoEnv
SetBatchLines -1
SetWorkingDir %A_ScriptDir%

#InstallMouseHook
#InstallKeybdHook
#SingleInstance force
#MaxThreadsPerHotkey 1

#Include, <WinUtils>
#Include, <VA\VA>
#Include, <cJson\Dist\JSON>
#Include, <Neutron\Neutron>
#Include, <StackSet>
#Include, <SoundPlayer>

#Include, %A_ScriptDir%
#Include, ResourcesManager.ahk
#Include, MicrophoneController.ahk
#Include, VersionChecker.ahk
#Include, %A_ScriptDir%\config
#Include, ProfileTemplate.ahk
#Include, Config.ahk
#Include, %A_ScriptDir%\UI
#Include, OSD.ahk
#Include, Overlay.ahk
#Include, Tray.ahk
#Include, %A_ScriptDir%\UI\config
#Include, HotkeyPanel.ahk
#Include, UI.ahk

Global config_obj, osd_obj, overlay_obj, mic_controllers, current_profile
, mute_sound, unmute_sound, ptt_on_sound, ptt_off_sound
, sys_theme, ui_theme, isFirstLaunch:=0
, watched_profiles, watched_profile, last_modif_time
, arg_isDebug:=0, arg_profile:="", arg_noUI:=0, arg_reload:= 0, arg_logFile:="*"
, resources_obj:= new ResourcesManager()
, A_Version:= A_IsCompiled? util_getFileSemVer(A_ScriptFullPath) : U_Version 
, WM_SETTINGCHANGE:= 0x001A, sp_obj
, A_log:="", A_startupTime:= A_TickCount
; parse cli args
parseArgs()
util_log("MicMute v" . A_Version)
util_log(Format("[Main] Running as user {}, A_IsAdmin = {}", A_UserName, A_IsAdmin))
OnError(Func("util_log"))
; create config gui window
if(!arg_noUI)
    UI_create(Func("reloadMicMute"))
; initilize micmute
initilizeMicMute(arg_profile)
; export the processed config object
config_obj.exportConfig()
OnExit(Func("exitMicMute"))
; listen for sys theme changes
OnMessage(WM_SETTINGCHANGE, "updateSysTheme")
; listen for window changes
registerWindowHook()
; run the update checker once, 5 seconds after launching
if(A_IsCompiled && !arg_reload && config_obj.AllowUpdateChecker=1){
    cfunc:= ObjBindMethod(VersionChecker, "CheckForUpdates")
    SetTimer, % cfunc, -5000
}
A_startupTime:= A_TickCount - A_startupTime
util_log("[Main] MicMute startup took " A_startupTime "ms")


initilizeMicMute(default_profile:=""){
    util_log("[Main] Initilizing MicMute")
    ;initilize globals
    config_obj:= new Config()
    , osd_obj:=""
    , overlay_obj:=""
    , mic_controllers:=""
    , watched_profiles:= Array()
    , current_profile:=""
    , watched_profile:=""
    , mute_sound:=""
    , unmute_sound:=""
    , ptt_on_sound:=""
    , ptt_off_sound:=""
    , sys_theme:=""
    , last_modif_time:= ""
    , sp_obj:=""
    tray_defaults()
    ;add profiles with linked apps to watched_profiles
    for i,profile in config_obj.Profiles {
        if(profile.LinkedApp)
            watched_profiles.Push(profile)
    }
    ;enable linked apps timer
    SetTimer, checkLinkedApps, % watched_profiles.Length()? 3000 : "Off"
    ;enable checkConfigDiff timer 
    setTimer, checkConfigDiff, 3000
    ;update theme variables
    updateSysTheme()
    ;initilize tray
    tray_init()
    if(config_obj.AllowUpdateChecker==-1){
        MsgBox, 35, MicMute, Allow MicMute to connect to the internet and check for updates on startup?
        IfMsgBox, Yes
            config_obj.AllowUpdateChecker:= 1
        IfMsgBox, No
            config_obj.AllowUpdateChecker:= 0
        IfMsgBox, Cancel
            config_obj.AllowUpdateChecker:= -1
    }
    ;on first launch -> immediately call editConfig()
    if(isFirstLaunch){
        current_profile:= config_obj.Profiles[1]
        editConfig()
        return
    }
    ;switch to the default profile
    switchProfile(default_profile)
}

switchProfile(p_name:=""){
    Critical, On
    ;turn off profile-specific timers
    Try{
        SetTimer, checkIsIdle, Off
    }
    ;destroy existing guis 
    overlay_obj.destroy()
    osd_obj.destroy()
    sp_obj.__free()
    ;reset tray icon and tooltip
    tray_defaults()
    ;uncheck the profile in the tray menu
    Menu, profiles, Uncheck, % current_profile.ProfileName
    ;unmute and disable hotkeys for all existing microphones
    if(mic_controllers){
        for i, mic in mic_controllers{
            VA_SetMasterMute(0,mic.microphone)
            mic.disableController()
        }
    }
    MicrophoneController.resetHotkeySet()
    ;set current_profile to the new profile
    Try current_profile:= config_obj.getProfile(p_name)
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
    osd_obj:= new OSD(current_profile.OSDPos, current_profile.ExcludeFullscreen)
    osd_obj.setTheme(ui_theme)
    ;initilize mic_controllers
    mic_controllers:= Array()
    for i, mic in current_profile.Microphone {
        Try {
            ;create a new MicrophoneController object for each mic
            mc:= new MicrophoneController(mic, current_profile.PTTDelay, config_obj.ForceMicrophoneState, Func("showFeedback"), Func("onUpdateState"))
            ; mute mics on startup
            if(config_obj.MuteOnStartup)
                VA_SetMasterMute(1,mic.Name)
            mc.enableController()
            mc.updateState()
            mic_controllers.Push(mc)
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
    tray_toggleMic(1)
    if(mic_controllers[1].isPushToTalk)
        tray_toggleMic(0)
    ; setup sound player
    if(current_profile.SoundFeedback){
        sp_obj:= new SoundPlayer()
        if(!sp_obj.setDevice(current_profile.SoundFeedbackDevice))
            sp_obj.setDevice("Default")
        sp_obj.play(resources_obj.getSoundFile(0),0) ;test playback to remove initial pop
    }
    ;handle multiple microphones
    if(mic_controllers.Length()>1){
        tray_toggleMic(0)
    }else{
        if(current_profile.OnscreenOverlay){
            overlay_obj:= new Overlay(current_profile)
            overlay_obj.setState(mic_controllers[1].state)
        }
    }
    if (current_profile.afkTimeout)
        SetTimer, checkIsIdle, 1000  
    ;show switching-profile OSD
    if(config_obj.SwitchProfileOSD)
        osd_obj.showAndHide(Format("Profile: {}", current_profile.ProfileName))
    Critical, Off
}

showFeedback(mic_obj){
    ; if sound fb is enabled -> play the sound file
    if (current_profile.SoundFeedback){
        file:= resources_obj.getSoundFile(mic_obj.state,mic_obj.isPushToTalk)
        sp_obj.play(file)
    }    
    ; if osd is enabled -> show and hide after 1 sec
    if (current_profile.OnscreenFeedback){ ;use generic/mic.name state string
        str:= (mic_obj[(mic_controllers.Length()>1? "": "generic_") "state_string"][mic_obj.state])
        osd_obj.showAndHide(str, !mic_obj.state)
    }
}

editConfig(){
    Try osd_obj.destroy()
    if(GetKeyState("Shift", "P") || arg_noUI){
        if(progPath:=util_GetFileAssoc("json"))
            Run, %ProgPath% "%A_ScriptDir%\config.json",
        else
            Run, notepad.exe "%A_ScriptDir%\config.json",
    }else{
        Thread, NoTimers, 1
        if(current_profile){
            for i, mic in mic_controllers 
                mic.disableController()
            overlay_obj.destroy()
            SetTimer, checkIsIdle, Off
            SetTimer, checkLinkedApps, Off
        }
        setTimer, checkConfigDiff, Off
        last_modif_time:= ""
        tray_toggleMic(0)
        tray_defaults()
        UI_show(current_profile.ProfileName)
    }
}

checkIsIdle(){
    if (A_TimeIdlePhysical > current_profile.afkTimeout * 60000){
        util_log("[Main] User is idle")
        for i, mic in mic_controllers
            if(!mic.isPushToTalk)
                mic.setMuteState(1)
    }
}

;checks for changes to the config file
checkConfigDiff(){
    FileGetTime, modif_time, config.json
    if(last_modif_time && modif_time!=last_modif_time){
        util_log("[Main] Detected changes to config file")
        last_modif_time:= ""
        setTimer, checkConfigDiff, Off
        initilizeMicMute(current_profile.ProfileName)
    }
    last_modif_time:= modif_time
}

checkLinkedApps(){
    if(watched_profile){
        if(!WinExist("ahk_exe " . watched_profile.LinkedApp)){
            util_log("[Main] Linked app closed: " . watched_profile.LinkedApp)
            switchProfile(config_obj.DefaultProfile)
            watched_profile:=""
        }
        return
    }
    for i, prof in watched_profiles {
        if(WinExist("ahk_exe " . prof.LinkedApp)){
            util_log("[Main] Detected linked app: " . prof.LinkedApp)
            watched_profile:= prof
            switchProfile(prof.ProfileName)
        }
    }
}

onUpdateState(mic){
    if(mic_controllers.Length()>1)
        return tray_defaults()
    tray_update(mic)
    overlay_obj.setState(mic.state)
}

updateSysTheme(wParam:="", lParam:=""){
    if(!lParam || StrGet(lParam) == "ImmersiveColorSet"){
        ;read system theme
        RegRead, reg
        , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
        sys_theme:= !reg
        ;read apps theme
        RegRead, reg
        , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
        ui_theme:= config_obj.PreferTheme = -1? !reg : config_obj.PreferTheme
        osd_obj.setTheme(ui_theme)
        UI_updateTheme()
        Sleep, 100
        onUpdateState(mic_controllers[1])
    }
}

exitMicMute(){
    util_log("[Main] Exiting MicMute")
    config_obj.exportConfig()
    for i, mic in mic_controllers {
        VA_SetMasterMute(0,mic.microphone)
        mic.disableController()
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
    arg_regex:= "i)\/([\w]+)(=(.+))?"
    for i,arg in A_Args {
        match:= RegExMatch(arg, arg_regex, val)
        if(!match)
            continue
        switch val1 {
            case "debug": arg_isDebug:= (val3=""? 1 : val3)
            case "noui": arg_noUI:= (val3=""? 1 : val3)
            case "profile": arg_profile:= val3
            case "reload": arg_reload:= (val3=""? 1 : val3)
            case "logFile": arg_logFile:= val3
        }
    }
}

registerWindowHook(){
    DllCall( "RegisterShellHookWindow", UInt,A_ScriptHwnd )
    MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
    OnMessage( MsgNum, "onWindowChange" )
}

onWindowChange(wParam, lParam){
    if(wParam=1)
        showElevatedWarning()
}

showElevatedWarning(){
    static lastP:=""
    WinGet, pid, PID, A
    WinGet, pName, ProcessName, A
    if(A_IsAdmin || !pName || pName == lastP)
        return
    if(util_isProcessElevated(pid)){
        util_log("[Main] Detected elevated app: " pName " (" pid ")")
        tray_defaults()
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