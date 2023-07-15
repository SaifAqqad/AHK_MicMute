class MicrophoneTemplate{
    __New(name, muteHotkey, unmuteHotkey, pushToTalk:=0, hybridPTT:=0, inverted:=0, stripProperty:=""){
        this.Name:= name
        this.MuteHotkey:= muteHotkey
        this.UnmuteHotkey:= unmuteHotkey
        this.PushToTalk:= pushToTalk
        this.Inverted:= inverted
        this.HybridPTT:= hybridPTT
        this.VMRStripProperty:= stripProperty
    }
}