class Overlay {
    static GDI_TOKEN := 0
        , BACKGROUND_COLOR := 0x232323
        , BACKGROUND_TRANSPARENCY := 0xef000000
        , PADDING_SIZE := 5
        , DEFAULT_POSITION := { X: 0.96, Y: 0.05 }

    __New(options := "", initialState := 0) {
        this.options := options.Clone()

        this.options.IconSize := this.options.size

        ; center icon in overlay: padding=4 -> x=4, y=4
        this.options.IconPos := Overlay.PADDING_SIZE

        this.BACKGROUND_COLOR := this.options.theme ? 0xf3f3f3 : Overlay.BACKGROUND_COLOR

        ; gui actual size = iconSize + 2*padding
        this.options.size += 2 * Overlay.PADDING_SIZE

        ;set overlay position
        this._calculatePos()

        this.onDragFunc := ObjBindMethod(this, "_onDrag")
        this.onPosChangeFunc := ObjBindMethod(this, "_onPosChange")
        this.onDisplayChangeFunc := ObjBindMethod(this, "_onDisplayChange")
        this.calculatePosFunc := ObjBindMethod(this, "_calculatePos")
        this.state := initialState
        this.locked := 1

        this._setupGdip()
        this._loadIcons()
        this._createWindow()
        this._setupHotkeys()
        this.draw()
        this.setShow(this.options.showOn == 2 || this.state == this.options.showOn)
    }

    _setupHotkeys() {
        if (this.options.showOn = 2) {
            toggleFunc := objBindMethod(this, "setShow")
            Try Hotkey, ^!F9, % toggleFunc, On
        }
        lockFunc := objBindMethod(this, "toggleLock")
        Try Hotkey, ^!F10, % lockFunc, On
    }

    _onDisplayChange(wParam:="", lParam:="", msg:="", hwnd:=""){
        if (hwnd) {
            if (this.hwnd != hwnd)
                return

            util_log("[Overlay] Detected a display change, Recalculating overlay position")
        }

        cFunc := this.calculatePosFunc
        SetTimer, % cFunc, -1000
    }
    
    _calculatePos(){
        if (this.options.pos.Length() > 1) {
            ; there's multiple positions -> Apply the first available
            isPositionSet:= 0

            for i, positionConfig in this.options.pos {
                if (!this._setPosConfig(positionConfig))
                    Continue

                this.options.pos[i] := this.currentPos
                isPositionSet := 1
                Break
            }

            ; no position was set -> use the first position on primary display
            if (!isPositionSet) {
                display := DisplayDevices.getPrimary()

                this.windowPosition := display.getAbsolutePosition(this.options.pos[1].X, this.options.pos[1].Y)

                ; position is not set -> use default position
                if (!this.windowPosition)
                    this._setDefaultPos(display)
                else {
                    this.currentPos := this.options.pos[1] := display.getRelativePosition(this.windowPosition.X, this.windowPosition.Y)
                }
            }
        } else {
            positionConfig := this.options.pos[1]

            if (positionConfig.X = -1 && positionConfig.Y = -1) {
                ; position is not set -> use default position on primary display
                this._setDefaultPos()
            } else {
                ; Try to find the display using it's id or window position
                if (positionConfig.DisplayId)
                    display := DisplayDevices.getById(positionConfig.DisplayId)

                if (!display)
                    display := DisplayDevices.getByPosition(positionConfig.X, positionConfig.Y)

                ; display wasn't -> fallback to primary display
                if (!display)
                    display := DisplayDevices.getPrimary()

                this.windowPosition := display.getAbsolutePosition(positionConfig.X, positionConfig.Y)

                ; position is not set -> use default position
                if (!this.windowPosition)
                    this._setDefaultPos(display)
                else {
                    this.currentPos := this.options.pos[1] := display.getRelativePosition(this.windowPosition.X, this.windowPosition.Y)
                }
            }
        }

        if (this.hwnd && this.shown && this.windowPosition.x && this.windowPosition.y)
            WinMove, % "ahk_id " this.hwnd, , % this.windowPosition.x, % this.windowPosition.y
    }

