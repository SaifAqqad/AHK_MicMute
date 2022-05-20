class VoicemeeterController extends MicrophoneController{
    static voicemeeter:="", BUS_STRIP_REGEX:= "iO)VMR_(?<type>\w+)\[(?<index>\d)\]", activeControllers:=[]

    __New(mic_obj, voicemeeter_path="", ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        this.initVoicemeeter(voicemeeter_path)
        microphoneMatch:=""
        RegExMatch(mic_obj.Name, this.BUS_STRIP_REGEX, microphoneMatch)
        this.microphoneType:= microphoneMatch.type
        this.microphoneIndex:= microphoneMatch.index
        this.microphoneName:= Format("{}[{}]", microphoneMatch.type, microphoneMatch.index)
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_key:=""
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.shouldCallFeedback:=0
        this.microphone:= this.voicemeeter[this.microphoneType][this.microphoneIndex]
        this.friendly_name:= this.microphone.label? this.microphone.label : this.microphone.name
        this.state_string:= {0:this.friendly_name . " Online",1:this.friendly_name . " Muted", -1:this.friendly_name . " Unavailable"}
        this.voicemeeter.onUpdateParameters:= ObjBindMethod(VoicemeeterController, "_activeControllersCallback")
    }

    setMuteState(state, shouldCallFeedback:=1){
        Critical, On
        switch state {
            case this.state: return
            case -2: state:= !this.state
        }
        this.state:= this.microphone.mute:= state
        this.shouldCallFeedback:= shouldCallFeedback
        Critical, Off
    }

    onUpdateState(){
        newState:= !!this.microphone.mute
        Critical, On
        if(this.force_current_state && this.state != newState)
            this.microphone.mute := this.state
        else
            this.state:= newState
        this.state_callback.Call(this)
        if(this.shouldCallFeedback){
            hotkeyId:= this.state? this.muteHotkeyId : (this.unmuteHotkeyId? this.unmuteHotkeyId : this.muteHotkeyId)
            if(hotkeyId>1)
                return
            this.shouldCallFeedback:=0
            this.feedback_callback.Call(this)
        }
        Critical, Off
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
            new VMR(p_path)
        }catch{
            return 0
        }
        return 1
    }

    initVoicemeeter(p_path:=""){
        if(!VoicemeeterController.voicemeeter)
            VoicemeeterController.voicemeeter:= new VMR(p_path).login()
        return VoicemeeterController.voicemeeter
    }

    _activeControllersCallback(){
        for i, ctrlr in VoicemeeterController.activeControllers {
            ctrlr.onUpdateState()
        }
    }
}