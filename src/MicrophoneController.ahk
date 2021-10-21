Class MicrophoneController {
    static hotkeys_set, generic_state_string:= {0:"Microphone Online",1:"Microphone Muted",-1:"Microphone Unavailable"}

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_func:="", state_func:=""){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        if(mic_obj.Name = "default")
            this.microphone:= "capture"            
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_func:= feedback_func
        this.state_func:= state_func
        this.name:= mic_obj.Name
        if(this.name == "default")
            try this.name:= VA_GetDeviceName(VA_GetDevice("capture")) 
        RegExMatch(this.name, "(.+) \(.+\)", match)
        this.name:= match1? match1 : this.name
        if (StrLen(this.name)>14)
            this.name:= SubStr(this.name, 1, 12) . Chr(0x2026) ; fix overflow with ellipsis
        this.state_string:= {0:this.name . " Online",1:this.name . " Muted"}
        this.callFeedback:=0
        this.callback:= ""
    }

    ptt(){
        this.setMuteState(0)
        KeyWait, % this.ptt_key
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(1)
    }

    setMuteState(state){
        if(this.state = -1){
            util_log(Format("[MicrophoneController] Attempting Reset: {}", this.microphone))
            this.disableController()
            this.enableController()
        }
        Critical, On
        switch state {
            case this.state: return
            case -2: state:= !this.state
        }
        if(VA_SetMasterMute(state, this.microphone) = -1){ ;failing
            this.state:= -1
            this.state_func.Call(this)
            return util_log("[MicrophoneController] " this.microphone " is unavailable")
        }else{
            this.state:= state
        }
        this.callFeedback:=1
        Critical, Off
    }
        
    updateState(callback:=""){
        Critical, On
        if(callback){
            if(this.force_current_state && this.state != callback.Muted)
                VA_SetMasterMute(this.state, this.microphone)
            else
                this.state:= callback.Muted
        }else{
            this.state:= VA_GetMasterMute(this.microphone)+0
        }
        this.state_func.Call(this)
        Critical, Off
        if(this.callFeedback){
            this.feedback_func.Call(this)
            this.callFeedback:=0
        }
    }

    enableController(){
        if(this.state!=-1 && (MicrophoneController.hotkeys_set.exists(HotkeyPanel.hotkeyToKeys(this.muteHotkey,1))
           || MicrophoneController.hotkeys_set.exists(HotkeyPanel.hotkeyToKeys(this.unmuteHotkey,1))))
            Throw, Format("Found conflicting hotkeys in profile '{}'", current_profile.ProfileName)
        Try{
            if(HotkeyPanel.hotkeyToKeys(this.muteHotkey,1)="")
                Throw, "Invalid hotkeys"
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
            Throw, Format("Invalid hotkeys in profile '{}'",current_profile.ProfileName)
        }
        MicrophoneController.hotkeys_set.push(HotkeyPanel.hotkeyToKeys(this.muteHotkey,1))
        MicrophoneController.hotkeys_set.push(HotkeyPanel.hotkeyToKeys(this.unmuteHotkey,1))
        this.callback:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "updateState"), this.microphone)
        util_log(Format("[MicrophoneController] Enabled: {}", this.microphone))
    }
    
    disableController(){
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
        Try VA_ReleaseAudioEndpointCallback(VA_GetDevice(this.microphone),this.callback)
        this.callback:=""
        util_log(Format("[MicrophoneController] Disabled: {}", this.microphone))
    }

    resetHotkeySet(){
        MicrophoneController.hotkeys_set:= new StackSet
    }

}