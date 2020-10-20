Global OSD_state:= 0 
, OSD_txt:=
, OSD_MAIN_ACCENT:= "FF572D"
, OSD_RED_ACCENT:= "DC3545"
, OSD_BLUE_ACCENT:= "007BFF"

OSD_spawn(txt, OSD_Accent, exclude_fullscreen:=0){
    if (exclude_fullscreen && OSD_isActiveWinFullscreen())
        return
    if (OSD_state = 0){
        SetFormat, integer, d
        Gui, OSD:New,,Configuration 
        Gui, Color,% sys_theme? "232323":"f2f2f2" , OSD_Accent
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border
        Gui, Margin, 30
        Gui, Font, s11 w500 c%OSD_Accent%, Segoe UI
        Gui, Add, Text, vOSD_txt w150 Center, %txt%
        SysGet, MonitorWorkArea, MonitorWorkArea, 0
        OSD_yPos:= MonitorWorkAreaBottom * 0.95
        Gui, Show, AutoSize NoActivate xCenter y%OSD_yPos%
        OSD_state:= 1
    }else{
        Gui, OSD:Default
        Gui, Font, s11 w500 c%OSD_Accent%
        GuiControl, Font, OSD_txt
        GuiControl, Text, OSD_txt, %txt% 
    }
    SetTimer, OSD_destroy, 1000
}
OSD_destroy(){
    Gui, OSD:Default
    Gui, Destroy
    OSD_state := 0
    SetTimer, OSD_destroy, Off
}
OSD_isActiveWinFullscreen(){ ;returns true if the active window is fullscreen
    winID := WinExist( "A" )
    if ( !winID )
        Return false
    WinGet style, Style, ahk_id %WinID%
    WinGetPos ,,,winW,winH, %winTitle%
    return !((style & 0x20800000) or WinActive("ahk_class Progman") 
    or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
}