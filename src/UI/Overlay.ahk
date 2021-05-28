class Overlay {
    __New(pos_obj){
        ;create the overlay
        Gui, New, +Hwndui_hwnd +AlwaysOnTop -SysMenu ToolWindow, MicMute overlay
        this.hwnd:= ui_hwnd

        ;add the icon to the overlay
        this.iconObj:= {0: resources_obj.icoFile["white_unmute"]
                       ,1: resources_obj.icoFile["white_mute"]}
        Gui, Add, Picture, % "w40 h-1 Hwndico_hwnd Icon" this.iconObj[0].group, % this.iconObj[1].file
        this.iconHwnd:= ico_hwnd

        ;set the overlay color/transparency
        Gui, Color, 656565
        DetectHiddenWindows, 1
        WinSet, TransColor, 656565, % "ahk_id " this.hwnd
        DetectHiddenWindows, 0
        
        ;remove the title bar
        Gui -Caption 
        
        ;set overlay position
        this.pos:= pos_obj
        if !(this.pos.x > -1 && this.pos.y > -1){
            SysGet, res, Monitor
            this.pos.x:= resRight - 100
            this.pos.y:= 50
        }

        ;set the overlay's handler functions
        this.onDragFunc:= ObjBindMethod(this, "__onDrag")
        this.onPosChangeFunc:= ObjBindMethod(this, "__onPosChange")

        ;show the overlay
        Gui, Show, % Format("NA x{} y{}",this.pos.x,this.pos.y), MicMute overlay
        this.shown:= 1

        ;register message handlers
        OnMessage(0x201, this.onDragFunc)
        OnMessage(0x46, this.onPosChangeFunc)

        ;register toggle hotkey
        this.toggleFunc:= toggleFunc:= objBindMethod(this, "toggleShow")
        Try Hotkey, ~^F10, % toggleFunc, On
    }

    setState(state){
        Gui,% this.Hwnd ":Default"
        GuiControl,, % this.iconHwnd, % Format("*w40 *h-1 *icon{} {}", this.iconObj[state].group, this.iconObj[state].file)
    }

    toggleShow(){
        Gui,% this.Hwnd ":Default"
        if(this.shown){
            Gui, Hide
            this.shown:= 0
        }else{
            Gui, Show, % Format("NA x{} y{}",this.pos.x,this.pos.y), MicMute overlay
            this.shown:= 1
        }
    }

    destroy(){
        Gui,% this.Hwnd ":Default"
        Gui, Destroy
        toggleFunc:= this.toggleFunc
        Try Hotkey, ^F10, % toggleFunc, Off
    }

    __onDrag(wParam, lParam, msg, hwnd){
        if(hwnd = this.hwnd)
            PostMessage, 0xA1, 2,,, % "ahk_id " this.hwnd
    }

    __onPosChange(wParam, lParam, msg, hwnd){
        if(hwnd != this.hwnd)
            return
        WinGetPos, xPos, yPos,,, % "ahk_id " this.hwnd
        if(xPos!=""){
            this.pos.x:= xPos
            this.pos.y:= yPos
        }
    }

    __Delete(){
        this.destroy()
    }
}