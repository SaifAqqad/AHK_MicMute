#Include, config_GUI.ahk
if (!FileExist("config.ini") || isFileEmpty("config.ini")) {
    IniWrite,Microphone=""`nMuteHotkey=""`nUnmuteHotkey=""`nPushToTalk=`nSoundFeedback=`nOnscreenFeedback=`nExcludeFullscreen=`nUpdateWithSystem=`nafkTimeout=, config.ini, settings
}
global device_name, hotkey_mute, hotkey_unmute, push_to_talk
global sound_feedback, OSD_feedback
global exclude_fullscreen, sys_update, afk_timeout
IniRead, device_name, config.ini, settings, Microphone, %A_Space%
IniRead, hotkey_mute, config.ini, settings, MuteHotkey, %A_Space%
IniRead, hotkey_unmute, config.ini, settings, UnmuteHotkey, %A_Space%
IniRead, push_to_talk, config.ini, settings, PushToTalk, 0
IniRead, sound_feedback, config.ini, settings, SoundFeedback, 0
IniRead, OSD_feedback, config.ini, settings, OnscreenFeedback, 0
IniRead, exclude_fullscreen, config.ini, settings, ExcludeFullscreen, 0
IniRead, sys_update, config.ini, settings, UpdateWithSystem, 1
IniRead, afk_timeout, config.ini, settings, afkTimeout, 0
if (!device_name)
    device_name:="capture"
if (hotkey_mute="" || hotkey_unmute=""){
    MsgBox, 48, MicMute, Mute/Unmute Hotkey need to be setup
    IfMsgBox, OK
        edit_config()
}
if (push_to_talk){
    mute_sound:="assets\ptt_mute.mp3", unmute_sound:="assets\ptt_unmute.mp3"
    Menu, Tray, Delete, 1&
}
edit_config(){
    GUI_show()
    Reload
}
write_config(){
    IniDelete, config.ini, settings
    IniWrite,Microphone=%device_name%`nMuteHotkey=%hotkey_mute%`nUnmuteHotkey=%hotkey_unmute%`nPushToTalk=%push_to_talk%`nSoundFeedback=%sound_feedback%`nOnscreenFeedback=%OSD_feedback%`nExcludeFullscreen=%exclude_fullscreen%`nUpdateWithSystem=%sys_update%`nafkTimeout=%afk_timeout% 
            ,config.ini, settings
}
isFileEmpty(file){
   FileGetSize, size , %file%
   return !size
}