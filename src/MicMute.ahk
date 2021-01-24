﻿;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion 0.7.9
;@Ahk2Exe-SetName MicMute
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


#UseHook On
#SingleInstance force

#Include, <VA>
#Include, <OSD>
#Include, GUI.ahk
#Include, Config.ahk
#Include, Tray.ahk

;auto_exec begin
SetWorkingDir %A_ScriptDir%
Global conf, watched_profiles, current_profile, watched_profile
, global_state, ptt_key, mute_sound, unmute_sound, ptt_on_sound, ptt_off_sound, sys_theme
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

ptt(){
    setMuteState(0)
    KeyWait, %ptt_key%
    setMuteState(1)
}

setMuteState(state){
    Critical, On
    switch state {
        case global_state: return
        case -1: state:= !global_state
    }
    VA_SetMasterMute(state, current_profile.Microphone)
    updateGlobalState()
    Critical, Off
    showFeedback()
}

switchProfile(p_name:=""){
    Try{
        disableHotkeys()
        SetTimer, updateGlobalState, Off
        SetTimer, checkActivity, Off
        Menu, profiles, Uncheck, % current_profile.ProfileName
    }
    current_profile:= conf.getProfile(p_name)
    Menu, profiles, Check, % current_profile.ProfileName
    if (current_profile.UpdateWithSystem){
        SetTimer, updateGlobalState, 1500
    }
    if (current_profile.afkTimeout && !current_profile.PushToTalk){
        SetTimer, checkActivity, 1000
    }
    Try initHotkeys()
    catch {
        MsgBox, 65, MicMute, % Format("'{}' profile needs to be setup",current_profile.ProfileName)
        IfMsgBox, OK
            editConfig()
        IfMsgBox, Cancel
            ExitApp, -2
    }
    OSD_setPos(current_profile.OSDPos.x,current_profile.OSDPos.y)
    if(conf.SwitchProfileOSD)
        OSD_show(Format("Profile: {}", current_profile.ProfileName),OSD_MAIN_ACCENT,current_profile.ExcludeFullscreen)
    updateGlobalState()
}

disableHotkeys(){
    Try Hotkey, % current_profile.MuteHotkey , Off, Off
    Try Hotkey, % current_profile.UnmuteHotkey, Off, Off
}

initHotkeys(){
    Menu, Tray, Enable, Toggle microphone
    Menu, Tray, Default, Toggle microphone
    if (current_profile.MuteHotkey=current_profile.UnmuteHotkey){
        if(current_profile.PushToTalk){
            VA_SetMasterMute(1, current_profile.Microphone)
            ptt_key:= (StrSplit(current_profile.MuteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
            Hotkey, % current_profile.MuteHotkey , ptt, On
            Menu, Tray, Disable, Toggle microphone
            Menu, Tray, NoDefault
        }else{
            funcObj:= Func("setMuteState").bind(-1)
            Hotkey, % current_profile.MuteHotkey , % funcObj, On
        }
    }else{
        funcObj:= Func("setMuteState").bind(1)
        Hotkey, % current_profile.MuteHotkey, % funcObj, On
        funcObj:= Func("setMuteState").bind(0)
        Hotkey, % current_profile.UnmuteHotkey, % funcObj, On
    } 
}

initSounds(){
    resRead(mute_sound, Format("{:U}", "mute.wav"))
    resRead(unmute_sound, Format("{:U}","unmute.wav"))
    resRead(ptt_on_sound, Format("{:U}", "ptt_off.wav"))
    resRead(ptt_off_sound, Format("{:U}","ptt_on.wav"))
    if(conf.UseCustomSounds){
        resRead(mute_sound,"mute.mp3" ,0)
        || resRead(mute_sound, "mute.wav",0)
        resRead(unmute_sound,"unmute.mp3" ,0)
        || resRead(unmute_sound, "unmute.wav",0)
        resRead(ptt_on_sound,"ptt_on.mp3" ,0)
        || resRead(ptt_on_sound, "ptt_on.wav",0)
        resRead(ptt_off_sound,"ptt_off.mp3" ,0)
        || resRead(ptt_off_sound, "ptt_off.wav",0)
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
    if (A_TimeIdlePhysical > current_profile.afkTimeout * 60000)
        setMuteState(1)
}

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

showFeedback(){
    if (current_profile.OnscreenFeedback){
        if (global_state)
            OSD_show("Microphone Muted", OSD_MUTE_ACCENT, current_profile.ExcludeFullscreen)
        else
            OSD_show("Microphone Online", OSD_UNMUTE_ACCENT, current_profile.ExcludeFullscreen)
    }
    if (current_profile.SoundFeedback){
        if(current_profile.PushToTalk)
            playSound(global_state? ptt_off_sound : ptt_on_sound)
        else
            playSound(global_state? mute_sound : unmute_sound)
    }
}

editConfig(){
    Menu, Tray, Icon, %A_ScriptFullPath%, 1
    OSD_destroy()
    if(GetKeyState("Shift", "P")){
        if(progPath:=getFileAssoc("json"))
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

getFileAssoc(extension){
    VarSetCapacity(numChars, 4)
    DllCall("Shlwapi.dll\AssocQueryStringW"
    , "UInt", 0x0, "UInt", 0x2, "WStr", "." . extension, "Ptr", 0, "Ptr", 0, "Ptr", &numChars)
    numChars:= NumGet(&numChars, 0, "UInt")
    VarSetCapacity(progPath, numChars*2)
    DllCall("Shlwapi.dll\AssocQueryStringW"
    , "UInt", 0x0, "UInt", 0x2, "WStr", "." . extension, "Ptr", 0, "Ptr", &progPath, "Ptr", &numChars)
    return StrGet(&progPath,NumGet(&numChars, 0, "UInt"),"UTF-16")
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

playSound(ByRef sound) {
    DllCall( "winmm.dll\PlaySoundW", Ptr,0, UInt,0, UInt, 0 )
    Try SoundPlay, Nonexistent.notype
    if(IsObject(sound)){
        SoundPlay, % sound.path
        return 1
    }
    return DllCall( "winmm.dll\PlaySoundW", Ptr,&sound, UInt,0, UInt, 0x7 )
}

resRead(ByRef Var, Key, is_res:=1) { 
    if(!is_res) {
        if(!FileExist(key))
            return 0
        SplitPath, key,,, ext,,
        if(ext = "wav")
            FileRead, Var, *c %Key%
        else
            Var:= {path:Key}
        return 1
    }
    VarSetCapacity(Var, 128), VarSetCapacity(Var, 0)
    if hMod := DllCall( "GetModuleHandle", UInt,0,PTR )
        if hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10,PTR )
            if hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes,PTR )
                if pData := DllCall( "LockResource", UInt,hData,PTR )
                    return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes,PTR ) )
                        , DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
    return 1
}

UpdateSysTheme(){
    RegRead, reg
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    sys_theme:= !reg
}

isFileEmpty(file){
    FileGetSize, size , %file%
    return !size
}

runUpdater(p_silent:=1){
    if(FileExist(A_ScriptDir . "\updater.exe")){
        RunWait, %A_ScriptDir%\updater.exe -check-update, %A_ScriptDir%, UseErrorLevel
        if(ErrorLevel=-2 && !p_silent)
            MsgBox, 64, MicMute, You already have the latest verison installed
    }
}
