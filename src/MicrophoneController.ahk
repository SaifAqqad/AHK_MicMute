Class MicrophoneController {
    static generic_state_string:= {0:"Microphone Online",1:"Microphone Muted",-1:"Microphone Unavailable"}

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.isHybridPTT:= mic_obj.HybridPTT
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.shouldCallFeedback:=0
        this.va_callback:= ""
        switch mic_obj.Name {
            case "all microphones": 
                this.microphone:= Array()
                for i, mic in VA_GetDeviceList("capture") 
                    this.microphone.Push(mic ":capture")
                this.isMicrophoneArray:= 1
                this.force_current_state:= 1
                this.friendly_name:= "Microphones"
                this.updateMicMethod := ObjBindMethod(this, "UpdateMicArray")
                ;WM_DEVICECHANGE := 0x0219
                OnMessage(0x0219, this.updateMicMethod)
            case "default": 
                this.microphone:= "capture"
                try this.friendly_name:= VA_GetDeviceName(VA_GetDevice("capture")) 
            default : 
                this.friendly_name:= mic_obj.Name
                this.microphone.= ":capture"
        }
        this.microphoneName:= this.microphone
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

    hybridPtt(){
        ; toggle the mute state
        this.setMuteState(-2)
        if(this.state = 1) ; mic is muted
            return
        KeyWait, % this.ptt_key
        if(A_TimeSinceThisHotkey < 200) ; it's a toggle
            return
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(1)
    }

    setMuteState(state, shouldCallFeedback:=1){
        if(this.state = -1){
            util_log(Format("[MicrophoneController] Attempting Reset: {}", util_toString(this.microphoneName)))
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
        this.shouldCallFeedback:= shouldCallFeedback
        return
        s_failure:
            this.state:= -1
            this.state_callback.Call(this)
            util_log("[MicrophoneController] " util_toString(this.microphoneName) " is unavailable")
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
        if(this.shouldCallFeedback){
            hotkeyId:= this.state? this.muteHotkeyId : this.unmuteHotkeyId
            if(hotkeyId>1)
                return
            this.shouldCallFeedback:=0
            this.feedback_callback.Call(this)
        }
        Critical, Off
    }

    enableController(){
        Try{
            if(HotkeyPanel.hotkeyToKeys(this.muteHotkey,1)="")
                Throw, "Invalid hotkeys"
            if (this.muteHotkey=this.unmuteHotkey){
                if(this.isPushToTalk){
                    this.setMuteState(1,0)
                    this.ptt_key:= (StrSplit(this.muteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
                    this.muteHotkeyId:= this.unmuteHotkeyId:= HotkeyManager.register(this.muteHotkey, ObjBindMethod(this, (this.isHybridPTT? "hybridPtt": "ptt")), this)
                    SetTimer, checkIsIdle, Off
                }else{
                    this.muteHotkeyId:= this.unmuteHotkeyId:= HotkeyManager.register(this.muteHotkey, ObjBindMethod(this,"setMuteState",-2), this)
                }
            }else{
                this.muteHotkeyId:= HotkeyManager.register(this.muteHotkey, ObjBindMethod(this,"setMuteState",1), this)
                this.unmuteHotkeyId:= HotkeyManager.register(this.unmuteHotkey, ObjBindMethod(this,"setMuteState",0), this)
            }
        }catch{
            Throw, Format("Invalid hotkeys in profile '{}'",current_profile.ProfileName)
        }
        this.enableCallback()
        util_log(Format("[MicrophoneController] Enabled: {}", util_toString(this.microphoneName)))
    }

    UpdateMicArray(wParam:="", lParam:=""){
        if(wParam != 0x0007 || !this.isMicrophoneArray)
            return
        util_log("[MicrophoneController] Updating Microphones")
        this.microphone:= Array()
        for i, mic in VA_GetDeviceList("capture") {
            micName:= mic . ":capture"
            this.microphone.Push(micName)
            ; reapply current state on any new mic
            VA_SetMasterMute(this.state, micName)
        }
    }

    disableController(){
        HotkeyManager.unregister(this.muteHotkey,this.muteHotkeyId)
        HotkeyManager.unregister(this.unmuteHotkey,this.unmuteHotkeyId)
        this.disableCallback()
        util_log(Format("[MicrophoneController] Disabled: {}", util_toString(this.microphoneName)))
    }

    enableCallback(){
        if(this.isMicrophoneArray){
            this.va_callback:= Object()
            for i, mic in this.microphone {
                this.va_callback[mic]:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", mic), mic)
            }
        }else{
            this.va_callback:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", this.microphone), this.microphone)
        }
    }

    disableCallback(){
        if(this.isMicrophoneArray){
            for micName, cb in this.va_callback {
                Try VA_ReleaseAudioEndpointCallback(VA_GetDevice(micName),cb)
            }
            this.va_callback:=""
        }else{
            Try VA_ReleaseAudioEndpointCallback(VA_GetDevice(this.microphone),this.va_callback)
            this.va_callback:=""
        }
        OnMessage(0x0219, this.updateMicMethod, 0)
    }
    resetHotkeySet(){
        MicrophoneController.hotkeys_set:= new StackSet()
    }

}