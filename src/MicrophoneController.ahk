Class MicrophoneController {
    static genericStateString:= {0:"Microphone Online",1:"Microphone Muted",-1:"Microphone Unavailable"}
        , isUsingMultipleMicrophones:= 0

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, volume_lock:=0, feedback_callback:="", state_callback:=""){
        ; Mic config
        this.microphone:= mic_obj.Name
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.isHybridPTT:= mic_obj.HybridPTT
        this.isInverted:= mic_obj.Inverted

        ; Global config
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.volumeLock:= volume_lock

        this.state:=0
        this.ptt_key:=""
        this.shouldCallFeedback:=0
        this.va_callback:= ""
        this.microphoneIds:= Object()
        this.shortName:= mic_obj.Name
        this.callbackMic:=""
        this.level_callback:=""
        this.audioMeter:=""
        this.lvlUpdateFunc:= ObjBindMethod(this, "OnLevelUpdate")

        switch mic_obj.Name {
            case "all microphones":
                this.microphone:= Array()
                this.microphoneName:= ""

                ; add all microphones to mic array
                for _i, mic in VA_GetDeviceList("capture") {
                    this.microphone.Push(mic ":capture")
                    this.microphoneName.= StrReplace(mic, ",") . ", "
                }
                this.microphoneName:= SubStr(this.microphoneName, 1, -2)

                this.isMicrophoneArray:= 1
                this.force_current_state:= 1
                this.shortName:= "Microphones"

                ; update mic array when devices change
                this.updateMicMethod := ObjBindMethod(this, "UpdateMicArray")
                OnMessage(WM_DEVICECHANGE, this.updateMicMethod)
            case "default":
                this.microphone:= "capture"
                try this.shortName:= VA_GetDeviceName(VA_GetDevice("capture"))
                this.microphoneName:= this.shortName
                default :
                try this.shortName:= VA_GetDeviceName(VA_GetDevice(this.shortName))
                this.microphone.= ":capture"
                this.microphoneName:= this.shortName
        }

        RegExMatch(this.shortName, "(.+)\s+\(.+\)", match)
        this.shortName:= match1? match1 : this.shortName

        stateMicName:= this.shortName
        if (StrLen(stateMicName)>14)
            stateMicName:= SubStr(stateMicName, 1, 12) . Chr(0x2026) ; fix overflow with ellipsis
        this.stateString:= {0:stateMicName . " Online",1:stateMicName . " Muted",-1:stateMicName . " Unavailable"}
    }

    ptt(state:=0){
        this.setMuteState(state)
        KeyWait, % this.ptt_key
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(!state)
    }

    hybridPtt(state:= 0){
        ; toggle the mute state
        this.setMuteState(-2)
        if(this.state = !state)
            return
        KeyWait, % this.ptt_key
        if(A_TimeSinceThisHotkey < 200) ; it's a toggle
            return
        if(this.ptt_delay)
            sleep, % this.ptt_delay
        this.setMuteState(!state)
    }

    setMuteState(state, shouldCallFeedback:=1){
        ; handle unavailable microphones
        if(this.state = -1){
            util_log(Format("[MicrophoneController] Attempting Reset: {}", util_toString(this.microphoneName)))
            this.disableController()
            this.enableController()
        }
        Critical, On

        switch state {
        case this.state: return
        case -2: state:= !this.state ; toggle
            default :
        }

        if(this.isMicrophoneArray){
            failureCount:=0
            for _i, mic in this.Microphone
                failureCount+= !!this.setMuteStateVA(state, mic)

            this.state:= state
            if(failureCount = this.Microphone.Length()){
                ; all microphones failed
                Goto, s_failure
                return
            }
        }else{
            if(this.setMuteStateVA(state, this.Microphone) != 0){
                Goto, s_failure
                return
            }
            this.state:= state
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

    setMuteStateVA(state, mic){
        ; Use cached microphone id
        result := VA_SetMasterMute(state, this.getMicId(mic))
        if result in 0,1 ; success
            return 0

        ; Update the cached microphone id and retry
        result := VA_SetMasterMute(state, this.microphoneIds[mic]:= VA_GetDevice(mic))
        if result in 0,1 ; success
            return 0
        return result
    }

    setVolumeVA(vol, mic){
        ; Use cached microphone id
        result := VA_SetMasterVolume(vol,, this.getMicId(mic))
        if result in 0,1 ; success
            return 0

        ; Update the cached microphone id and retry
        result := VA_SetMasterVolume(vol,, this.microphoneIds[mic]:= VA_GetDevice(mic))
        if result in 0,1 ; success
            return 0
        return result
    }

    getMicId(micName){
        ; Prevent caching the default device (which can change)
        if(micName == "capture")
            return micName

        micId := this.microphoneIds[micName]
        if(!micId)
            micId := this.microphoneIds[micName]:= VA_GetDevice(micName)
        return micId
    }

    onUpdateState(micName:= "", callback:=""){
        Critical, On
        ; Set the microphone that will handle callbacks
        if(callback && !this.callbackMic)
            this.callbackMic:= micName

        ; Called by VA
        if(callback){
            ; Force microphone volume lock
            volume:= Format("{:d}", callback.MasterVolume*100)+0
            if(this.volumeLock > 0 && volume != this.volumeLock)
                this.setVolumeVA(this.volumeLock, micName)

            ; Force microphone mute state
            if(this.force_current_state && this.state != callback.Muted)
                this.setMuteStateVA(this.state, micName)
            else
                this.state:= callback.Muted
        } else {
            ; Called manually
            micName:= this.isMicrophoneArray? this.microphone[1] : this.microphone
            this.state:= VA_GetMasterMute(this.getMicId(micName))+0
        }

        ; Check if the current microphone is the one that should handle callbacks
        if(micName == this.callbackMic) {
            this.state_callback.Call(this)

            hotkeyId:= this.state? this.muteHotkeyId : this.unmuteHotkeyId
            ; check if the current controller is the first registered for the current hotkey
            if(this.shouldCallFeedback && hotkeyId == 1){
                this.shouldCallFeedback:=0
                this.feedback_callback.Call(this)
            }
        }
        Critical, Off
    }

    getStateString(){
        ; # of controllers the current hotkey is registered to
        local hotkeyRegistrationCount := (HotkeyManager.registeredHotkeys[this.state? this.muteHotkey : this.unmuteHotkey]).Length()

        ; if the current hotkey is bound to multiple microphones
        if(controller.isUsingMultipleMicrophones && hotkeyRegistrationCount == 1)
            ; use microphone's actual name
            return this.stateString[this.state]
        else
            return MicrophoneController.genericStateString[this.state]
    }

    enableController(){
        Try {
            if (HotkeyPanel.hotkeyToKeys(this.muteHotkey,1)="")
                Throw, "Invalid hotkeys"
            if (this.muteHotkey=this.unmuteHotkey){
                if(this.isPushToTalk){
                    this.ptt_key:= (StrSplit(this.muteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()

                    if(this.isMicrophoneArray){
                        for i, mic in this.Microphone
                            this.setMuteStateVA(!this.isInverted, mic)
                    }else{
                        this.setMuteStateVA(!this.isInverted, this.microphone)
                    }

                    pttMethod:= ObjBindMethod(this, (this.isHybridPTT? "hybridPtt": "ptt"), !!this.isInverted)
                    this.muteHotkeyId:= this.unmuteHotkeyId:= HotkeyManager.register(this.muteHotkey, pttMethod, this)

                    SetTimer, checkIsIdle, Off
                }else{
                    this.muteHotkeyId:= this.unmuteHotkeyId:= HotkeyManager.register(this.muteHotkey, ObjBindMethod(this,"setMuteState",-2), this)
                }
            }else{
                this.muteHotkeyId:= HotkeyManager.register(this.muteHotkey, ObjBindMethod(this,"setMuteState",1), this)
                this.unmuteHotkeyId:= HotkeyManager.register(this.unmuteHotkey, ObjBindMethod(this,"setMuteState",0), this)
            }
        } catch {
            Throw, Format("Invalid hotkeys in profile '{}'",current_profile.ProfileName)
        }

        ; Check if volume lock is enabled and set the microphone's initial volume
        if (this.volumeLock > 0) {
            if (this.isMicrophoneArray) {
                for i, mic in this.Microphone
                    this.setVolumeVA(this.volumeLock, mic)
            } else {
                this.setVolumeVA(this.volumeLock, this.microphone)
            }
        }

        this.enableCallback()
        util_log(Format("[MicrophoneController] Enabled: {}", util_toString(this.microphoneName)))
    }

    UpdateMicArray(wParam:="", _lParam:=""){
        if (wParam != 0x0007 || !this.isMicrophoneArray)
            return
        util_log("[MicrophoneController] Updating Microphones")
        this.microphone:= Array()
        this.microphoneIds:= Object()
        for _i, mic in VA_GetDeviceList("capture") {
            micName:= mic . ":capture"
            this.microphone.Push(micName)
            ; reapply current state on any new mic
            this.setMuteStateVA(this.state, micName)
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
            for _i, mic in this.microphone {
                this.va_callback[mic]:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", mic), mic)
            }
        }else{
            this.va_callback:= VA_CreateAudioEndpointCallback(ObjBindMethod(this, "onUpdateState", this.microphone), this.microphone)
        }

        if (this._level_callback)
            this.setLevelCallback(this._level_callback)
    }

    disableCallback(){
        if(this.isMicrophoneArray){
            for micName, cb in this.va_callback {
                try VA_ReleaseAudioEndpointCallback(this.getMicId(micName), cb)
            }
            this.va_callback:=""
        }else{
            try VA_ReleaseAudioEndpointCallback(this.getMicId(this.microphone), this.va_callback)
            this.va_callback:=""
        }
        this._level_callback := this.level_callback
        this.setLevelCallback("")
        this.microphoneIds:= Object()
        OnMessage(0x0219, this.updateMicMethod, 0)
    }

    setLevelCallback(level_callback:=""){
        if(level_callback){ ;enable
            micPeriod:=defaultMicPeriod:=30
            if(this.isMicrophoneArray){
                this.audioMeter:= Array()
                for i, mic in this.microphone {
                    currMicPeriod:=""
                    VA_GetDevicePeriod(mic, currMicPeriod)
                    micPeriod:= Min(micPeriod,currMicPeriod)
                    this.audioMeter.Push(VA_GetAudioMeter(mic))
                }
            }else{
                this.audioMeter:= VA_GetAudioMeter(this.microphone)
                VA_GetDevicePeriod(this.microphone, micPeriod)
            }
            this.level_callback:= level_callback
            lvlUpdateFunc:= this.lvlUpdateFunc
            Try SetTimer, % lvlUpdateFunc, % micPeriod ? micPeriod : defaultMicPeriod
        }else{ ;disable
            this.audioMeter:=""
            this.level_callback:=""
            lvlUpdateFunc:= this.lvlUpdateFunc
            Try SetTimer, % lvlUpdateFunc, Off
        }
    }

    onLevelUpdate(){
        peakLvl:=0
        if(this.isMicrophoneArray){
            for i, audioMeter in this.audioMeter {
                currentPeakLvl:=""
                VA_IAudioMeterInformation_GetPeakValue(audioMeter, currentPeakLvl)
                peakLvl:= Max(peakLvl, currentPeakLvl)
            }
        }else{
            VA_IAudioMeterInformation_GetPeakValue(this.audioMeter, peakLvl)
        }

        peakLvl := Min(Round(peakLvl * 200), 100)
        this.level_callback.Call(peakLvl)
    }
}