    _setPosConfig(positionConfig){
        ; Try to find the display using it's id or window position
        if (positionConfig.DisplayId)
            display := DisplayDevices.getById(positionConfig.DisplayId)

        if (!display)
            display := DisplayDevices.getByPosition(positionConfig.X, positionConfig.Y)

        if (!display)
            return false

        this.windowPosition := display.getAbsolutePosition(positionConfig.X, positionConfig.Y)
        if (!this.windowPosition)
            return false

        this.currentPos := display.getRelativePosition(this.windowPosition.X, this.windowPosition.Y)
        return true
    }

    _setDefaultPos(display := "") {
        if (!display)
            display := DisplayDevices.getPrimary()

        this.currentPos := this.options.pos[1] := Overlay.DEFAULT_POSITION.Clone()
        this.options.pos[1].DisplayId := display.id

        this.windowPosition := display.getAbsolutePosition(this.options.pos[1].X, this.options.pos[1].X)
    }

    _createWindow() {
        util_log("[Overlay] Creating Overlay window")
        Gui, New, +Hwndui_hwnd -Caption +E0x20 +E0x80000 +AlwaysOnTop +ToolWindow -SysMenu, MicMute overlay
        this.hwnd := ui_hwnd
        OnMessage(0x201, this.onDragFunc)
        OnMessage(0x46, this.onPosChangeFunc)
        OnMessage(WM_DISPLAYCHANGE, this.onDisplayChangeFunc)
    }

    _loadIcons() {
        this.icons := { 0: "", 1: "" }
        iconColor := this.options.theme ? ICON_ID_BLACK : ICON_ID_WHITE

        this.icons[0] := resources_obj.getIcon(ICON_ID_OVERLAY + ICON_ID_UNMUTE + iconColor)
        this.icons[1] := resources_obj.getIcon(ICON_ID_OVERLAY + ICON_ID_MUTE + iconColor)

        if (this.options.useCustomIcons) {
            Loop, Files, overlay_unmute. *
            {
                this.icons[0].file := A_LoopFileLongPath
                this.icons[0].group := 1
                break
            }
            Loop, Files, overlay_mute. *
            {
                this.icons[1].file := A_LoopFileLongPath
                this.icons[1].group := 1
                break
            }
        }

        if (this.icons[0].group != 1) { ; icon is an internal resource
            this.icons[0].group := util_indexOfIconResource(A_ScriptFullPath, Abs(this.icons[0].group))
        }
        this.icons[0].bitmap := Gdip_CreateBitmapFromFile(this.icons[0].file, this.icons[0].group, this.options.IconSize)
        this.icons[0].width := Gdip_GetImageWidth(this.icons[0].bitmap)
        this.icons[0].height := Gdip_GetImageHeight(this.icons[0].bitmap)

        if (this.icons[1].group != 1) { ; icon is an internal resource
            this.icons[1].group := util_indexOfIconResource(A_ScriptFullPath, Abs(this.icons[1].group))
        }
        this.icons[1].bitmap := Gdip_CreateBitmapFromFile(this.icons[1].file, this.icons[1].group, this.options.IconSize)
        this.icons[1].width := Gdip_GetImageWidth(this.icons[1].bitmap)
        this.icons[1].height := Gdip_GetImageHeight(this.icons[1].bitmap)
    }

    _setupGdip() {
        if (Overlay.GDI_TOKEN = 0) {
            Overlay.GDI_TOKEN := Gdip_Startup()
            OnExit(Func("Gdip_Shutdown").bind(Overlay.GDI_TOKEN))
        }
        ; create a device context
        this.deviceContext := CreateCompatibleDC()
        ; create a canvas
        this.canvas := CreateDIBSection(this.options.size, this.options.size)
        ; select the canvas into the device context
        this.originalBitmap := SelectObject(this.deviceContext, this.canvas)
        this.graphics := Gdip_GraphicsFromHDC(this.deviceContext)
        ; SmoothingModeAntiAlias8x8 = 6
        Gdip_SetSmoothingMode(this.graphics, 6)
        ; InterpolationModeHighQualityBicubic = 7
        Gdip_SetInterpolationMode(this.graphics, 7)
        this.backgroundBrush := Gdip_BrushCreateSolid(this.BACKGROUND_COLOR | Overlay.BACKGROUND_TRANSPARENCY)
    }

