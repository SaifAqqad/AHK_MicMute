class VoicemeeterController extends MicrophoneController{
    static voicemeeter:= new VMR(), BUS_STRIP_REGEX:= "iO)(?<type>\w+)\[(?<index>\d)\]"

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        this.ptt_key:=""
        RegExMatch(mic_obj.Name, this.BUS_STRIP_REGEX, microphoneMatch)
        this.microphoneType:= microphoneMatch.Value("type")
        this.microphoneIndex:= microphoneMatch.Value("index")
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.shouldCallFeedback:=0
        this.microphone:= this.voicemeeter[microphoneType][microphoneIndex]

        
    }

    setMuteState(state, shouldCallFeedback:=1){

    }

    onUpdateState(){

    }

    enableController(){

    }

    disableController(){

    }

    isVoicemeeterInstalled(){
        return VMR.__getDLLPath()? 1 : 0
    }

}