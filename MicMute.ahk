#NoEnv
#Include <OSD>
#Include <VA>
SendMode Input
SetWorkingDir %A_ScriptDir%
FileCreateDir, resources
FileInstall, .\resources\mute.mp3, resources\mute.mp3 
FileInstall, .\resources\unmute.mp3, resources\unmute.mp3
FileInstall, .\resources\unmute.ico, resources\unmute.ico 
FileInstall, .\resources\mute.ico, resources\mute.ico 
if (FileExist("resources\MicMute.ico")) {
    Menu, Tray, Icon, resources\MicMute.ico
}
Menu, Tray, NoStandard
Menu, Tray, Add, Edit Config, editConfig
Menu, Tray, Add, Open Key List, openKeyList
Menu, Tray, Add, Exit, exitApp
showOSD("MicMute Loading...", "4BB04F")
Global DeviceName:=
Global hotkeymute:=
Global hotkeyUnmute:=
Global soundFeedback:=
Global OSDFeedback:=
if (!FileExist("config.ini")) {
    IniWrite, Device_Name=""`nMute_Hotkey=""`nUnmute_Hotkey=""`nSound_Feedback=""`nOnScreen_Feedback=""`n, config.ini, settings
    openKeyList()
    editConfig()
}
readConfig()
if (hotkeymute=hotkeyUnmute){ ;toggle
    Hotkey, %hotkeymute%, toggleMic
}else{
    Hotkey, %hotkeymute%, muteMic
    Hotkey, %hotkeyUnmute%, unmuteMic
}
;******************Functions*******************
toggleMic(){
    state:= VA_GetMasterMute(DeviceName . ":1") ;1 muted 0 unmuted
    if (state)
        unmuteMic()
    else
        muteMic()
}
muteMic(){
    VA_SetMasterMute(1, DeviceName . ":1")
    if (soundFeedback){
        SoundPlay, resources\mute.mp3
    }
    if (OSDFeedback){
        OSD_destroy()
        showOSD("Microphone Muted", "FF2D02")
    }
    Menu, Tray, Icon, resources\mute.ico
}
unmuteMic(){
    VA_SetMasterMute(0, DeviceName . ":1")
    if (soundFeedback){
        SoundPlay, resources\unmute.mp3
    }
    if (OSDFeedback){
        OSD_destroy()
        showOSD("Microphone Online", "0066C1")
    }
    Menu, Tray, Icon, resources\unmute.ico
}
showOSD(txt, color){
    if (!isActiveWinFullscreen()){
        OSD_spawn(txt,color)
    }
}
isActiveWinFullscreen(){ ;returns true if the active window is fullscreen
    winID := WinExist( "A" )
    if ( !winID )
         Return false
    WinGet style, Style, ahk_id %WinID%
    WinGetPos ,,,winW,winH, %winTitle%
    return !((style & 0x20800000) or WinActive("ahk_class Progman") or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
}
readConfig(){
    IniRead, DeviceName, config.ini, settings, Device_Name, %A_Space%
    IniRead, hotkeymute, config.ini, settings, Mute_Hotkey, %A_Space%
    IniRead, hotkeyUnmute, config.ini, settings, Unmute_Hotkey, %A_Space%
    IniRead, soundFeedback, config.ini, settings, Sound_Feedback, %A_Space%
    IniRead, OSDFeedback, config.ini, settings, OnScreen_Feedback, %A_Space%
    if (!DeviceName or !hotkeymute or !hotkeyUnmute or soundFeedback="" or OSDFeedback="")
        editConfig()
}
editConfig(){
    RunWait, notepad.exe config.ini
    Reload
}
openKeyList(){
    Run, https://www.autohotkey.com/docs/KeyList.htm,, UseErrorLevel
}
exitApp(){
    ExitApp,
}