#Include, config_GUI.ahk
class Config {
    Microphone:="", MuteHotkey:="", UnmuteHotkey:=""
    PushToTalk:=0, SoundFeedback:=0, OnscreenFeedback:=0
    ExcludeFullscreen:=0, UpdateWithSystem:=1, afkTimeout:=0
    
    init(){
        if (!FileExist("config.ini") || isFileEmpty("config.ini"))
            this.writeIni()
        this.readIni()
    }

    edit(){
        GUI_show()
        Reload
    }

    readIni(){
        For key in this {
            IniRead, %key%, config.ini, settings, %key%, %A_Space%
            this[key]:= %key%
        }
        if (!this.Microphone)
            Microphone:= "capture"
        if (!this.MuteHotkey || !this.UnmuteHotkey){
            MsgBox, 48, MicMute, MicMute needs to be set up
            IfMsgBox, OK
            this.edit()
        }
        if (this.PushToTalk){
            
        }
    }
    writeIni(){
        IniDelete, config.ini, settings
        For key, value in this 
            IniWrite, %value%, config.ini, settings, %Key% 
    }
}
isFileEmpty(file){
    FileGetSize, size , %file%
    return !size
}