    _updateLayeredWindow() {
        UpdateLayeredWindow(this.hwnd, this.deviceContext
            , this.windowPosition.x, this.windowPosition.y
            , this.options.size, this.options.size)
    }

    _clear() {
        Gdip_GraphicsClear(this.graphics)
    }

    _fillBackground() {
        Gdip_FillRoundedRectangle(this.graphics, this.backgroundBrush, 0, 0, this.options.size, this.options.size, 5)
    }

    _drawIcon(iconObj) {
        Gdip_DrawImage(this.graphics, iconObj.bitmap
            , this.options.IconPos, this.options.IconPos, this.options.IconSize, this.options.IconSize
            , 0, 0, iconObj.width, iconObj.height)
    }

    _onDrag(wParam, lParam, msg, hwnd) {
        if (hwnd = this.hwnd)
            PostMessage, 0xA1, 2, , , % "ahk_id " this.hwnd
    }

    _onPosChange(wParam, lParam, msg, hwnd) {
        this.changedPos := ""

        if (hwnd != this.hwnd)
            return

        WinGetPos, xPos, yPos, , , % "ahk_id " this.hwnd
        if (xPos == "" || yPos == "")
            return

        this.changedPos := { x: xPos, y: yPos }
    }

    _onPosChanged(){
        if (!this.changedPos)
            return

        util_log("[Overlay] Position changed")

        this.windowPosition.X := xPos := this.changedPos.x
        this.windowPosition.Y := yPos := this.changedPos.y

        this.changedPos := ""
        display := DisplayDevices.getByPosition(xPos, yPos)

        ; Check if we're on the same display
        if (display.Id == this.windowPosition.DisplayId){
            relativePos := display.getRelativePosition(xPos, yPos)

            this.currentPos.X := relativePos.X
            this.currentPos.Y := relativePos.Y

            config_obj.exportConfig()
            return
        }

        ; Check if there's a config for the new display
        existingConfigIndex := 0
        for i, positionConfig in this.options.pos {
            if (positionConfig.displayId = display.Id) {
                existingConfigIndex := i
                break
            }
        }

        if (existingConfigIndex) {
            this.currentPos := existingConfig := this.options.pos[existingConfigIndex]

            this.options.pos.Delete(existingConfigIndex)
            this.options.pos.InsertAt(1, existingConfig)

            relativePos := display.getRelativePosition(xPos, yPos)
            existingConfig.X := relativePos.X
            existingConfig.Y := relativePos.Y

            this.windowPosition.DisplayId := display.Id

            config_obj.exportConfig()
            return
        }

        ; No config for the new display, add a new one
        this.currentPos := display.getRelativePosition(xPos, yPos)
        this.options.pos.InsertAt(1, this.currentPos)
        this.windowPosition.DisplayId := display.Id

        config_obj.exportConfig()
    }

    draw() {
        this._clear()
        if (!this.locked)
            this._fillBackground()
        iconObj := this.icons[this.state]
        this._drawIcon(iconObj)
        this._updateLayeredWindow()
        return this
    }

    show() {
        Gui, % this.hwnd ":Default"
        Gui, Show, % Format("w{} h{} x{} y{} NA"
            , this.options.size, this.options.size
            , this.windowPosition.x, this.windowPosition.y)
        this._updateLayeredWindow()
        this.shown := 1
    }

    hide() {
        Gui, Hide
        this.shown := 0
    }

    setShow(showHide := -1) {
        Try {
            Gui, % this.Hwnd ":Default"
            if (showHide == this.shown)
                return
            _setShowHide:
            switch showHide {
                case -1:
                    showHide := !this.shown
                    Goto, _setShowHide
                case 0:
                    this.hide()
                case 1:
                    this.show()
            }
        }
        return this
    }

    setState(state) {
        if (state == this.state)
        return
        this.state := state
        this.draw()
        if (this.options.showOn != 2)
            this.setShow(state == this.options.showOn)
        return this
    }

    toggleLock() {
        Try {
            Gui, % this.Hwnd ":Default"
            this.locked := !this.locked

            if (this.locked)
                this._onPosChanged()

            Gui, % (this.locked ? "+" : "-") "E0x20"
            this.draw()

            if (!this.shown)
                this.setShow(1)
        }
        return this
    }

    destroy() {
        try {
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