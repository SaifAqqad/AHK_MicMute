;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-Let UI = %A_ScriptDir%\UI\config
;@Ahk2Exe-Let Version = 0.9.2
;@Ahk2Exe-IgnoreBegin
    U_Version:= "0.9.2"
;@Ahk2Exe-IgnoreEnd
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion %U_Version%
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-SetDescription MicMute
#NoEnv
SetBatchLines -1
SetWorkingDir %A_ScriptDir%

#InstallMouseHook
#InstallKeybdHook
#SingleInstance force

#Include, <WinUtils>
#Include, <VA>
#Include, <JSON>
#Include, <Neutron>
#Include, <StackSet>

#Include, %A_ScriptDir%
#Include, ResourcesManager.ahk
#Include, MicrophoneController.ahk
#Include, %A_ScriptDir%\config
#Include, ProfileTemplate.ahk
#Include, Config.ahk
#Include, %A_ScriptDir%\UI
#Include, OSD.ahk
#Include, Tray.ahk
#Include, %A_ScriptDir%\UI\config
#Include, HotkeyPanel.ahk
#Include, UI.ahk

Global config_obj, osd_obj, mic_controllers, current_profile
, mute_sound, unmute_sound, ptt_on_sound, ptt_off_sound
, sys_theme, ui_theme, isFirstLaunch:=0
, watched_profiles, watched_profile
, func_update_state, last_modif_time
, arg_isDebug:=0, arg_profile:="", arg_noUI:=0
, resources_obj:= new ResourcesManager()
, A_Version:= A_IsCompiled? util_getFileSemVer(A_ScriptFullPath) : U_Version 
, WM_SETTINGCHANGE:= 0x001A
; parse cli args
parseArgs()
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


initilizeMicMute(default_profile:=""){
    ;make sure hotkeys are disabled before reinitilization
    if(mic_controllers)
        for i,mic in mic_controllers
            mic.disableHotkeys()
    ;initilize globals
    config_obj:= new Config()
    , osd_obj:=""
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
    ;initilize sound variables
    initilizeSounds()
    ;update theme variables
    updateSysTheme()
    ;initilize tray
    tray_init()
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
        SetTimer, % func_update_state, Off
        SetTimer, checkIsIdle, Off
    }
    ;unmute and disable hotkeys for all existing microphones
    if(mic_controllers){
        for i, mic in mic_controllers{
            VA_SetMasterMute(0,mic.microphone)
            mic.disableHotkeys()
        }
    }
    ;reset tray icon and tooltip
    tray_defaults()
    ;uncheck the profile in the tray menu
    Menu, profiles, Uncheck, % current_profile.ProfileName
    ;reset the hotkeys set in MicrophoneController class
    MicrophoneController.resetHotkeysSet()
    ;set current_profile to the new profile
    current_profile:= config_obj.getProfile(p_name)
    ;@Ahk2Exe-IgnoreBegin
    OutputDebug, % Format("Switching to profile '{}'`n",current_profile.ProfileName)
    ;@Ahk2Exe-IgnoreEnd
    ;create a new OSD object for the profile
    osd_obj:= new OSD(current_profile.OSDPos, current_profile.ExcludeFullscreen)
    osd_obj.setTheme(ui_theme)
    ;initilize mic_controllers
    mic_controllers:= Array()
    for i, mic in current_profile.Microphone {
        ;create a new MicrophoneController object for each mic
        mc:= new MicrophoneController(mic, current_profile.PTTDelay, Func("showFeedback"))
        Try {
            device:= VA_GetDevice(mc.microphone)
            if(!device) ;if the mic does not exist -> throw an error
                Throw, Format("Invalid microphone name '{}' in profile '{}'", mic.Name,current_profile.ProfileName)
            mc.enableHotkeys()
        }Catch, err {
            Thread, NoTimers, 1
            MsgBox, 65, MicMute, % err . "`nClick OK to edit configuration"
            IfMsgBox, OK
                editConfig()
            IfMsgBox, Cancel
                ExitApp, -2
            return
        }
        ;@Ahk2Exe-IgnoreBegin
        OutputDebug,% Format("Enabled Microphone controller: {} | {} | {}`n", mc.microphone,mc.muteHotkey,mc.unmuteHotkey)
        ;@Ahk2Exe-IgnoreEnd
        mic_controllers.Push(mc)
    }
    ;check the profile in the tray menu
    Menu, profiles, Check, % current_profile.ProfileName
    ;handle tray toggle option
    tray_add("Toggle microphone", ObjBindMethod(mic_controllers[1],"setMuteState",-1))
    tray_toggleMic(1)
    if(mic_controllers[1].isPushToTalk)
        tray_toggleMic(0)
    ;handle multiple microphones
    if(mic_controllers.Length()>1){
        func_update_state:= Func("updateStateMutliple")
        tray_toggleMic(0)
    }else{
        func_update_state:= Func("updateState")
    }
    ;turn on profile-specific timers
    if (current_profile.UpdateWithSystem)
        SetTimer, % func_update_state, 1500
    if (current_profile.afkTimeout)
        SetTimer, checkIsIdle, 1000  
    ; mute mics on startup
    if(config_obj.MuteOnStartup){
        for i, mic in mic_controllers 
            VA_SetMasterMute(1,mic.microphone)
    }
    ;get initial state  
    func_update_state.Call()
    ;show switching-profile OSD
    if(config_obj.SwitchProfileOSD)
        osd_obj.showAndHide(Format("Profile: {}", current_profile.ProfileName))
    Critical, Off
}

