class Overlay{
    static GDI_TOKEN:=0
    , BACKGROUND_COLOR:= 0x232323
    , BACKGROUND_TRANSPARENCY:= 0xef000000
    , PADDING_SIZE:= 4

    __New(options:=""){
        this.options:= options.Clone()
        this.options.IconSize:= this.options.size
        ; center icon in overlay: padding=4 -> x=4, y=4
        this.options.IconPos:= Overlay.PADDING_SIZE
        ; gui actual size = iconSize + 2*padding
        this.options.size+= 2*Overlay.PADDING_SIZE
        ;set overlay position
        if(this.options.pos.x = -1 || this.options.pos.y = -1){
            SysGet, res, Monitor
            this.options.pos.x:= resRight - 100
            this.options.pos.y:= 50
        }

        this.BACKGROUND_COLOR:= this.options.theme? 0xf3f3f3: Overlay.BACKGROUND_COLOR

        this.onDragFunc:= ObjBindMethod(this, "_onDrag")
        this.onPosChangeFunc:= ObjBindMethod(this, "_onPosChange")
        this.state := 0
        this.locked:= 1

        this._setupGdip()
        this._loadIcons()
        this._createWindow()
        this._setupHotkeys()
        this.draw()
        this.setShow(1)
    }

    _setupHotkeys(){
        if(this.options.showOn = 2){
            toggleFunc:= objBindMethod(this, "setShow")
            Try Hotkey, ^!F9, % toggleFunc, On
        }
        lockFunc:= objBindMethod(this, "toggleLock")
        Try Hotkey, ^!F10, % lockFunc, On
    }

    _createWindow(){
        Gui, New, +Hwndui_hwnd -Caption +E0x20 +E0x80000 +AlwaysOnTop +ToolWindow -SysMenu, MicMute overlay
        this.hwnd:= ui_hwnd
        OnMessage(0x201, this.onDragFunc)
        OnMessage(0x46, this.onPosChangeFunc)
    }

    _loadIcons(){
        this.icons:= {0:"", 1:""}
        iconColor:= this.options.theme? ICON_ID_BLACK : ICON_ID_WHITE 
        
        this.icons[0]:= resources_obj.getIcon(ICON_ID_OVERLAY + ICON_ID_UNMUTE + iconColor)
        this.icons[1]:= resources_obj.getIcon(ICON_ID_OVERLAY + ICON_ID_MUTE + iconColor)
        
        if(this.options.useCustomIcons){
            Loop, Files, overlay_unmute.*
            {
                this.icons[0].file:= A_LoopFileLongPath
                this.icons[0].group:= 1
                break
            }
            Loop, Files, overlay_mute.* 
            {
                this.icons[1].file:= A_LoopFileLongPath
                this.icons[1].group:= 1
                break
            }
        }

        if(this.icons[0].group!=1){ ; icon is an internal resource
            this.icons[0].group:= util_indexOfIconResource(A_ScriptFullPath, Abs(this.icons[0].group))
        }
        this.icons[0].bitmap:= Gdip_CreateBitmapFromFile(this.icons[0].file, this.icons[0].group, this.options.IconSize)
        this.icons[0].width:= Gdip_GetImageWidth(this.icons[0].bitmap)
        this.icons[0].height:= Gdip_GetImageHeight(this.icons[0].bitmap)

        if(this.icons[1].group!=1){ ; icon is an internal resource
            this.icons[1].group:= util_indexOfIconResource(A_ScriptFullPath, Abs(this.icons[1].group))
        }
        this.icons[1].bitmap:= Gdip_CreateBitmapFromFile(this.icons[1].file, this.icons[1].group, this.options.IconSize)
        this.icons[1].width:= Gdip_GetImageWidth(this.icons[1].bitmap)
        this.icons[1].height:= Gdip_GetImageHeight(this.icons[1].bitmap)
    }

