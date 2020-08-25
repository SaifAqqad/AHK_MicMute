#Include, config_GUI.ahk
Global current_config:= new config
if (!FileExist("config.ini") || isFileEmpty("config.ini"))
    current_config.writeIni()
current_config.readIni()
edit_config(){
    GUI_show()
    Reload
}
isFileEmpty(file){
   FileGetSize, size , %file%
   return !size
}
class config {
    Microphone:="", MuteHotkey:="", UnmuteHotkey:=""
    PushToTalk:=0, SoundFeedback:=0, OnscreenFeedback:=0
    ExcludeFullscreen:=0, UpdateWithSystem:=1, afkTimeout:=0
    
    readIni(){
        For key in this {
            IniRead, %key%, config.ini, settings, %key%, %A_Space%
            this[key]:= %key%
        }
        if (!Microphone)
            Microphone:= "capture"
        if (!MuteHotkey || !UnmuteHotkey){
            MsgBox, 48, MicMute, Mute/Unmute Hotkey need to be setup
            IfMsgBox, OK
                edit_config()
        }
        if (PushToTalk){
            mute_sound:="assets\ptt_mute.mp3", unmute_sound:="assets\ptt_unmute.mp3"
            Menu, Tray, Delete, 1&
        }
    }
    writeIni(){
        IniDelete, config.ini, settings
        For key, value in this 
            IniWrite, %value%, config.ini, settings, %Key% 
    }
}