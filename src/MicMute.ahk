;compiler directives
;@Ahk2Exe-Let Res = %A_ScriptDir%\resources
;@Ahk2Exe-SetMainIcon %U_Res%\MicMute.ico
;@Ahk2Exe-SetVersion 0.7
;@Ahk2Exe-SetName MicMute
;@Ahk2Exe-ExeName %A_ScriptDir%\updater\MicMute.exe
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
;@Ahk2Exe-AddResource %U_Res%\dark.css
;@Ahk2Exe-AddResource %U_Res%\MicMute.png


#InstallKeybdHook
#InstallMouseHook
#SingleInstance, ignore

#Include, <VA>
#Include, <OSD>
#Include, GUI.ahk
#Include, Config.ahk
#Include, Tray.ahk

;auto_exec begin
SetWorkingDir %A_ScriptDir%
Global conf, watched_profiles, current_profile, watched_profile
, global_mute, ptt_key, mute_sound, unmute_sound, sys_theme
init()
SetTimer, runUpdater, -1
;auto_exec end

init(){
    conf:= new Config
    , watched_profiles:= Array()
    , current_profile:=""
    , watched_profile:=""
    , global_mute:=""
    , ptt_key:=""
    , mute_sound:=""
    , unmute_sound:=""
    , sys_theme:=""
    for i, prof in conf.Profiles 
        if(prof.LinkedApp)
            watched_profiles.Push(prof)
    if(watched_profiles.Length()){
        SetTimer, checkProfiles, 3000
    }else{
        Try SetTimer, checkProfiles, Off
    }
    UpdateSysTheme()
    tray_init()
    switchProfile()
    updateState()
}

tgl(){
    VA_SetMasterMute(!global_mute, current_profile.Microphone)
    updateState()
    SetTimer, showFeedback, -1, 5
}

ptt(){
    unmute()
    KeyWait, %ptt_key%
    mute()
}

mute(){
    if (global_mute)
        Return
    VA_SetMasterMute(1, current_profile.Microphone)
    updateState()
    SetTimer, showFeedback, -1, 5
}

unmute(){
    if (!global_mute)
        return
    VA_SetMasterMute(0, current_profile.Microphone)
    updateState()
    SetTimer, showFeedback, -1, 5
}

switchProfile(p_name:=""){
    if(current_profile){
        disableHotkeys()
        SetTimer, updateState, Off
        SetTimer, checkActivity, Off
        Menu, profiles, Uncheck, % current_profile.ProfileName
    }
    current_profile:= conf.getProfile(p_name)
    Menu, profiles, Check, % current_profile.ProfileName
    if (current_profile.UpdateWithSystem){
        SetTimer, updateState, 1500
    }
    if (current_profile.afkTimeout && !current_profile.PushToTalk){
        SetTimer, checkActivity, 1000
    }
    Try initHotkeys()
    catch {
        MsgBox, 64, MicMute, % Format("'{}' profile needs to be setup",current_profile.ProfileName)
        editConfig()
    }
    OSD_spawn(Format("Profile: '{}'", current_profile.ProfileName),OSD_MAIN_ACCENT,current_profile.ExcludeFullscreen)
}

disableHotkeys(){
    Try Hotkey, % current_profile.MuteHotkey , Off, Off
    Try Hotkey, % current_profile.UnmuteHotkey, Off, Off
}

initHotkeys(){
    resRead(mute_sound, Format("{:U}", "mute.wav"))
    resRead(unmute_sound, Format("{:U}","unmute.wav"))
    Menu, Tray, Enable, Toggle microphone
    Menu, Tray, Default, Toggle microphone
    if (current_profile.MuteHotkey=current_profile.UnmuteHotkey){
        if(current_profile.PushToTalk){
            VA_SetMasterMute(1, current_profile.Microphone)
            ptt_key:= (StrSplit(current_profile.MuteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
            resRead(mute_sound, Format("{:U}", "ptt_off.wav"))
            resRead(unmute_sound, Format("{:U}","ptt_on.wav"))
            Hotkey, % current_profile.MuteHotkey , ptt, On
            Menu, Tray, Disable, Toggle microphone
            Menu, Tray, NoDefault
        }else{
            Hotkey, % current_profile.MuteHotkey , tgl, On
        }
    }else{
        Hotkey, % current_profile.MuteHotkey, mute, On
        Hotkey, % current_profile.UnmuteHotkey, unmute, On
    } 
}

updateState(){
    global_mute:= VA_GetMasterMute(current_profile.Microphone)
    UpdateSysTheme()
    if(global_mute){
        tooltipTxt:= "Microphone Muted"
        tray_update(sys_theme? U_muteWhite : U_muteBlack, tooltipTxt)
    }else{
        tooltipTxt:= "Microphone Online"
        tray_update(sys_theme? U_defaultWhite : U_defaultBlack, tooltipTxt)
    }
}

checkActivity(){
    if (A_TimeIdlePhysical > current_profile.afkTimeout * 60000)
        mute()
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
        if (global_mute)
            OSD_spawn("Microphone Muted", OSD_RED_ACCENT, current_profile.ExcludeFullscreen)
        else
            OSD_spawn("Microphone Online", OSD_BLUE_ACCENT, current_profile.ExcludeFullscreen)
    }
    if (current_profile.SoundFeedback){
        playSound(global_mute? mute_sound : unmute_sound)
    }
}

editConfig(){
    OSD_destroy()
    if(current_profile){
        disableHotkeys()
        SetTimer, updateState, Off
        SetTimer, checkActivity, Off
        SetTimer, checkProfiles, Off
    }
    Menu, Tray, Icon, %A_ScriptFullPath%, 1
    if(GetKeyState("Shift", "P")){
        Try Run, open "config.json",,,procId
        catch
            Run notepad.exe "config.json",,,procId
        WinWait, ahk_pid %procId%
        WinWaitClose, ahk_pid %procId%
    }else{
        GUI_show()
    }
    init()
}

playSound( ByRef Sound ) {
    return DllCall( "winmm.dll\PlaySoundA", Ptr,&Sound, UInt,0, UInt, 0x7 )
}

ResRead( ByRef Var, Key ) { 
    VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
    if ! ( A_IsCompiled ) {
        FileGetSize, nSize, %Key%
        FileRead, Var, *c %Key%
        return nSize
    }
    if hMod := DllCall( "GetModuleHandle", UInt,0,PTR )
        if hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10,PTR )
            if hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes,PTR )
                if pData := DllCall( "LockResource", UInt,hData,PTR )
                    return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes,PTR ) )
                        , DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
    return 0 
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