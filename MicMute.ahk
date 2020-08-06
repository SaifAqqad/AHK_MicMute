#Include, <VA>
#Include, <OSD>
OSD_spawn("Loading config...", "4BB04F")
#Include, resources.ahk
global global_mute:= ;1 muted
init_tray()
update_state()
if (sys_update){
    SetTimer, update_state, 500
}
if (hotkey_mute=hotkey_unmute){
    Hotkey, %hotkey_mute%, toggle_hotkey
}else{
    Hotkey, %hotkey_mute%, mute_hotkey
    Hotkey, %hotkey_unmute%, unmute_hotkey
}
;Hotkey Functions
toggle_hotkey(){
    VA_SetMasterMute(!global_mute, device_name . ":1")
    update_state()
    show_feedback(global_mute)
}
mute_hotkey(){
    if (global_mute)
        return
    VA_SetMasterMute(1, device_name . ":1")
    update_state()
    show_feedback(global_mute)
}
unmute_hotkey(){
    if (!global_mute)
        return
    VA_SetMasterMute(0, device_name . ":1")
    update_state()
    show_feedback(global_mute)
}
;
update_state(){
    state:=VA_GetMasterMute(device_name . ":1")
    if (state!=global_mute){
        global_mute:=state
        update_tray(global_mute)
    }
}
update_tray(state){
    Menu, Tray, Icon, % state? mute_ico : default_ico
    Menu, Tray, Tip, % state? "Microphone Muted" : "Microphone Online"
}
show_feedback(state){
    if (sound_feedback){
        SoundPlay,% state? "resources\mute.mp3" : "resources\unmute.mp3"
    }
    if (OSD_feedback){
        OSD_destroy()
        if (state)
            OSD_spawn("Microphone Muted", "DC3545", exclude_fullscreen)
        else
            OSD_spawn("Microphone Online", "007BFF", exclude_fullscreen)
    }
}
;tray initialization functions
init_tray(){
    RegRead, sysTheme
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    default_ico:= sysTheme? "resources\default_black.ico" : "resources\default_white.ico"
    mute_ico:= sysTheme? "resources\mute_black.ico" : "resources\mute_white.ico"
    if (FileExist(default_ico)) {
        Menu, Tray, Icon, %default_ico%
    }
    Menu, Tray, Tip, MicMute  
    Menu, Tray, NoStandard
    Menu, Tray, Add, Edit Config, edit_config
    Menu, Tray, Add, Help, launch_help
    Menu, Tray, Add, Exit, exit
}
launch_help(){
    Run, https://github.com/SaifAqqad/AHK_MicMute#usage
}
exit(){
    ExitApp
}