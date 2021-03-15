;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\..\resources
;@Ahk2Exe-Let UI = %A_ScriptDir%\UI
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion 0.8.3
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-SetDescription MicMute
;@Ahk2Exe-AddResource %U_Res%\MicMute.png
;@Ahk2Exe-AddResource %U_Res%\MicMute.ico, 2000
;@Ahk2Exe-AddResource %U_Res%\black_unmute.ico, 3080
;@Ahk2Exe-AddResource %U_Res%\black_mute.ico, 4080
;@Ahk2Exe-AddResource %U_Res%\white_unmute.ico, 3090
;@Ahk2Exe-AddResource %U_Res%\white_mute.ico, 4090
;@Ahk2Exe-AddResource %U_Res%\mute.wav
;@Ahk2Exe-AddResource %U_Res%\unmute.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_off.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_on.wav
;@Ahk2Exe-AddResource *10 %U_UI%\GUI.html
;@Ahk2Exe-AddResource %U_UI%\bulma.css
;@Ahk2Exe-AddResource %U_UI%\base.css
;@Ahk2Exe-AddResource %U_UI%\dark.css



#InstallMouseHook
#InstallKeybdHook
#SingleInstance force

#Include, <VA>
#Include, <JSON>
#Include, <Neutron>
#Include, <StackSet>

#Include, .\utils.ahk
#Include, .\ResourcesManager.ahk
#Include, .\MicrophoneController.ahk
#Include, .\config\ProfileTemplate.ahk
#Include, .\config\Config.ahk
#Include, .\UI\OSD.ahk
#Include, .\UI\GUI.ahk
#Include, .\UI\Tray.ahk

Global config_obj, resources_obj, osd_obj, mic_controllers
, mute_sound, unmute_sound, ptt_on_sound, ptt_off_sound
, sys_theme, current_profile, watched_profiles, watched_profile
, func_update_state, state_string:={0:"Microphone Online",1:"Microphone Muted"}


initilizeMicMute(default_profile:=""){
    ;initilize globals
    config_obj:= new Config()
    , resources_obj:= new ResourcesManager()
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
    ;update sys_theme variable
    UpdateSysTheme()
    ;initilize tray
    tray_init()
    ;switch to the default profile
    switchProfile(default_profile)
}

switchProfile(p_name:=""){
    ;turn off profile-specific timers
    Try{
        SetTimer, % func_update_state, Off
        SetTimer, checkIsIdle, Off
    }
    ;disable hotkeys for all microphones
    if(mic_controllers){
        for i, mic in mic_controllers
            mic.disableHotkeys()
    }
    ;reset tray icon and tooltip
    tray_defaults()
    ;uncheck the profile in the tray menu
    Try Menu, profiles, Uncheck, % current_profile.ProfileName
    ;reset the hotkeys set in MicrophoneController class
    MicrophoneController.resetHotkeysSet()
    ;set current_profile to the new profile
    current_profile:= config_obj.getProfile(p_name)
    ;check the profile in the tray menu
    Menu, profiles, Check, % current_profile.ProfileName
    ;create a new OSD object for the profile
    osd_obj:= new OSD(current_profile.OSDPos, current_profile.ExcludeFullscreen)
    ;initilize mic_controllers
    mic_controllers:= Array()
    for i, mic in current_profile.Microphone {
        ;create a new MicrophoneController object for each mic
        mc:= new MicrophoneController(mic, current_profile.PTTDelay, Func("showFeedback"))
        Try mc.enableHotkeys()
        Catch, err {
            MsgBox, 65, MicMute, % err
            IfMsgBox, OK
                editConfig()
            IfMsgBox, Cancel
                ExitApp, -2
            return
        }
        mic_controllers.Push(mc)
    }
    ;handle multiple microphones
    if(mic_controllers.Length()>1){
        func_update_state:= Func("UpdateStateMutliple")
        tray_toggleMic(0)
    }else{
        func_update_state:= Func("UpdateState")
        tray_toggleMic(1)
    }
    ;turn on profile-specific timers
    if (current_profile.UpdateWithSystem)
        SetTimer, % func_update_state, 1500
    if (current_profile.afkTimeout)
        SetTimer, checkIsIdle, 1000  
    ;update initial state  
    func_update_state.Call()
    ;show switching-profile OSD
    if(config_obj.SwitchProfileOSD)
        osd_obj.showAndHide(Format("Profile: {}", current_profile.ProfileName))
}

showFeedback(mic_obj){
    if (current_profile.OnscreenFeedback){
        osd_obj.showAndHide(state_string[mic_obj.state], !mic_obj.state)
    }
    if (current_profile.SoundFeedback){
        if(current_profile.PushToTalk)
            util_PlaySound(mic_obj.state? ptt_off_sound : ptt_on_sound)
        else
            util_PlaySound(mic_obj.state? mute_sound : unmute_sound)
    }
}

editConfig(){
    Try osd_obj.destroy()
    if(GetKeyState("Shift", "P")){
        if(progPath:=util_GetFileAssoc("json"))
            Run, %ProgPath% "%A_ScriptDir%\config.json",
        else
            Run, notepad.exe "%A_ScriptDir%\config.json",
    }else{
        if(current_profile){
            disableHotkeys()
            SetTimer, % func_update_state, Off
            SetTimer, checkIsIdle, Off
            SetTimer, checkLinkedApps, Off
        }
        setTimer, checkConfigDiff, Off
        tray_defaults()
        GUI_show()
        if(!checkConfigDiff())
            init(current_profile.ProfileName)
    }
}

initilizeSounds(){
    ;load default sounds
    util_ResRead(mute_sound, Format("{:U}", "mute.wav"))
    util_ResRead(unmute_sound, Format("{:U}","unmute.wav"))
    util_ResRead(ptt_on_sound, Format("{:U}", "ptt_on.wav"))
    util_ResRead(ptt_off_sound, Format("{:U}","ptt_off.wav"))
    if(conf.UseCustomSounds){
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
           mic.setMuteState(1)
    }
}

;checks for changes to the config file
checkConfigDiff(){
    static last_modif_time:= ""
    FileGetTime, modif_time, config.json
    if(last_modif_time && modif_time!=last_modif_time){
        init(current_profile.ProfileName)
        ret:= 1
    }
    last_modif_time:= modif_time
    return ret
}

checkLinkedApps(){
    static last_profile:=""
    if(watched_profile){
        if(!WinExist("ahk_exe " . watched_profile.LinkedApp)){
            switchProfile(last_profile.ProfileName)
            last_profile:=""
            watched_profile:=""
        }
        return
    }
    for i, prof in watched_profiles {
        if(WinExist("ahk_exe " . prof.LinkedApp)){
            last_profile:= current_profile
            watched_profile:= prof
            switchProfile(prof.ProfileName)
        }
    }
}

updateState(){
    mic_controllers[1].UpdateState()
    UpdateSysTheme()
    tray_update(sys_theme, mic_controllers[1].state)
}

updateStateMutliple(){
    ;for each MicrophoneController -> update its state
    for i, mc in mic_controllers {
        mc.updateState()
    }
    UpdateSysTheme()
}

UpdateSysTheme(){
    RegRead, reg
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    sys_theme:= !reg
    osd_obj.setTheme(sys_theme)
}

runUpdater(p_silent:=1){
    if(FileExist(A_ScriptDir . "\updater.exe")){
        RunWait, %A_ScriptDir%\updater.exe -check-update, %A_ScriptDir%, UseErrorLevel
        if(ErrorLevel=-2 && !p_silent)
            MsgBox, 64, MicMute, You already have the latest verison installed
    }
}
