Class MicrophoneController {
    static hotkeys_set, generic_state_string:= {0:"Microphone Online",1:"Microphone Muted"}

    __New(mic_obj, ptt_delay:=0, feedback_func:=""){
        this.state:=0
        this.ptt_key:=""
        this.microphone:= mic_obj.Name
        if(mic_obj.Name = "default")
            this.microphone:= "capture"
        this.muteHotkey:= mic_obj.MuteHotkey
        this.unmuteHotkey:= mic_obj.UnmuteHotkey
        this.isPushToTalk:= mic_obj.PushToTalk
        this.ptt_delay:= ptt_delay
        this.feedback_func:= feedback_func
        _n:= this.microphone == "capture"? VA_GetDeviceName(VA_GetDevice("capture")) : this.microphone
        RegExMatch(_n, "(.+) \(.+\)", match)
        this.name:= match1? match1 : _n
        if (StrLen(this.name)>14)
            this.name:= SubStr(this.name, 1, 12) . Chr(0x2026) ; fix overflow with ellipsis
        this.state_string:= {0:this.name . " Online",1:this.name . " Muted"}
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
        if(IsFunc(this.feedback_func))
            this.feedback_func.Call(this)
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
                    SetTimer, checkIsIdle, Off
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
            Throw, Format("Invalid hotkeys in profile '{}'",current_profile.ProfileName)
        }
        hotkeys_set.push(mic.MuteHotkey)
        hotkeys_set.push(mic.UnmuteHotkey)
    }
    
    disableHotkeys(){
        ;@Ahk2Exe-IgnoreBegin
        OutputDebug, % Format("Disabling Hotkeys: {} | {}`n",this.muteHotkey,this.unmuteHotkey)
        ;@Ahk2Exe-IgnoreEnd
        Hotkey, % this.muteHotkey, Off, Off
        Hotkey, % this.unmuteHotkey, Off, Off
    }
    
    updateState(){
        this.state:= VA_GetMasterMute(this.microphone)
    }

    resetHotkeysSet(){
        MicrophoneController.hotkeys_set:= new StackSet
    }
}