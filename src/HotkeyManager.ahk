class HotkeyManager {
    static registeredHotkeys:= ""

    _init(){
        if(!HotkeyManager.registeredHotkeys){
            HotkeyManager.registeredHotkeys:= {}
            HotkeyManager.sharedCallback:= ObjBindMethod(HotkeyManager, "_sharedCallback")
        }
        return HotkeyManager.registeredHotkeys
    }

    register(hotkeyStr, callback, obj){
        hotkeys:= this._init()
        existingHotkey:= hotkeys[hotkeyStr]
        if(existingHotkey){
            existingHotkey.Push(new HotkeyManager.hotkeyRegistration(hotkeyStr, callback, obj))
            return existingHotkey.Length()
        }else{
            hotkeys[hotkeyStr] := [new HotkeyManager.hotkeyRegistration(hotkeyStr, callback, obj)]
            sharedCallback:= HotkeyManager.sharedCallback
            Hotkey, % hotkeyStr, % sharedCallback, On
            return 1
        }
    }

    unregister(hotkeyStr, registrationId){
        hotkeys:= this._init()
        existingHotkey:= hotkeys[hotkeyStr]
        if(existingHotkey && registrationId){
            existingHotkey.RemoveAt(registrationId)
            if(existingHotkey.Length() == 0){
                hotkeys.Delete(hotkeyStr)
                sharedCallback:= HotkeyManager.sharedCallback
                Hotkey, % hotkeyStr, % sharedCallback, Off
            }
        }
    }

    _sharedCallback(){
        registrations:= HotkeyManager.registeredHotkeys[A_ThisHotkey]
        if(!registrations)
            return
        for i, registration in registrations{
            registration.callbackFn.call()
        }
    }

    class hotkeyRegistration {
        __New(hotkeyStr, callbackFn, callbackObj){
            this.hotkeyStr:= hotkeyStr
            this.callbackFn:= callbackFn
            this.callbackObj:= callbackObj
        }
    }

}