Class OSD {
    static ACCENT:= {"-1":"FF572D" ; MAIN ACCENT
    ,"0":"DC3545" ; OFF ACCENT
    ,"1":"007BFF"} ; ON ACCENT

    __New(pos:="", excludeFullscreen:=0, posEditorCallback:=""){
        this.excludeFullscreen:= excludeFullscreen
        this.state:= 0
        ;get the primary monitor resolution
        SysGet, res, Monitor
        this.screenHeight:= resBottom
        this.screenWidth:= resRight
        ;get the primary monitor scaling
        this.scale:= A_ScreenDPI/96
        ;set the OSD width and height
        this.width:= Format("{:i}", 220 * this.scale)
        this.height:= Format("{:i}", 38 * this.scale)
        ;set the default pos object
        pos:= pos? pos : {x:-1,y:-1}
        ;get the final pos object
        this.pos:= this.getPosObj(pos.x, pos.y)
        ;set up bound func objects 
        this.hideFunc:= objBindMethod(this, "hide")
        this.onDragFunc:= objBindMethod(this, "__onDrag")
        this.onRClickFunc:= objBindMethod(this, "__onRClick")
        this.posEditorCallback:= posEditorCallback

        ;set the initial OSD theme
        this.setTheme(0)
        ;create the OSD window
        this.create()
    }

    ; creates the OSD window
    create(){
        util_log("[OSD] Creating OSD window")
        Gui, New, +Hwndhwnd, OSD 
        this.hwnd:= hwnd
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border 
        Gui, Margin, 30
        Gui, Color, % this.theme, % OSD.ACCENT["-1"]
        Gui, Font,% Format("s{:i} w500 c{}", 12*this.scale, OSD.ACCENT["-1"]), Segoe UI
        Gui, Add, Text,% Format("HwndtxtHwnd w{} r1 Center", this.width-60)
        this.hwndTxt:= txtHwnd
    }

    ; hides and destroys the OSD window
    destroy(){
        Try{
            this.hide()
            Gui, Destroy
        }
        this.hwnd:= ""
        this.hwndTxt:=""
    }

    ; shows the OSD window with the specified text and accent
    show(text,accent:=-1){
        ;if the window can't be shown -> return
        if(!this.canShow())
            return
        ;if the window does not exist -> create it first
        if(!this.hwnd)
            this.create()
        Gui, % this.hwnd ":Default" ;set the default window
        ;set the accent/theme colors
        if(color:=OSD.ACCENT[accent ""])
            accent:=color
        Gui, Color, % this.theme, % accent
        Gui, Font,% Format("s{:i} w500 c{}", 12*this.scale, accent)
        GuiControl, Font, % this.hwndTxt
        ;set the OSD text
        text:= this.processText(text)
        GuiControl, Text, % this.hwndTxt, %text%
        ;show the OSD
        Gui, Show, % Format("w{} h{} NA x{} y{}", this.width, this.height, this.pos.x, this.pos.y)
        ;make the OSD corners rounded
        WinGetPos,,,Width, Height, % "ahk_id " . this.hwnd
        WinSet, Region, % Format("w{} h{} 0-0 R{3:i}-{3:i}", Width, Height, 15*this.scale ), % "ahk_id " . this.hwnd
        ;set the OSD transparency
        WinSet, Transparent, 252, % "ahk_id " . this.hwnd
        return this.state:= 1
    }

    ; shows the OSD window with the specified text and accent
    ; and activates a timer to hide it
    showAndHide(text, accent:=-1, seconds:=1){
        hideFunc:= this.hideFunc
        this.show(text,accent)
        SetTimer, % hideFunc,% "-" . seconds*1000
    }

    ; shows a draggable OSD window with the specified text and accent
    showDraggable(text, accent:=-1){
        Gui,% this.hwnd ":Default"
        this.show(text, accent)
        OnMessage(0x201, this.onDragFunc)
    }

    ; shows a draggable OSD window to set the position
    showPosEditor(){
        Gui,% this.hwnd ":Default"
        this.showdraggable("RClick to confirm")
        OnMessage(0x205, this.onRClickFunc)
    }

    ; hides the OSD window
    hide(){
        if(!this.hwnd)
            return
        Gui, % this.hwnd ":Default"
        OnMessage(0x201, this.onDragFunc, 0)
        OnMessage(0x205, this.onRClickFunc, 0)
        Gui, Hide
        this.state:= 0
    }

    canShow(){
        return this.excludeFullscreen? !this.isWindowFullscreen() : 1
    }

    setTheme(theme:=""){
        if(theme != this.theme)
            this.theme:= theme? (theme=1? "272727" : theme) : "F3F3F3"
    }

    processText(text){
        if (StrLen(text)>20)
            text:= SubStr(text, 1, 18) . Chr(0x2026) ; fix overflow with ellipsis
        return text
    }

    isWindowFullscreen(win:="A"){
        winID := WinExist(win)
        if(!winID)
            return 0
        WinGet style, Style, ahk_id %WinID%
        WinGetPos ,,,winW,winH, %winTitle%
        return !((style & 0x20800000) or WinActive("ahk_class Progman") 
            or WinActive("ahk_class WorkerW") or winH < A_ScreenHeight or winW < A_ScreenWidth)
    }

    getPosObj(x:=-1,y:=-1){
        p_obj:= {}
        p_obj.x:= x=-1? Round(this.screenWidth/2 - this.width/2) : x
        p_obj.y:= y=-1? this.screenHeight * 0.9 : y
        return p_obj
    }

    __onDrag(wParam, lParam, msg, hwnd){
        if(hwnd = this.hwnd)
            PostMessage, 0xA1, 2,,, % "ahk_id " this.hwnd
    }

    __onRClick(wParam, lParam, msg, hwnd){
        if(hwnd != this.hwnd)
            return
        WinGetPos, xPos,yPos
        this.hide()
        this.pos.x:= xPos
        this.pos.y:= yPos
        if(IsFunc(this.posEditorCallback))
            this.posEditorCallback.Call(xPos,yPos)
    }
}