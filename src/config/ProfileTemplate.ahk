class ProfileTemplate{
    __New(p_name_Obj){
        this.ProfileName:= p_name_Obj
        this.Microphone:= [{Name:"capture"
        ,MuteHotkey:""
        ,UnmuteHotkey:""
        ,PushToTalk:0}]
        this.SoundFeedback:=0
        this.OnscreenFeedback:=0
        this.ExcludeFullscreen:=0
        this.UpdateWithSystem:=1
        this.afkTimeout:=0
        this.LinkedApp:=""
        this.PTTDelay:=100
        this.OSDPos:={x:-1,y:-1}
        if(IsObject(p_name_Obj)){
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
    getMicObj(p_mic){
        for i,mic in this.Microphone {
            if(mic.Name == p_mic)
                return mic
        }
    }
}