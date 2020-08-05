#Include, <VA>
#Include, <OSD>
OSD_spawn("Loading config...", "4BB04F")
#Include, resources.ahk
global mic_state:= ;1 muted
if (sys_update){
    SetTimer, update_state, 100
}
if (hotkey_mute=hotkey_unmute){
    Hotkey, %hotkey_mute%, toggle_hotkey
}else{
    Hotkey, %hotkey_mute%, mute_hotkey
    Hotkey, %hotkey_unmute%, unmute_hotkey
}
update_state()
toggle_hotkey(){
    VA_SetMasterMute(!mic_state, device_name . ":1")
    update_state()
    feedback(mic_state)
}
mute_hotkey(){
    if (mic_state)
        return
    VA_SetMasterMute(1, device_name . ":1")
    update_state()
    feedback(mic_state)
}
unmute_hotkey(){
    if (!mic_state)
        return
    VA_SetMasterMute(0, device_name . ":1")
    update_state()
    feedback(mic_state)

}
update_state(){
    state:=VA_GetMasterMute(device_name . ":1")
    if (state!=mic_state){
        mic_state:=state
        update_tray(mic_state)
    }
}