class VoicemeeterController extends MicrophoneController{
    static voicemeeter:=""
    , BUS_STRIP_REGEX:= "iO)VMR_(?<type>\w+)\[(?<index>\d)\]"
    , STRIP_PROPERTIES:=
    ( Join LTrim ; ahk
        {
            "A1": 1,
            "A2": 1,
            "A3": 1,
            "A4": 1,
            "A5": 1,
            "B1": 1,
            "B2": 1,
            "B3": 1
        }
    )
    , activeControllers:=[]

    __New(mic_obj, voicemeeter_path="", ptt_delay:=0, force_current_state:=0, volume_lock:=0, feedback_callback:="", state_callback:=""){
        this.initVoicemeeter(voicemeeter_path)
        microphoneMatch:=""
        RegExMatch(mic_obj.Name, this.BUS_STRIP_REGEX, microphoneMatch)
        this.microphoneType:= microphoneMatch.type
        this.microphoneIndex:= microphoneMatch.index
        this.microphoneName:= Format("{}[{}]", microphoneMatch.type, microphoneMatch.index)
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.isHybridPTT:= mic_obj.HybridPTT
        this.prop:= "mute"
        this.isInvertedProp:= 0
        if(this.microphoneType = "Strip" && mic_obj.VMRStripProperty){
            this.prop:= mic_obj.VMRStripProperty
            this.isInvertedProp:= this.STRIP_PROPERTIES[mic_obj.VMRStripProperty] || 0
        }
        this.ptt_key:=""
        this.ptt_delay:= ptt_delay
        this.volumeLock:= volume_lock
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.shouldCallFeedback:=0
        this.microphone:= this.voicemeeter[this.microphoneType][this.microphoneIndex]
        this.shortName:= this.microphone.label? this.microphone.label : this.microphone.name
        this.stateString:= {0:this.shortName . " Online",1:this.shortName . " Muted", -1:this.shortName . " Unavailable"}
        this.voicemeeter.onUpdateParameters:= ObjBindMethod(VoicemeeterController, "_activeControllersCallback")
    }

    setMuteState(state, shouldCallFeedback:=1){
        Critical, On
        switch state {
            case this.state: return
            case -2: state:= !this.state
        }
        this.state:= this.setStateProp(state)
        this.shouldCallFeedback:= shouldCallFeedback
        Critical, Off
    }

    onUpdateState(){
        newState:= !!this.getStateProp()
        Critical, On

        ; Force microphone volume lock
        if(this.volumeLock > 0 && this.getVolume() != this.volumeLock)
            this.setVolume(this.volumeLock)

        ; Force microphone mute state
        if(this.force_current_state && this.state != newState)
            this.setStateProp(this.state)
        else
            this.state:= newState

        this.state_callback.Call(this)
        if(this.shouldCallFeedback){
            ; Check if the current controller is the first registered for the current hotkey
            hotkeyId:= this.state? this.muteHotkeyId : (this.unmuteHotkeyId? this.unmuteHotkeyId : this.muteHotkeyId)
            if (hotkeyId > 1)
                return

            this.shouldCallFeedback:=0
            this.feedback_callback.Call(this)
        }
        Critical, Off
    }

    getStateProp(){
        return this.microphone[this.prop] ^ this.isInvertedProp
    }

    setStateProp(state){
        this.microphone[this.prop]:= state ^ this.isInvertedProp
        return state
    }

    setMuteStateVA(state, _mic){
        this.setStateProp(state)
    }

    getVolume(){
        return this.microphone.getGainPercentage()
    }

    setVolume(volume){
        return this.microphone.getdB(this.microphone.setGainPercentage(volume))
    }

    setVolumeVA(volume, _mic){
        this.setVolume(volume)
    }
    
    enableCallback(){
        this.activeControllers.Push(this)
        this.id:= this.activeControllers.Length()
    }

    disableCallback(){
        this.activeControllers.RemoveAt(this.id)
    }

    isVoicemeeterInstalled(p_path:=""){
        try{
            util_log("[VoicemeeterController] Checking if Voicemeeter is installed at " . (p_path? p_path : "default path"))
            new VMR(p_path)
        }catch err{
            util_log("[VoicemeeterController] " . err.Message)
            return 0
        }
        return 1
    }

    initVoicemeeter(p_path:=""){
        if(!VoicemeeterController.voicemeeter){
            VoicemeeterController.voicemeeter:= new VMR(p_path).login()
            util_log("[VoicemeeterController] Initialized Voicemeeter at: " . VBVMR.DLL_PATH)
        }
        return VoicemeeterController.voicemeeter
    }

    _activeControllersCallback(){
        for _i, ctrlr in VoicemeeterController.activeControllers {
            ctrlr.onUpdateState()
        }
    }
}