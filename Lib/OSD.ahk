Global OSD_state:= 0 
Global OSD_txt:=
OSD_spawn(txt, OSD_Accent, exclude_fullscreen:=0){
    if (exclude_fullscreen && isActiveWinFullscreen())
        return
    if (OSD_state = 0){
        SetFormat, integer, d
        Gui, Color, 191919, %OSD_Accent%
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border
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
isActiveWinFullscreen(){ ;returns true if the active window is fullscreen
    winID := WinExist( "A" )
    if ( !winID )
         Return false
    WinGet style, Style, ahk_id %WinID%
    WinGetPos ,,,winW,winH, %winTitle%
    return !((style & 0x20800000) or WinActive("ahk_class Progman") 
            or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
}