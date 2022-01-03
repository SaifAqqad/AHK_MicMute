Class MicrophoneController {
    static hotkeys_set, generic_state_string:= {0:"Microphone Online",1:"Microphone Muted",-1:"Microphone Unavailable"}

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.callFeedback:=0
        this.va_callback:= ""
        switch mic_obj.Name {
            case "all microphones": 
                this.microphone:= VA_GetDeviceList("capture")
                this.isMicrophoneArray:= 1
                this.force_current_state:= 1
                this.friendly_name:= "Microphones"
            case "default": 
                this.microphone:= "capture"
                try this.friendly_name:= VA_GetDeviceName(VA_GetDevice("capture")) 
            default : 
                this.friendly_name:= mic_obj.Name
        }
        RegExMatch(this.friendly_name, "(.+) \(.+\)", match)
        this.friendly_name:= match1? match1 : this.friendly_name
        if (StrLen(this.friendly_name)>14)
            this.friendly_name:= SubStr(this.friendly_name, 1, 12) . Chr(0x2026) ; fix overflow with ellipsis
        this.state_string:= {0:this.friendly_name . " Online",1:this.friendly_name . " Muted",-1:this.friendly_name . " Unavailable"}
    }

    ptt(){
        this.setMuteState(0)
        KeyWait, % this.ptt_key
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(1)
    }

    setMuteState(state, callFeedback:=1){
        if(this.state = -1){
            util_log(Format("[MicrophoneController] Attempting Reset: {}", util_toString(this.microphone)))
            this.disableController()
            this.enableController()
        }
        Critical, On
        switch state {
            case this.state: return
            case -2: state:= !this.state
        }
        if(this.isMicrophoneArray){
            numFails:=0
            for i, mic in this.Microphone 
                numFails+= !!VA_SetMasterMute(state, mic)
            if(numFails = this.Microphone.Length()){
                Goto, s_failure
                return
            }else{
                this.state:= state
            }
        }else{
            if(VA_SetMasterMute(state, this.Microphone) = -1){ ;failing
                Goto, s_failure
                return
            }else{
                this.state:= state
            }
        }
        Critical, Off
        this.callFeedback:= callFeedback
        return
        s_failure:
            this.state:= -1
            this.state_callback.Call(this)
            util_log("[MicrophoneController] " util_toString(this.microphone) " is unavailable")
        return
    }

    onUpdateState(micName:= "", callback:=""){
        Critical, On
        if(callback){
            if(this.force_current_state && this.state != callback.Muted)
                VA_SetMasterMute(this.state, micName)
            else
                this.state:= callback.Muted
        }else{
            micName:= this.isMicrophoneArray? this.microphone[1] : this.microphone
            this.state:= VA_GetMasterMute(micName)+0
        }
        this.state_callback.Call(this)
        if(this.callFeedback){
            this.callFeedback:=0
            this.feedback_callback.Call(this)
        }
        Critical, Off
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
                    this.setMuteState(1,0)
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
        if(this.isMicrophoneArray){
            this.va_callback:= Object()
            for i, mic in this.microphone {
                this.va_callback[mic]:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", mic), mic)
            }
        }else{
            this.va_callback:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", this.microphone), this.microphone)
        }
        util_log(Format("[MicrophoneController] Enabled: {}", util_toString(this.microphone)))
    }

    disableController(){
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
        if(this.isMicrophoneArray){
            for micName, cb in this.va_callback {
                Try VA_ReleaseAudioEndpointCallback(VA_GetDevice(micName),cb)
            }
            this.va_callback:=""
        }else{
            Try VA_ReleaseAudioEndpointCallback(VA_GetDevice(this.microphone),this.va_callback)
            this.va_callback:=""
        }
        util_log(Format("[MicrophoneController] Disabled: {}", util_toString(this.microphone)))
    }

    resetHotkeySet(){
        MicrophoneController.hotkeys_set:= new StackSet()
    }

}