#InstallKeybdHook
#InstallMouseHook

#Include, <VA>
#Include, <OSD>
#Include, Config.ahk
#Include, AssetsLoader.ahk

Global current_config:= new Config, assets:= new Assetsloader, global_mute

assets.install_assets()
assets.init_tray()
current_config.init()
update_state()
OSD_spawn("MicMute", "4BB04F")

if (current_config.UpdateWithSystem){
    SetTimer, update_state, 5000
}
if (current_config.afkTimeout && !current_config.PushToTalk){
    SetTimer, check_activity, 1000
}
if (current_config.MuteHotkey=current_config.UnmuteHotkey){
    if(current_config.PushToTalk){
        Global ptt_key:= (StrSplit(current_config.MuteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
        assets.mute_sound:= "assets\ptt_mute.mp3"
        assets.unmute_sound:= "assets\ptt_unmute.mp3"
        Hotkey, % current_config.MuteHotkey , ptt_hotkey
        Menu, Tray, Delete, 1&
    }else{
        Hotkey, % current_config.MuteHotkey , toggle_hotkey
    }
}else{
    Hotkey, % current_config.MuteHotkey, mute_hotkey
    Hotkey, % current_config.UnmuteHotkey, unmute_hotkey
}

toggle_hotkey(){
    VA_SetMasterMute(!global_mute, current_config.Microphone)
    update_state()
    SetTimer, show_feedback, -1
}

ptt_hotkey(){
    unmute_hotkey()
    KeyWait, %ptt_key%
    mute_hotkey()
}

mute_hotkey(){
    if (global_mute)
        Return
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
    global_mute:= VA_GetMasterMute(current_config.Microphone)
    assets.update_tray()
}

check_activity:
    if (A_TimeIdlePhysical > current_config.afkTimeout * 60000)
        mute_hotkey()
Return

show_feedback:
    assets.show_feedback()
Return
