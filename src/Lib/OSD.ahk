Global OSD_state:= 0 
, OSD_txt:=
, OSD_MAIN_ACCENT:= "FF572D"
, OSD_MUTE_ACCENT:= "DC3545"
, OSD_UNMUTE_ACCENT:= "007BFF"
, OSD_POS:= { x:-1, y:-1 }
, OSD_PosEditorFunc:=""

OSD_show(txt, OSD_Accent, exclude_fullscreen:=0){
    if (exclude_fullscreen && OSD_isActiveWinFullscreen())
        return
    OSD_spawn(txt, OSD_Accent)
    SetTimer, OSD_destroy, 1000
}
OSD_spawn(txt, OSD_Accent,is_draggable:=0){
    if (StrLen(txt)>20)
        txt:= SubStr(txt, 1, 16) . "..."
    if (OSD_state = 0){
        SetFormat, integer, d
        Gui, OSD:New,,Configuration 
        Gui, Color,% sys_theme? "232323":"f2f2f2" , OSD_Accent
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border
        Gui, Margin, 30
        Gui, Font, s12 w500 c%OSD_Accent%, Segoe UI
        Gui, Add, Text, vOSD_txt w155 r1 Center, %txt%
        if(OSD_POS.x = -1 || OSD_POS.y = -1)
            OSD_setPos()
        Gui, Show, % Format("w220 h38 NoActivate x{} y{}", OSD_POS.x, OSD_POS.y)
        if(is_draggable)
            OnMessage(0x201, "onDrag")
        OSD_state:= 1
    }else{
        Gui, OSD:Default
        Gui, Font, s12 w500 c%OSD_Accent%
        GuiControl, Font, OSD_txt
        GuiControl, Text, OSD_txt, %txt% 
    }
}
OSD_destroy(){
    Gui, OSD:Default
    Gui, Destroy
    OSD_state := 0
    SetTimer, OSD_destroy, Off
}
OSD_showPosEditor(funcObj:=""){
    OSD_spawn("RClick to confirm",OSD_MAIN_ACCENT,1)
    OSD_PosEditorFunc:= funcObj
    Gui, OSD:Default
    OnMessage(0x205, "onRClick")
}
OSD_setPos(x:="",y:=""){
    SysGet, mon, Monitor, 0
    OSD_POS.x := !x? monRight/2 - 105 : x
    OSD_POS.y := !y? monBottom * 0.9 : y
    return OSD_POS
}
OSD_isActiveWinFullscreen(){
    winID := WinExist( "A" )
    if ( !winID )
        Return false
    WinGet style, Style, ahk_id %WinID%
    WinGetPos ,,,winW,winH, %winTitle%
    return !((style & 0x20800000) or WinActive("ahk_class Progman") 
    or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
}
onDrag(wParam, lParam, msg, hwnd){
    Gui, OSD:Default 
    Gui, +LastFound
    Checkhwnd := WinExist()
    if(hwnd = Checkhwnd)
        PostMessage, 0xA1, 2 
}
onRClick(wParam, lParam, msg, hwnd){
    Gui, OSD:Default 
    Gui, +LastFound
    Checkhwnd := WinExist()
    if(hwnd != Checkhwnd)
        return
    WinGetPos, xPos,yPos
    OSD_destroy() 
    if(IsFunc(OSD_PosEditorFunc))
        OSD_PosEditorFunc.Call(xPos,yPos)
} 