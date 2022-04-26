class VoicemeeterController extends MicrophoneController{
    static voicemeeter:="", BUS_STRIP_REGEX:= "iO)VMR_(?<type>\w+)\[(?<index>\d)\]", activeControllers:=[]

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        if(!this.voicemeeter)
            VoicemeeterController.voicemeeter:= new VMR().login()
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
        this.friendly_name:= this.microphone.label? this.microphone.label : this.microphoneName "[" this.microphoneIndex "]"
        this.state_string:= {0:this.friendly_name . " Online",1:this.friendly_name . " Muted",-1:this.friendly_name . " Unavailable"}
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
        this.onUpdateState()
        Critical, Off
    }

    onUpdateState(){
        Critical, On
        newState:= this.microphone.mute
        if(this.force_current_state && this.state != newState)
            this.microphone.mute := this.state
        else
            this.state:= newState
        this.state_callback.Call(this)
        if(this.shouldCallFeedback){
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

    isVoicemeeterInstalled(){
        static vmr_installed:= VMR.__getDLLPath()? 1 : 0
        return vmr_installed
    }

    _activeControllersCallback(){
        for i, ctrlr in VoicemeeterController.activeControllers {
            ctrlr.onUpdateState()
        }
    }
}