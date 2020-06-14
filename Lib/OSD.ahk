Global OSD_state:= 0 ;0 -> closed ;1 -> open
Global OSD_txt:=
OSD_spawn(txt, OSD_Accent ){
    if (OSD_state = 0){
        SetFormat, integer, d
        Gui, Color, 191919, %OSD_Accent%
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border
        WinSet, Transparent, 230, ahk_class AutoHotkeyGUI
        Gui, Font, s11, Segoe UI
        Gui, Add, Text, c%OSD_Accent% vOSD_txt W165 Center, %txt%
        SysGet, MonitorWorkArea, MonitorWorkArea, 0
        OSD_yPos:= MonitorWorkAreaBottom * 0.95
        Gui, Show, AutoSize NoActivate xCenter y%OSD_yPos%
        OSD_state:= 1
    }else{
        GuiControl, Text, OSD_txt, %txt% 
    }
    SetTimer, OSD_destroy, 700
}
OSD_destroy(){
    Gui, Destroy
    OSD_state := 0
    SetTimer, OSD_destroy, Off
}