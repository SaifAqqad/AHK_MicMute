class VoicemeeterController extends MicrophoneController{
    static voicemeeter:="", BUS_STRIP_REGEX:= "iO)(?<type>\w+)\[(?<index>\d)\]", activeControllers:=[]

    __New(mic_obj, ptt_delay:=0, force_current_state:=0, feedback_callback:="", state_callback:=""){
        if(!this.voicemeeter)
            VoicemeeterController.voicemeeter:= new VMR()
        RegExMatch(mic_obj.Name, this.BUS_STRIP_REGEX, microphoneMatch)
        this.microphoneName:= mic_obj.Name
        this.microphoneType:= microphoneMatch.Value("type")
        this.microphoneIndex:= microphoneMatch.Value("index")
        this.ptt_key:=""
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.force_current_state:= force_current_state
        this.feedback_callback:= feedback_callback
        this.state_callback:= state_callback
        this.shouldCallFeedback:=0
        this.microphone:= this.voicemeeter[microphoneType][microphoneIndex]
        this.friendly_name:= this.microphone.label 
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
        Critical, Off
        this.shouldCallFeedback:= shouldCallFeedback
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
        this.activeControllers.Push(this)
        this.id:= this.activeControllers.Length()
        util_log(Format("[MicrophoneController] Enabled: {}", util_toString(this.microphoneName)))
    }

    disableController(){
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
        this.activeControllers.RemoveAt(this.id)
        util_log(Format("[MicrophoneController] Disabled: {}", util_toString(this.microphoneName)))
    }

    isVoicemeeterInstalled(){
        return VMR.__getDLLPath()? 1 : 0
    }

    _activeControllersCallback(){
        for i, ctrlr in VoicemeeterController.activeControllers {
            ctrlr.onUpdateState()
        }
    }
}