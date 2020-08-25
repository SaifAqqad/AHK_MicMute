Global GUI_ddl
Global GUI_mute_hotkey, GUI_mute_adv_hotkey, GUI_mute_adv_checkbox, GUI_mute_wildcard, GUI_mute_passthrough
Global GUI_unmute_hotkey, GUI_unmute_adv_hotkey, GUI_unmute_adv_checkbox, GUI_unmute_wildcard, GUI_unmute_passthrough
Global GUI_ptt_radio, GUI_afk_timeout, GUI_afk_timeout_edit
Global GUI_feedback_OSD, GUI_feedback_OSD_exFullscreen, GUI_feedback_sound
Global GUI_mute_wildcard_TT:="Fire the hotkey even if extra modifiers `nare being held down." , GUI_mute_passthrough_TT:="When the hotkey fires, its key's native function `nwill not be blocked (hidden from the system)."
Global GUI_unmute_wildcard_TT:=GUI_mute_wildcard_TT, GUI_unmute_passthrough_TT:=GUI_mute_passthrough_TT
Global GUI_afk_timeout_TT:="Mute the microphone when the user is AFK (idle) `nfor longer than the AFK Timeout. set to 0 to disable it.", GUI_afk_timeout_edit_TT:= GUI_afk_timeout_TT
GUI_show(){
    Suspend, On
    Menu, Tray, Icon, .\assets\MicMute.ico
    Gui, config:New,,MicMute configuration 
    Gui, Font, S8 CDefault, Segoe UI
    
    Gui, Add, Text, x42 y29 w70 h20 +Left, Microphone
    Gui, Add, DropDownList , vGUI_ddl x112 y29 w280 R5 
    Gui, Add, Button, x422 y29 w100 h20 gRefreshList , Refresh Devices
    
    Gui, Add, Text, x62 y79 w80 h20 +Left, Mute hotkey
    Gui, Add, Hotkey, vGUI_mute_hotkey x82 y99 w130 h20 ,
    Gui, Add, Edit, vGUI_mute_adv_hotkey Hidden x82 y99 w130 h20 ,
    Gui, Add, CheckBox, vGUI_mute_adv_checkbox gMute_adv_checkbox x242 y129 w110 h20 , Advanced hotkey
    Gui, Add, CheckBox, vGUI_mute_wildcard gMute_wildcard x242 y99 w70 h20 , Wildcard
    Gui, Add, CheckBox, vGUI_mute_passthrough gMute_passthrough x322 y99 w100 h20 , Passthough key
    
    Gui, Add, Text, x62 y159 w80 h20 +Left, Unmute hotkey
    Gui, Add, Hotkey, vGUI_unmute_hotkey x82 y179 w130 h20 ,
    Gui, Add, Edit, vGUI_unmute_adv_hotkey Hidden x82 y179 w130 h20 ,
    Gui, Add, CheckBox, vGUI_unmute_adv_checkbox gUnmute_adv_checkbox x242 y209 w110 h20 , Advanced hotkey
    Gui, Add, CheckBox, vGUI_unmute_wildcard gUnmute_wildcard x242 y179 w70 h20 , Wildcard
    Gui, Add, CheckBox, vGUI_unmute_passthrough gUnmute_passthrough x322 y179 w100 h20 , Passthough key
    
    Gui, Add, GroupBox, x42 y59 w410 h180 , Hotkeys
    
    Gui, Add, Radio, gPtt x472 y89 w160 h30 +Left Checked, Separate hotkeys
    Gui, Add, Radio, gPtt x472 y119 w160 h30 , Toggle
    Gui, Add, Radio, vGUI_ptt_radio gPtt x472 y149 w160 h30 +Left, Push To Talk
    
    Gui, Add, GroupBox, x42 y249 w410 h110 , Feedback
    Gui, Add, CheckBox, vGUI_feedback_OSD gfeedback_OSD x72 y279 w130 h20 +Left, On-screen feedback
    Gui, Add, CheckBox, vGUI_feedback_OSD_exFullscreen x222 y279 w150 h20 +Disabled, Exclude fullscreen apps
    Gui, Add, CheckBox, vGUI_feedback_sound x72 y319 w120 h20 , Sound feedback
    
    Gui, Add, Text, x462 y209 w70 h20 +Center, AFK Timeout
    Gui, Add, Edit, x502 y229 w60 h20 vGUI_afk_timeout_edit
    Gui, Add, UpDown,x542 y229 w20 h20 vGUI_afk_timeout Range0-120, 0
    Gui, Add, Text, x562 y239 w30 h20 +Center, Min
    
    Gui, Add, Button, x482 y319 w100 h30 gSaveConfig, Save Config
    Gui, Add, Button, x482 y279 w100 h30 gRestoreConfig , Restore
    restoreConfig()
    Gui, Show, x892 y206 h390 w646, MicMute configuration
    OnMessage(0x200, "WM_MOUSEMOVE")
    WinWaitClose, MicMute configuration ahk_exe MicMute.exe
    Suspend, Off
}

