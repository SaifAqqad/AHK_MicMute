#Requires AutoHotkey v1.1.36+

class DisplayDevices {
    static _wmiPath := "winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\wmi"
        , _length_DisplayDevice := 4 + 4 + ((32 + 128 + 128 + 128) * 2)
        , _offset_DeviceString := 4 + (32 * 2)
        , _length_DeviceString := 128
        , _offset_DeviceID := 4 + 4 + ((32 + 128) * 2)
        , _length_DeviceID := 128
        , _cachedDisplays := ""
        , _primaryDisplayId := ""
        , _listeners := Array()

    _NewEnum() {
        return new DisplayDevices.DisplayEnumerator(DisplayDevices._cachedDisplays)
    }

    AddListener(funObj) {
        return DisplayDevices._listeners.Push(funObj)
    }

    RemoveListener(index) {
        try DisplayDevices._listeners[index] := ""
    }

    getById(id) {
        return DisplayDevices._cachedDisplays[id]`
    }

    getPrimary() {
        return DisplayDevices._cachedDisplays[DisplayDevices._primaryDisplayId]
    }

    getByPosition(x, y) {
        if (DisplayDevices.isRelativePosition(x, y))
            return ""

        for id, display in DisplayDevices._cachedDisplays {
            if (display.isInBounds(x, y))
                return display
        }
    }

    updateCachedDisplays() {
        Critical, On

        util_log("[DisplayDevices] Updating cached displays")

        DisplayDevices._cachedDisplays := {}

        SysGet, primaryIndex, MonitorPrimary
        SysGet, displayCount, MonitorCount

        Loop %displayCount% {
            SysGet, mPos, Monitor, %A_Index%

            VarSetCapacity(lpDisplayDevice, this._length_DisplayDevice, 0)
            Numput(this._length_DisplayDevice, lpDisplayDevice, 0, "UInt")

            VarSetCapacity(lpDevice, this._length_DeviceString * 2, 0)
            SysGet, dName, MonitorName, %A_Index%
            StrPut(dName, &lpDevice, this._length_DeviceString)

            DllCall("EnumDisplayDevices", "Ptr", &lpDevice, "UInt", 0, "Ptr", &lpDisplayDevice, "UInt", 0x00000001)
            displayName := StrGet(&lpDisplayDevice + this._offset_DeviceString, this._length_DeviceString)
            displayPath := StrGet(&lpDisplayDevice + this._offset_DeviceID, this._length_DeviceID)

            displayInstanceName := this._parseInstanceName(displayPath)
            displaySerialNum:= this._getSerialNumber(displayInstanceName)

            display:= new DisplayDevices.Display(displayName, displaySerialNum, A_Index = primaryIndex, mPosTop, mPosRight, mPosLeft, mPosBottom)

            DisplayDevices._cachedDisplays[display.Id] := display

            if (display.Primary)
                DisplayDevices._primaryDisplayId := display.Id
        }

        util_log("[DisplayDevices] Calling listeners")
        for _, listener in DisplayDevices._listeners {
            if (listener)
                listener.Call()
        }

        Critical, Off
    }

    isRelativePosition(x, y) {
        return (x > 0 && x < 1 && y > 0 && y < 1)
    }

    _parseInstanceName(path) {
        local
        pos:=1, M:= ""

        while (pos := RegExMatch(path, "(?<=#).*?(?=#)", M, pos+StrLen(M))) {
            M%A_Index% := M
        }

        return Format("DISPLAY\{}\{}", M1, M2)
    }

    _getSerialNumber(instance) {
        try displaysQuery := ComObjGet(this._wmiPath).ExecQuery("Select * from WmiMonitorID")

        for display in displaysQuery {
            if(!InStr(display.InstanceName, instance))
                Continue

            displaySerialNum := ""

            for char in display.SerialNumberID
                displaySerialNum .= chr(char)

            return displaySerialNum
        }

        ; Fallback to the UID from instance path
        return RegExMatch(instance, "UID(\d+)", serialNum) ? serialNum : ""
    }

    class Display {
        __New(name, serialNumber, primary, topPos, rightPos, leftPos, bottomPos) {
            this.Name := Trim(name)
            this.SerialNumber := Trim(serialNumber)

            this.Id := this.Name "_" this.SerialNumber
            this.Primary := primary

            this.Width := Abs(rightPos - leftPos)
            this.Height := Abs(bottomPos - topPos)

            this.Bounds := { "Left": leftPos, "Right": rightPos, "Top": topPos, "Bottom": bottomPos }
        }

        isInBounds(x, y) {
            return (x >= this.Bounds.Left && x <= this.Bounds.Right && y >= this.Bounds.Top && y <= this.Bounds.Bottom)
        }

        getRelativePosition(x, y) {
            if (DisplayDevices.isRelativePosition(x, y))
                return { "X" : x, "Y" : y }

            if (!this.isInBounds(x,y))
                return ""

            position := { "X" : x - this.Bounds.Left, "Y" : y - this.Bounds.Top, "DisplayId" : this.Id }

            position.X := Abs(position.X) / this.Width
            position.Y := Abs(position.Y) / this.Height

            return position
        }

        getAbsolutePosition(x, y) {
            if (!DisplayDevices.isRelativePosition(x, y)){
                if (this.isInBounds(x,y))
                    return { "X" : x, "Y" : y, "DisplayId" : this.Id }

                return ""
            }

            position := { "X" : x * this.Width, "Y" : y * this.Height, "DisplayId" : this.Id }

            position.X := this.Bounds.Left + position.X
            position.Y := this.Bounds.Top + position.Y

            return position
        }
    }

    class DisplayEnumerator {
        __New(displays) {
            this.displays := displays
            this.innerEnum := displays._NewEnum()
            this.index := 1
        }

        Next(ByRef key, ByRef value) {
            retValue := this.innerEnum.Next(key, value)
            key := this.index++
            return retValue
        }
    }
}

DisplayDevices_UpdateDisplays() {
    static method := ObjBindMethod(DisplayDevices, "updateCachedDisplays")
    SetTimer, %method%, -100
}

DisplayDevices.updateCachedDisplays()
OnMessage(0x007E, "DisplayDevices_UpdateDisplays", -1)