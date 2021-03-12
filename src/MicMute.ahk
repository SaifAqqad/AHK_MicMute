;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion 0.8.3
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-SetDescription MicMute
;@Ahk2Exe-AddResource %U_Res%\defaultBlack.ico, 3080
;@Ahk2Exe-AddResource %U_Res%\muteBlack.ico, 4080
;@Ahk2Exe-AddResource %U_Res%\defaultWhite.ico, 3090
;@Ahk2Exe-AddResource %U_Res%\muteWhite.ico, 4090
;@Ahk2Exe-AddResource %U_Res%\mute.wav
;@Ahk2Exe-AddResource %U_Res%\unmute.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_off.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_on.wav
;@Ahk2Exe-AddResource *10 %U_Res%\GUI.html
;@Ahk2Exe-AddResource %U_Res%\bulma.css
;@Ahk2Exe-AddResource %U_Res%\base.css
;@Ahk2Exe-AddResource %U_Res%\dark.css
;@Ahk2Exe-AddResource %U_Res%\MicMute.png


#InstallMouseHook
#InstallKeybdHook
#SingleInstance force

#Include, <VA>
#Include, <JSON>
#Include, <Neutron>
#Include, <StackSet>

#Include, utils.ahk
#Include, OSD.ahk
#Include, GUI.ahk
#Include, Config.ahk
#Include, Tray.ahk

;auto_exec begin
SetWorkingDir %A_ScriptDir%
Global conf
, watched_profiles
, current_profile
, watched_profile
, global_state
, ptt_key
, mute_sound
, unmute_sound
, ptt_on_sound
, ptt_off_sound
, sys_theme
, osd_obj
, hotkeys_set
SetTimer, runUpdater, -1
SetTimer, GUI_create, -1
init()
conf.exportConfig()
if(conf.MuteOnStartup)
    setMuteState(1)
OnExit(Func("setMuteState").bind(0))
;auto_exec end

init(){
    conf:= new Config
    , osd_obj:=""
    , watched_profiles:= Array()
    , current_profile:=""
    , watched_profile:=""
    , global_state:=""
    , ptt_key:=""
    , mute_sound:=""
    , unmute_sound:=""
    , ptt_on_sound:=""
    , ptt_off_sound:=""
    , sys_theme:=""
    , hotkeys_set:= ""
    for i, prof in conf.Profiles 
        if(prof.LinkedApp)
            watched_profiles.Push(prof)
    Try SetTimer, checkProfiles, % watched_profiles.Length()? 3000 : "Off"
    initSounds()
    enableCheckChanges()
    UpdateSysTheme()
    tray_init()
    switchProfile()
}


switchProfile(p_name:=""){
    Try{
        disableHotkeys()
        SetTimer, updateGlobalState, Off
        SetTimer, checkActivity, Off
        Menu, profiles, Uncheck, % current_profile.ProfileName
    }
    Menu, profiles, Check, % current_profile.ProfileName
    current_profile:= conf.getProfile(p_name)
    osd_obj:= new OSD(current_profile.OSDPos, current_profile.ExcludeFullscreen)
    hotkeys_set:= new StackSet
    if (current_profile.UpdateWithSystem)
        SetTimer, updateGlobalState, 1500
    if (current_profile.afkTimeout)
        SetTimer, checkActivity, 1000
    Try initHotkeys()
    catch err{
        MsgBox, 65, MicMute, % err
        IfMsgBox, OK
            editConfig()
        IfMsgBox, Cancel
            ExitApp, -2
        return
    }
    updateGlobalState()
    if(conf.SwitchProfileOSD)
        osd_obj.showAndHide(Format("Profile: {}", current_profile.ProfileName))
}




initSounds(){
    util_ResRead(mute_sound, Format("{:U}", "mute.wav"))
    util_ResRead(unmute_sound, Format("{:U}","unmute.wav"))
    util_ResRead(ptt_on_sound, Format("{:U}", "ptt_off.wav"))
    util_ResRead(ptt_off_sound, Format("{:U}","ptt_on.wav"))
    if(conf.UseCustomSounds){
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

updateGlobalState(){
    global_state:= VA_GetMasterMute(current_profile.Microphone)
    UpdateSysTheme()
    if(global_state){
        tooltipTxt:= "Microphone Muted"
        tray_update(sys_theme? U_muteWhite : U_muteBlack, tooltipTxt)
    }else{
        tooltipTxt:= "Microphone Online"
        tray_update(sys_theme? U_defaultWhite : U_defaultBlack, tooltipTxt)
    }
}

checkActivity(){
    if (A_TimeIdlePhysical > current_profile.afkTimeout * 60000){
        ;TODO: for each mic -> setMuteState(1)
    }
}

;TODO REWRITE FEATURE
checkProfiles(){
    static last_profile:=
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

;TODO REWRITE FEATURE
showFeedback(mic_obj){
    if (current_profile.OnscreenFeedback){
        osd_obj.showAndHide("Microphone " . (global_state? "Muted" : "Online"), !global_state)
    }
    if (current_profile.SoundFeedback){
        if(current_profile.PushToTalk)
            util_PlaySound(global_state? ptt_off_sound : ptt_on_sound)
        else
            util_PlaySound(global_state? mute_sound : unmute_sound)
    }
}

editConfig(){
    Menu, Tray, Icon, %A_ScriptFullPath%, 1
    Try osd_obj.destroy()
    if(GetKeyState("Shift", "P")){
        if(progPath:=util_GetFileAssoc("json"))
            Run, %ProgPath% "%A_ScriptDir%\config.json",
        else
            Run, notepad.exe "%A_ScriptDir%\config.json",
    }else{
        if(current_profile){
            disableHotkeys()
            SetTimer, updateGlobalState, Off
            SetTimer, checkActivity, Off
            SetTimer, checkProfiles, Off
        }
        disableCheckChanges()
        GUI_show()
        if(!checkChanges())
            init()
    }
}

checkChanges(){
    static last_modif_time:= ""
    FileGetTime, modif_time, config.json
    if(last_modif_time && modif_time!=last_modif_time){
        init()
        ret:= 1
    }
    last_modif_time:= modif_time
    return ret
}

enableCheckChanges(){
    static ccObj:= Func("checkChanges")
    setTimer, % ccObj, 3000
}

disableCheckChanges(){
    static ccObj:= Func("checkChanges")
    setTimer, % ccObj, Off
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
