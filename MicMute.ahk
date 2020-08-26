#InstallKeybdHook
#InstallMouseHook
#Include, <VA>
#Include, <OSD>
#Include, assets.ahk
init_tray()
#Include, config.ahk
OSD_spawn("MicMute", "4BB04F")
global global_mute:= ;1 muted
global keys:= StrSplit(current_config.MuteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")
update_state()
if (current_config.UpdateWithSystem){
    SetTimer, update_state, 5000
}
if (current_config.afkTimeout && !current_config.PushToTalk){
    SetTimer, check_activity, 1000
}
if (current_config.MuteHotkey=current_config.UnmuteHotkey){
    Hotkey,% current_config.MuteHotkey ,% current_config.PushToTalk? "ptt_hotkey" : "toggle_hotkey"
}else{
    Hotkey, % current_config.MuteHotkey, mute_hotkey
    Hotkey, % current_config.UnmuteHotkey, unmute_hotkey
}
;Hotkey Functions
toggle_hotkey(){
    VA_SetMasterMute(!global_mute, current_config.Microphone)
    update_state()
    SetTimer, show_feedback, -1
}
ptt_hotkey(){
    unmute_hotkey()
    KeyWait, % keys[keys.Length()]
    mute_hotkey()
}
mute_hotkey(){
    if (global_mute)
        return
    VA_SetMasterMute(1, current_config.Microphone)
    update_state()
    SetTimer, show_feedback, -1
}
unmute_hotkey(){
    if (!global_mute)
        return
    VA_SetMasterMute(0, current_config.Microphone)
    update_state()
    SetTimer, show_feedback, -1
}
update_state(){
    state:=VA_GetMasterMute(current_config.Microphone)
    if (state!=global_mute){
        global_mute:=state
        update_tray()
    }
}
check_activity(){
    if (A_TimeIdlePhysical > current_config.afkTimeout * 60000)
        mute_hotkey()
}