class Overlay {
    __New(config){
        util_log("[Overlay] Creating overlay window")
        ;create the overlay
        Gui, New, +Hwndui_hwnd +AlwaysOnTop -SysMenu +E0x20 ToolWindow, MicMute overlay
        this.hwnd:= ui_hwnd
        this.locked:=1
        this.state:= -1
        this.showOn:= config.OverlayShow ; 0 -> on-unmute, 1 -> on-mute, 2 -> always
        ; setup default icons
        this.iconObj:= {0: resources_obj.icoFile["white_unmute"].clone()
                       ,1: resources_obj.icoFile["white_mute"].clone()}
        ; check if we're using custom icons
        if(config.OverlayUseCustomIcons){
            Loop, Files, overlay_unmute.* 
            {
                this.iconObj[0].group:= 1
                this.iconObj[0].file:= A_LoopFileLongPath
                break
            }
            Loop, Files, overlay_mute.* 
            {
                this.iconObj[1].group:= 1
                this.iconObj[1].file:= A_LoopFileLongPath
                break
            }
        }
        ;add the icon to the overlay        
        Gui, Add, Picture, % "w40 h-1 Hwndico_hwnd Icon" this.iconObj[0].group, % this.iconObj[1].file
        this.iconHwnd:= ico_hwnd

        ;set the overlay color/transparency
        Gui, Color, 232323
        DetectHiddenWindows, 1
        WinSet, TransColor, 232323 210, % "ahk_id " this.hwnd
        DetectHiddenWindows, 0
        
        ;remove the title bar
        Gui -Caption 
        
        ;set overlay position
        this.pos:= config.OverlayPos
        if !(this.pos.x > -1 && this.pos.y > -1){
            SysGet, res, Monitor
            this.pos.x:= resRight - 100
            this.pos.y:= 50
        }

        ;show the overlay
        Gui, Show, % Format("NA x{} y{}",this.pos.x,this.pos.y), MicMute overlay
        this.shown:= 1

        ;set the overlay's handler functions
        this.onDragFunc:= ObjBindMethod(this, "__onDrag")
        this.onPosChangeFunc:= ObjBindMethod(this, "__onPosChange")

        ;register message handlers
        OnMessage(0x201, this.onDragFunc)
        OnMessage(0x46, this.onPosChangeFunc)

        ;register toggle hotkeys
        if(this.showOn=2){
            toggleFunc:= objBindMethod(this, "setShow")
            Try Hotkey, ^!F9, % toggleFunc, On
        }
        lockFunc:= objBindMethod(this, "toggleLock")
        Try Hotkey, ^!F10, % lockFunc, On
    }

    setState(state){
        if(state==this.state)
            return
        try{
            Gui,% this.Hwnd ":Default"
            GuiControl,, % this.iconHwnd, % Format("*w40 *h-1 *icon{} {}", this.iconObj[state].group, this.iconObj[state].file)
            this.state:= state
            if(this.showOn != 2)
                this.setShow(state==this.showOn)
        }
        return this
    }

    toggleLock(){
        Try {
            Gui,% this.Hwnd ":Default"
            if(!this.shown)
                this.setShow(1)
            if(this.locked){
                Gui, -E0x20
                DetectHiddenWindows, 1
                WinSet, TransColor, Off, % "ahk_id " this.hwnd
                DetectHiddenWindows, 0
                this.locked:= 0
            }else{
                Gui, +E0x20
                DetectHiddenWindows, 1
                WinSet, TransColor, 232323 190, % "ahk_id " this.hwnd
                DetectHiddenWindows, 0
                this.locked:= 1
            }
        }
        return this
    }

    setShow(showHide:=-1){
        Try {
            Gui,% this.Hwnd ":Default"
            if(showHide == this.shown)
                return
            _setShowHide:
            switch showHide {
                case -1: 
                    showHide:= !this.shown
                    Goto, _setShowHide
                    return
                case 0:
                    Gui, Hide
                    this.shown:= 0
                case 1:
                    Gui, Show, % Format("NA x{} y{}",this.pos.x,this.pos.y), MicMute overlay
                    this.shown:= 1
            }
        }
        return this
    }

    destroy(){
        Try {
            Gui,% this.Hwnd ":Default"
            Gui, Destroy
        }
        Hotkey, ^!F9, Off, Off UseErrorLevel
        Hotkey, ^!F10, Off, Off UseErrorLevel
        return this
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