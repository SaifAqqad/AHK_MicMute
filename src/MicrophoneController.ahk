Class MicrophoneController {
    static hotkeys_set
    __New(mic_obj,PTTDelay:=0){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= PTTDelay
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
            case -1: state:= !this.state
        }
        VA_SetMasterMute(state, this.microphone)
        this.updateState()
        Critical, Off
        showFeedback(this)
    }
    

    enableHotkeys(){
        if(MicrophoneController.hotkeys_set.exists(this.muteHotkey)
        || MicrophoneController.hotkeys_set.exists(this.unmuteHotkey))
            Throw, Format("Found conflicting hotkeys in profile '{}'`nMicrophone `{}`",current_profile.ProfileName,mic.Name)
        Try{
            if (this.muteHotkey=this.unmuteHotkey){
                if(this.isPushToTalk){
                    VA_SetMasterMute(1, this.microphone)
                    this.ptt_key:= (StrSplit(this.muteHotkey, [" ","#","!","^","+","&",">","<","*","~","$","UP"], " `t")).Pop()
                    funcObj:= ObjBindMethod(this,"ptt")
                    Hotkey, % this.muteHotkey , % funcObj, On
                    SetTimer, checkActivity, Off
                }else{
                    funcObj:= ObjBindMethod(this,"setMuteState",-1)
                    Hotkey, % this.muteHotkey , % funcObj, On
                }
            }else{
                funcObj:= ObjBindMethod(this,"setMuteState",1)
                Hotkey, % this.muteHotkey, % funcObj, On
                funcObj:= ObjBindMethod(this,"setMuteState",0)
                Hotkey, % this.unmuteHotkey, % funcObj, On
            } 
        }catch{
            Throw, Format("'{}' profile needs to be set up",current_profile.ProfileName)
        }
        hotkeys_set.push(mic.MuteHotkey)
        hotkeys_set.push(mic.UnmuteHotkey)

    }
    
    disableHotkeys(){
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
    }
    
    updateState(){
        this.state:= VA_GetMasterMute(this.Microphone)
    }

    resetHotkeysSet(){
        MicrophoneController.hotkeys_set:= new StackSet
    }
}