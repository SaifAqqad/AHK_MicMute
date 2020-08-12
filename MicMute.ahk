#Include, <VA>
#Include, <OSD>
#Include, config.ahk
#Include, assets.ahk
OSD_spawn("MicMute", "4BB04F")
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
    VA_SetMasterMute(!global_mute, device_name)
    update_state()
    show_feedback(global_mute, sound_feedback, OSD_feedback)
}
mute_hotkey(){
    if (global_mute)
        return
    VA_SetMasterMute(1, device_name)
    update_state()
    show_feedback(global_mute, sound_feedback, OSD_feedback)
}
unmute_hotkey(){
    if (!global_mute)
        return
    VA_SetMasterMute(0, device_name)
    update_state()
    show_feedback(global_mute, sound_feedback, OSD_feedback)
}
update_state(){
    state:=VA_GetMasterMute(device_name)
    if (state!=global_mute){
        global_mute:=state
        update_tray(global_mute)
    }
}