RefreshList(){
    selected_device:= VA_GetDevice(current_config.Microphone)
    dList := VA_GetCaptureDeviceList()
    GuiControl,, GUI_ddl, |
    loop % dList.Length()
    {
        dev:= dList[A_Index].Name
        if (selected_device && VA_GetDeviceName(selected_device)=dev){
            GuiControl,, GUI_ddl, % (dList[A_Index].isDefault? "(Default) " . dev : dev) . "||"
        }else{
            GuiControl,, GUI_ddl, % dList[A_Index].isDefault? "(Default) " . dev . "||": dev . "|"
        }
    }
}
SaveConfig(){
    Gui, Submit, NoHide
    current_config.Microphone:= GUI_ddl
    if (GUI_mute_adv_checkbox){
        current_config.MuteHotkey:= GUI_mute_adv_hotkey , current_config.UnmuteHotkey:= GUI_mute_adv_hotkey
    }else{
        if (GUI_mute_wildcard){
            GUI_mute_hotkey := "*" . GUI_mute_hotkey
        }else{
            GUI_mute_hotkey := StrReplace(GUI_mute_adv_hotkey, "*")
        }
        if (GUI_mute_passthrough){
            GUI_mute_hotkey := "~" . GUI_mute_hotkey
        }else{
            GUI_mute_hotkey := StrReplace(GUI_mute_hotkey, "~")
        }
        current_config.MuteHotkey:= GUI_mute_hotkey , current_config.UnmuteHotkey:= GUI_mute_hotkey
    }
    if (GUI_ptt_radio=1){ ; 1 => seperate hotkeys
        if (GUI_unmute_adv_checkbox){
            current_config.UnmuteHotkey:= GUI_unmute_adv_hotkey
        }else{
            if (GUI_unmute_wildcard){
                GUI_unmute_hotkey := "*" . GUI_unmute_hotkey
            }else{
                GUI_unmute_hotkey := StrReplace(GUI_unmute_adv_hotkey, "*")
            }
            if (GUI_unmute_passthrough){
                GUI_unmute_hotkey := "~" . GUI_unmute_hotkey
            }else{
                GUI_unmute_hotkey := StrReplace(GUI_unmute_hotkey, "~")
            }
            current_config.UnmuteHotkey:= GUI_unmute_hotkey
        }
    }
    current_config.PushToTalk:= GUI_ptt_radio>2
    current_config.afkTimeout:= GUI_afk_timeout
    current_config.OnscreenFeedback:= GUI_feedback_OSD
    current_config.ExcludeFullscreen:= GUI_feedback_OSD_exFullscreen
    current_config.SoundFeedback:= GUI_feedback_sound
    current_config.writeIni()
    Gui, Destroy
}
RestoreConfig(){
    RefreshList()
    if (current_config.MuteHotkey){
        GuiControl, Hide, GUI_mute_hotkey
        GuiControl, Show, GUI_mute_adv_hotkey
        GuiControl,, GUI_mute_adv_checkbox, 1
        GuiControl,,GUI_mute_adv_hotkey, % current_config.MuteHotkey
        if (InStr(current_config.MuteHotkey, "*"))
            GuiControl,, GUI_mute_wildcard, 1
        else
            GuiControl,, GUI_mute_wildcard, 0
        if (InStr(current_config.MuteHotkey, "~"))
            GuiControl,, GUI_mute_passthrough, 1
        else
            GuiControl,, GUI_mute_passthrough, 0
    }
    if (current_config.UnmuteHotkey){
        GuiControl, Hide, GUI_unmute_hotkey
        GuiControl, Show, GUI_unmute_adv_hotkey
        GuiControl,, GUI_unmute_adv_checkbox, 1
        GuiControl,,GUI_unmute_adv_hotkey, % current_config.UnmuteHotkey
        if (InStr(current_config.UnmuteHotkey, "*"))
            GuiControl,, GUI_unmute_wildcard, 1
        else
            GuiControl,, GUI_unmute_wildcard, 0
        if (InStr(current_config.UnmuteHotkey, "~"))
            GuiControl,, GUI_unmute_passthrough, 1
        else
            GuiControl,, GUI_unmute_passthrough, 0
    }
    if (current_config.PushToTalk){
        GuiControl,, GUI_ptt_radio, 1
    }else if (current_config.MuteHotkey && current_config.MuteHotkey=current_config.UnmuteHotkey){
        GuiControl,, Toggle, 1
    }else{
        GuiControl,, Separate hotkeys, 1
    }
    Ptt()
    if (current_config.afkTimeout)
        GuiControl,, GUI_afk_timeout, % current_config.afkTimeout
    else
        GuiControl,, GUI_afk_timeout, 0
    if (current_config.OnscreenFeedback)
        GuiControl,, GUI_feedback_OSD, 1
    else
        GuiControl,, GUI_feedback_OSD, 0
    feedback_OSD()
    if (current_config.ExcludeFullscreen)
        GuiControl,, GUI_feedback_OSD_exFullscreen, 1
    else
        GuiControl,, GUI_feedback_OSD_exFullscreen, 0
    if (current_config.SoundFeedback)
        GuiControl,, GUI_feedback_sound, 1
    else
        GuiControl,, GUI_feedback_sound, 0
}
Mute_adv_checkbox(){
    Gui, Submit, NoHide
    if (GUI_mute_adv_checkbox){
        GuiControl, Hide, GUI_mute_hotkey
        GuiControl, Show, GUI_mute_adv_hotkey
        GuiControl,,GUI_mute_adv_hotkey, %GUI_mute_hotkey%
        Mute_wildcard()
        Mute_passthrough()
    }else{
        GuiControl, Show, GUI_mute_hotkey
        GuiControl, Hide, GUI_mute_adv_hotkey
    }
}
Mute_wildcard(){
    Gui, Submit, NoHide
    if (GUI_mute_adv_checkbox){
        if (GUI_mute_wildcard){
            GuiControl,, GUI_mute_adv_hotkey, % InStr(GUI_mute_adv_hotkey, "~")? StrReplace(GUI_mute_adv_hotkey, "~" , "~*") : "*" . GUI_mute_adv_hotkey
        }else{
            GuiControl,, GUI_mute_adv_hotkey, % StrReplace(GUI_mute_adv_hotkey, "*")
        }
    }else{
        if (GUI_mute_wildcard){
            GUI_mute_hotkey := "*" . GUI_mute_hotkey
        }else{
            GUI_mute_hotkey := StrReplace(GUI_mute_adv_hotkey, "*")
        }
    }
}
Mute_passthrough(){
    Gui, Submit, NoHide
    if (GUI_mute_adv_checkbox){
        if (GUI_mute_passthrough){
            GuiControl,, GUI_mute_adv_hotkey, ~%GUI_mute_adv_hotkey%
        }else{
            GuiControl,, GUI_mute_adv_hotkey, % StrReplace(GUI_mute_adv_hotkey, "~")
        }
    }else{
        if (GUI_mute_passthrough){
            GUI_mute_hotkey := "~" . GUI_mute_hotkey
        }else{
            GUI_mute_hotkey := StrReplace(GUI_mute_hotkey, "~")
        }
    }
}
Unmute_adv_checkbox(){
    Gui, Submit, NoHide
    if (GUI_unmute_adv_checkbox){
        GuiControl, Hide, GUI_unmute_hotkey
        GuiControl, Show, GUI_unmute_adv_hotkey
        GuiControl,, GUI_unmute_adv_hotkey, %GUI_unmute_hotkey%
        Unmute_wildcard()
        Unmute_passthrough()
    }else{
        GuiControl, Show, GUI_unmute_hotkey
        GuiControl, Hide, GUI_unmute_adv_hotkey
    }
}
Unmute_wildcard(){
    Gui, Submit, NoHide
    if (GUI_unmute_adv_checkbox){
        if (GUI_unmute_wildcard){
            GuiControl,, GUI_unmute_adv_hotkey, % InStr(GUI_unmute_adv_hotkey, "~")? StrReplace(GUI_unmute_adv_hotkey, "~" , "~*") : "*" . GUI_unmute_adv_hotkey
        }else{
            GuiControl,, GUI_unmute_adv_hotkey, % StrReplace(GUI_unmute_adv_hotkey, "*")
        }
    }else{
        if (GUI_unmute_wildcard){
            GUI_unmute_hotkey := "*" . GUI_unmute_hotkey
        }else{
            GUI_unmute_hotkey := StrReplace(GUI_unmute_hotkey, "*")
        }
    }
}
Unmute_passthrough(){
    Gui, Submit, NoHide
    if (GUI_unmute_adv_checkbox){
        if (GUI_unmute_passthrough){
            GuiControl,, GUI_unmute_adv_hotkey, ~%GUI_unmute_adv_hotkey%
        }else{
            GuiControl,, GUI_unmute_adv_hotkey, % StrReplace(GUI_unmute_adv_hotkey, "~")
        }
    }else{
        if (GUI_unmute_passthrough){
            GUI_unmute_hotkey := "~" . GUI_unmute_hotkey
        }else{
            GUI_unmute_hotkey := StrReplace(GUI_unmute_adv_hotkey, "~")
        }
    }
}
Ptt(){
    Gui, Submit, NoHide
    if (GUI_ptt_radio>1){
        GuiControl, Disable, GUI_unmute_hotkey
        GuiControl, Disable, GUI_unmute_adv_hotkey
        GuiControl, Disable, GUI_unmute_adv_checkbox
        GuiControl, Disable, GUI_unmute_wildcard
        GuiControl, Disable, GUI_unmute_passthrough
    }else{
        GuiControl, Enable, GUI_unmute_hotkey
        GuiControl, Enable, GUI_unmute_adv_hotkey
        GuiControl, Enable, GUI_unmute_adv_checkbox
        GuiControl, Enable, GUI_unmute_wildcard
        GuiControl, Enable, GUI_unmute_passthrough
        
    }
}
feedback_OSD(){
    Gui, Submit, NoHide
    if (GUI_feedback_OSD)
        GuiControl, Enable, GUI_feedback_OSD_exFullscreen
    else
        GuiControl, Disable, GUI_feedback_OSD_exFullscreen
    
}
WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
    return
    
    DisplayToolTip:
        SetTimer, DisplayToolTip, Off
        CurrControl:= StrReplace(CurrControl, " ")
        ToolTip % %CurrControl%_TT 
        SetTimer, RemoveToolTip, 5000
    return
    
    RemoveToolTip:
        SetTimer, RemoveToolTip, Off
        ToolTip
    return
}