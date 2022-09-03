class MicrophoneTemplate{
    __New(name, muteHotkey, unmuteHotkey, pushToTalk:=0, hybridPTT:=0, stripProperty:=""){
        this.Name:= name
        this.MuteHotkey:= muteHotkey
        this.UnmuteHotkey:= unmuteHotkey
        this.PushToTalk:= pushToTalk
        this.HybridPTT:= hybridPTT
        this.VMRStripProperty:= stripProperty
    }
}