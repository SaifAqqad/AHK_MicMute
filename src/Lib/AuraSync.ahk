#Requires AutoHotkey v1.1.36+

class AuraSync {
    static CLSID := "aura.sdk.1"

    __New(){
        this.sdk := ComObjCreate(AuraSync.CLSID)

        this.isControlled := false
        this.isReleasingControl := false
        this.devices := []

        this.releaseMethod := ObjBindMethod(this, "releaseControl")
        OnExit(this.releaseMethod)

        ; Cache devices
        for device in this.sdk.Enumerate(0)
            this.devices.Push(new AuraSync.Device(device, this))

        if (this.devices.Length() > 0)
            this.setAllDevicesColor(this.devices[1].lights[1].getColor(), 1)
    }

    takeControl(){
        while(this.isReleasingControl)
            Sleep, 100

        if(this.isControlled)
            return

        this.sdk.SwitchMode()
        this.isControlled := true
    }

    releaseControl(){
        if(!this.isControlled)
            return
        this.isReleasingControl := true
        this.sdk.ReleaseControl(0)
        this.isControlled := false
        this.isReleasingControl := false
    }

    setAllDevicesColor(color){
        for i, device in this.devices {
            for i, light in device.lights
                light.setColor(color)
            device.apply()
        }
    }

    isInstalled(){
        local auraSdk

        try {
            auraSdk := ComObjCreate(AuraSync.CLSID)
            ObjRelease(auraSdk)
        } Catch {
            return false
        }

        return true
    }

    rgbToBgr(r, g, b){
        return (b << 16) | (g << 8) | r
    }

    hexToBgr(hex){
        hex := StrReplace(hex, "#", "")

        red := Format("{:d}","0x" SubStr(hex, 1, 2))
        green := Format("{:d}","0x" SubStr(hex, 3, 2))
        blue := Format("{:d}","0x" SubStr(hex, 5, 2))

        return (blue << 16) | (green << 8) | red
    }

    bgrToRgb(color){
        red := color & 0xFF
        green := (color >> 8) & 0xFF
        blue := (color >> 16) & 0xFF

        return [red, green, blue]
    }

    bgrToHex(color){
        red := color & 0xFF
        green := (color >> 8) & 0xFF
        blue := (color >> 16) & 0xFF

        return Format("#{:02X}{:02X}{:02X}", red, green, blue)
    }

    class Device {
        __New(raw, sdk){
            this.sdk := sdk
            this.raw := raw
            this.name := raw.Name
            this.type := raw.Type
            this.width := raw.Width
            this.height := raw.Height

            ; Cache device's lights
            this.lights:= []
            for light in raw.Lights
                this.lights.Push(new AuraSync.Light(light, sdk))
        }

        apply(){
            if (!this.sdk.isControlled)
                this.sdk.takeControl()
            this.raw.Apply()
        }
    }

    class Light {
        __New(raw, sdk){
            this.sdk := sdk
            this.raw := raw
            this.Name := raw.Name
        }

        setColor(color){
            if (!this.sdk.isControlled)
                this.sdk.takeControl()
            this.raw.Color := color
        }

        getColor(){
            if(!this.sdk.isControlled)
                this.sdk.takeControl()
            return this.raw.Color
        }
    }
}