    _setupGdip(){
        if(Overlay.GDI_TOKEN = 0){
            Overlay.GDI_TOKEN := Gdip_Startup()
            OnExit(Func("Gdip_Shutdown").bind(Overlay.GDI_TOKEN))
        }
        ; create a device context
        this.deviceContext:= CreateCompatibleDC()
        ; create a canvas
        this.canvas:= CreateDIBSection(this.options.size, this.options.size)
        ; select the canvas into the device context
        this.originalBitmap:= SelectObject(this.deviceContext, this.canvas)
        this.graphics:= Gdip_GraphicsFromHDC(this.deviceContext)
        ; SmoothingModeAntiAlias8x8 = 6
        Gdip_SetSmoothingMode(this.graphics, 6)
        ; InterpolationModeHighQualityBicubic = 7
        Gdip_SetInterpolationMode(this.graphics, 7)
        this.backgroundBrush:= Gdip_BrushCreateSolid(this.BACKGROUND_COLOR | Overlay.BACKGROUND_TRANSPARENCY)
    }

    _updateLayeredWindow(){
        UpdateLayeredWindow(this.hwnd, this.deviceContext
            , this.options.pos.x, this.options.pos.y
            , this.options.size, this.options.size)
    }

    _clear(){
        Gdip_GraphicsClear(this.graphics)
    }

    _fillBackground(){
        Gdip_FillRoundedRectangle(this.graphics, this.backgroundBrush, 0, 0, this.options.size, this.options.size, 5)
    }

    _drawIcon(iconObj){
        Gdip_DrawImage(this.graphics, iconObj.bitmap
                    , this.options.IconPos, this.options.IconPos, this.options.IconSize, this.options.IconSize
                    , 0, 0, iconObj.width, iconObj.height)
    }

    _onDrag(wParam, lParam, msg, hwnd){
        if(hwnd = this.hwnd)
            PostMessage, 0xA1, 2,,, % "ahk_id " this.hwnd
    }

    _onPosChange(wParam, lParam, msg, hwnd){
        if(hwnd != this.hwnd)
            return
        WinGetPos, xPos, yPos,,, % "ahk_id " this.hwnd
        if(xPos!=""){
            this.options.pos.x:= xPos
            this.options.pos.y:= yPos
        }
    }

    draw(){
        this._clear()
        if(!this.locked)
            this._fillBackground()
        iconObj:= this.icons[this.state]
        this._drawIcon(iconObj)
        this._updateLayeredWindow()
        return this
    }

    show(){
        Gui, % this.hwnd ":Default"
        Gui, Show, % Format("w{} h{} x{} y{} NA"
            , this.options.size, this.options.size
            , this.options.pos.x, this.options.pos.y)
        this._updateLayeredWindow()
        this.shown:= 1
    }

    hide(){
        Gui, Hide
        this.shown:= 0
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
                case 0:
                    this.hide()
                case 1:
                    this.show()
            }
        }
        return this
    }

    setState(state){
        if(state==this.state)
            return
        this.state:= state
        this.draw()
        if(this.options.showOn != 2)
            this.setShow(state==this.options.showOn)
        return this
    }

    toggleLock(){
        Try {
            Gui, % this.Hwnd ":Default"
            this.locked:= !this.locked
            Gui, % (this.locked? "+":"-") "E0x20"
            this.draw()
            if(!this.shown)
                this.setShow(1)
        }
        return this
    }

    destroy(){
        try{
            Gui, % this.hwnd ":Default"
            Gui, Destroy
            OnMessage(0x201, this.onDragFunc, 0)
            OnMessage(0x46, this.onPosChangeFunc, 0)
            Gdip_DeleteBrush(this.backgroundBrush)
            DeleteObject(this.canvas)
            DeleteDC(this.deviceContext)
            Gdip_DeleteGraphics(this.graphics)
            for i, iconObj in this.icons 
                Gdip_DisposeImage(iconObj.bitmap)
        }
    }
}