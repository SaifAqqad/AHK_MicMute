if (!FileExist("config.ini") || isFileEmpty("config.ini")) {
    IniWrite, Microphone=""`nMuteHotkey=""`nUnmuteHotkey=""`nSoundFeedback=`nOnscreenFeedback=`nExcludeFullscreen=`nUpdateWithSystem=`n, config.ini, settings
    edit_config()
}
global device_name:="", global hotkey_mute:="", global hotkey_unmute:=""
global sound_feedback:="", global OSD_feedback:=""
global exclude_fullscreen:="", global sys_update:=""
global mute_ico:="", global default_ico:=""
IniRead, device_name, config.ini, settings, Microphone, %A_Space%
IniRead, hotkey_mute, config.ini, settings, MuteHotkey, %A_Space%
IniRead, hotkey_unmute, config.ini, settings, UnmuteHotkey, %A_Space%
IniRead, sound_feedback, config.ini, settings, SoundFeedback, 0
IniRead, OSD_feedback, config.ini, settings, OnscreenFeedback, 0
IniRead, exclude_fullscreen, config.ini, settings, ExcludeFullscreen, 0
IniRead, sys_update, config.ini, settings, UpdateWithSystem, 0
if (!device_name)
    device_name:="capture"
if (!hotkey_mute or !hotkey_unmute)
    edit_config()
edit_config(){
    RunWait, notepad config.ini
    Reload
}
isFileEmpty(file){
   FileGetSize, size , %file%
   return !size
}