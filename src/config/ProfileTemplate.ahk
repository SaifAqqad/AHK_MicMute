class ProfileTemplate{
    __New(p_name_Obj){
        this.ProfileName:= p_name_Obj
        this.Microphone:= [{Name:"Default"
        ,MuteHotkey:""
        ,UnmuteHotkey:""
        ,PushToTalk:0}]
        this.SoundFeedback:=0
        this.SoundFeedbackDevice:="Default"
        this.SoundFeedbackUseCustomSounds:=0
        this.OnscreenFeedback:=0
        this.OnscreenOverlay:=0
        this.ExcludeFullscreen:=0
        this.UpdateWithSystem:=1
        this.afkTimeout:=0
        this.LinkedApp:=""
        this.PTTDelay:=100
        this.OSDPos:={x:-1,y:-1}
        this.OverlayPos:={x:-1,y:-1}
        this.OverlayShow:=2
        this.OverlayUseCustomIcons:=0
        if(IsObject(p_name_Obj)){
            onMuteOnly:= p_name_Obj.Delete("OverlayOnMuteOnly")
            if(onMuteOnly)
                this.OverlayShow := onMuteOnly
            for prop, val in p_name_Obj{
                this[prop]:= val
            }
            if(!IsObject(this.Microphone)){
                this.Microphone:= Array({Name: this.Delete("Microphone")
                ,MuteHotkey: this.Delete("MuteHotkey")
                ,UnmuteHotkey: this.Delete("UnmuteHotkey")
                ,PushToTalk: this.Delete("PushToTalk")})
            }
        }
    }
}