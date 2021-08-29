Class MicrophoneController {
    static hotkeys_set, generic_state_string:= {0:"Microphone Online",1:"Microphone Muted",-1:"Microphone Unavailable"}

    __New(mic_obj, ptt_delay:=0, feedback_func:=""){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        if(mic_obj.Name = "default")
            this.microphone:= "capture"            
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.feedback_func:= feedback_func
        _n:= this.microphone == "capture"? VA_GetDeviceName(VA_GetDevice("capture")) : this.microphone
        RegExMatch(_n, "(.+) \(.+\)", match)
        this.name:= match1? match1 : _n
        if (StrLen(this.name)>14)
            this.name:= SubStr(this.name, 1, 12) . Chr(0x2026) ; fix overflow with ellipsis
        this.state_string:= {0:this.name . " Online",1:this.name . " Muted"}
    }

    ptt(){
        this.setMuteState(0)
        KeyWait, % this.ptt_key
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(1)
    }

    setMuteState(state){
        Critical, On
        switch state {
            case this.state: return
            case -2: state:= !this.state
        }
        if(VA_SetMasterMute(state, this.microphone) = -1) ;failing
            return util_log("[MicrophoneController] " this.microphone " is unavailable")
        this.updateState()
        Critical, Off
        if(IsFunc(this.feedback_func))
            this.feedback_func.Call(this)
    }
    

    enableHotkeys(){
        if(this.hotkeys_set.exists(HotkeyPanel.hotkeyToKeys(this.muteHotkey,1))
           || this.hotkeys_set.exists(HotkeyPanel.hotkeyToKeys(this.unmuteHotkey,1)))
            Throw, Format("[MicrophoneController] Found conflicting hotkeys in profile '{}'", current_profile.ProfileName)
        Try{
            if (this.muteHotkey=this.unmuteHotkey){
                if(this.isPushToTalk){
                    VA_SetMasterMute(1, this.microphone)
                    this.ptt_key:= (StrSplit(this.muteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
                    funcObj:= ObjBindMethod(this,"ptt")
                    Hotkey, % this.muteHotkey , % funcObj, On
                    SetTimer, checkIsIdle, Off
                }else{
                    funcObj:= ObjBindMethod(this,"setMuteState",-2)
                    Hotkey, % this.muteHotkey , % funcObj, On
                }
            }else{
                funcObj:= ObjBindMethod(this,"setMuteState",1)
                Hotkey, % this.muteHotkey, % funcObj, On
                funcObj:= ObjBindMethod(this,"setMuteState",0)
                Hotkey, % this.unmuteHotkey, % funcObj, On
            } 
        }catch{
            Throw, Format("[MicrophoneController] Invalid hotkeys in profile '{}'",current_profile.ProfileName)
        }
        this.hotkeys_set.push(HotkeyPanel.hotkeyToKeys(this.MuteHotkey,1))
        this.hotkeys_set.push(HotkeyPanel.hotkeyToKeys(this.unmuteHotkey,1))
        util_log(Format("[MicrophoneController] Enabled: {} | {} | {}", this.microphone,this.muteHotkey,this.unmuteHotkey))
    }
    
    disableHotkeys(){
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
        util_log(Format("[MicrophoneController] Disabled: {} | {} | {}", this.microphone,this.muteHotkey,this.unmuteHotkey))
    }
    
    updateState(){
        this.state:= VA_GetMasterMute(this.microphone)
    }

    resetHotkeysSet(){
        MicrophoneController.hotkeys_set:= new StackSet
    }
}