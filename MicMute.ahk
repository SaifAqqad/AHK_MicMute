#NoEnv
#Include <OSD>
#Include <VA>
SendMode Input
SetWorkingDir %A_ScriptDir%
FileCreateDir, resources
FileInstall, .\resources\mute.mp3, resources\mute.mp3 
FileInstall, .\resources\unmute.mp3, resources\unmute.mp3
FileInstall, .\resources\default_white.ico, resources\default_white.ico 
FileInstall, .\resources\default_dark.ico, resources\default_dark.ico 
FileInstall, .\resources\mute_white.ico, resources\mute_white.ico 
FileInstall, .\resources\mute_dark.ico, resources\mute_dark.ico 
showOSD("MicMute Loading...", "4BB04F")
Global device_name:=
Global hotkey_mute:=
Global hotkey_unmute:=
Global sound_feedback:=
Global OSD_feedback:=
Global mute_ico:=
Global default_ico:=
loadtray()
if (!FileExist("config.ini")) {
    IniWrite, Device_Name=""`nMute_Hotkey=""`nUnmute_Hotkey=""`nSound_Feedback=`nOnScreen_Feedback=`n, config.ini, settings
    openKeyList()
    editConfig()
}
readConfig()
if (hotkey_mute=hotkey_unmute){ ;toggle
    Hotkey, %hotkey_mute%, toggleMic
}else{
    Hotkey, %hotkey_mute%, muteMic
    Hotkey, %hotkey_unmute%, unmuteMic
}
;******************Functions*******************
toggleMic(){
    state:= VA_GetMasterMute(device_name . ":1") ;1 muted 0 unmuted
    if (state)
        unmuteMic()
    else
        muteMic()
}
muteMic(){
    VA_SetMasterMute(1, device_name . ":1")
    if (sound_feedback){
        SoundPlay, resources\mute.mp3
    }
    if (OSD_feedback){
        OSD_destroy()
        showOSD("Microphone Muted", "FF2D02")
    }
    Menu, Tray, Icon, %mute_ico%
}
unmuteMic(){
    VA_SetMasterMute(0, device_name . ":1")
    if (sound_feedback){
        SoundPlay, resources\unmute.mp3
    }
    if (OSD_feedback){
        OSD_destroy()
        showOSD("Microphone Online", "0066C1")
    }
    Menu, Tray, Icon, %default_ico%
}
showOSD(txt, color){
    if (!isActiveWinFullscreen()){
        OSD_spawn(txt,color)
    }
}
readConfig(){
    IniRead, device_name, config.ini, settings, Device_Name, %A_Space%
    IniRead, hotkey_mute, config.ini, settings, Mute_Hotkey, %A_Space%
    IniRead, hotkey_unmute, config.ini, settings, Unmute_Hotkey, %A_Space%
    IniRead, sound_feedback, config.ini, settings, Sound_Feedback, %A_Space%
    IniRead, OSD_feedback, config.ini, settings, OnScreen_Feedback, %A_Space%
    if (!device_name or !hotkey_mute or !hotkey_unmute or sound_feedback="" or OSD_feedback="")
        editConfig()
}
editConfig(){
    RunWait, notepad.exe config.ini
    Reload
}
loadtray(){
    RegRead, sysTheme
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    default_ico:= sysTheme? "resources\default_dark.ico" : "resources\default_white.ico"
    mute_ico:= sysTheme? "resources\mute_dark.ico" : "resources\mute_white.ico"
    if (FileExist(default_ico)) {
        Menu, Tray, Icon, %default_ico%
    }
    Menu, Tray, NoStandard
    Menu, Tray, Add, Edit Config, editConfig
    Menu, Tray, Add, Open Key List, openKeyList
    Menu, Tray, Add, Exit, exitApp
}
isActiveWinFullscreen(){ ;returns true if the active window is fullscreen
    winID := WinExist( "A" )
    if ( !winID )
         Return false
    WinGet style, Style, ahk_id %WinID%
    WinGetPos ,,,winW,winH, %winTitle%
    return !((style & 0x20800000) or WinActive("ahk_class Progman") 
            or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
}
openKeyList(){
    Run, https://www.autohotkey.com/docs/KeyList.htm,, UseErrorLevel
}
exitApp(){
    ExitApp,
}