showFeedback(mic_obj){
    ;update global state to make sure the tray icon is updated
    func_update_state.Call()
    ;if osd is enabled -> show and hide after 1 sec
    if (current_profile.OnscreenFeedback){ ;use generic/mic.name state string
        str:= (mic_obj[(mic_controllers.Length()>1? "": "generic_") "state_string"][mic_obj.state])
        osd_obj.showAndHide(str, !mic_obj.state)
    }
    ; if sound fb is enabled -> play the relevant sound file
    if (current_profile.SoundFeedback){
        if(mic_obj.isPushToTalk)
            util_PlaySound(mic_obj.state? ptt_off_sound : ptt_on_sound)
        else
            util_PlaySound(mic_obj.state? mute_sound : unmute_sound)
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
                mic.disableHotkeys()
            Try SetTimer, % func_update_state, Off
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

initilizeSounds(){
    ;load default sounds
    util_ResRead(mute_sound, resources_obj.getSoundFile(1), A_IsCompiled)
    util_ResRead(unmute_sound, resources_obj.getSoundFile(0), A_IsCompiled)
    util_ResRead(ptt_on_sound, resources_obj.getSoundFile(0,1), A_IsCompiled)
    util_ResRead(ptt_off_sound, resources_obj.getSoundFile(1,1), A_IsCompiled)
    if(config_obj.UseCustomSounds){
        ;try loading custom sound files
        util_ResRead(mute_sound,"mute.mp3" ,0)
        || util_ResRead(mute_sound, "mute.wav",0)
        util_ResRead(unmute_sound,"unmute.mp3" ,0)
        || util_ResRead(unmute_sound, "unmute.wav",0)
        util_ResRead(ptt_on_sound,"ptt_on.mp3" ,0)
        || util_ResRead(ptt_on_sound, "ptt_on.wav",0)
        util_ResRead(ptt_off_sound,"ptt_off.mp3" ,0)
        || util_ResRead(ptt_off_sound, "ptt_off.wav",0)
    }
}

checkIsIdle(){
    if (A_TimeIdlePhysical > current_profile.afkTimeout * 60000){
        for i, mic in mic_controllers
            if(!mic.isPushToTalk)
                mic.setMuteState(1)
    }
}

;checks for changes to the config file
checkConfigDiff(){
    FileGetTime, modif_time, config.json
    if(last_modif_time && modif_time!=last_modif_time){
        last_modif_time:= ""
        setTimer, checkConfigDiff, Off
        initilizeMicMute(current_profile.ProfileName)
    }
    last_modif_time:= modif_time
}

checkLinkedApps(){
    if(watched_profile){
        if(!WinExist("ahk_exe " . watched_profile.LinkedApp)){
            switchProfile(config_obj.DefaultProfile)
            watched_profile:=""
        }
        return
    }
    for i, prof in watched_profiles {
        if(WinExist("ahk_exe " . prof.LinkedApp)){
            watched_profile:= prof
            switchProfile(prof.ProfileName)
        }
    }
}

updateState(){
    mic_controllers[1].updateState()
    tray_update(mic_controllers[1])
}

updateStateMutliple(){
    ;for each MicrophoneController -> update its state
    for i, mc in mic_controllers {
        mc.updateState()
    }
    tray_defaults()
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
    }
}

exitMicMute(){
    config_obj.exportConfig()
    for i, mic in mic_controllers 
        VA_SetMasterMute(0,mic.microphone)
}

reloadMicMute(p_profile:=""){
    if(A_IsCompiled)
        Run "%A_ScriptFullPath%" /restart "/profile=%p_profile%"
    else
        Run "%A_AhkPath%" /restart "%A_ScriptFullPath%" "/profile=%p_profile%"
}

parseArgs(){
    arg_regex:= "i)\/([\w]+)(=([\w\s]+))?"
    for i,arg in A_Args {
        match:= RegExMatch(arg, arg_regex, val)
        if(!match)
            continue
        switch val1 {
            case "debug": arg_isDebug:= (val3=""? 1 : val3)
            case "noui": arg_noUI:= (val3=""? 1 : val3)
            case "profile": arg_profile:= val3
        }
    }
}