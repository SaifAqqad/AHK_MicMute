class ProfileTemplate {
    __New(p_name_Obj) {
        this.ProfileName := p_name_Obj
        this.Microphone := Array(new MicrophoneTemplate("Default", "", ""))
        this.MicrophoneActions := Array()
        this.MicrophoneVolumeLock := 0

        this.SoundFeedback := 0
        this.SoundFeedbackDevice := "Default"
        this.SoundFeedbackUseCustomSounds := 0

        this.OnscreenFeedback := 0
        this.ExcludeFullscreen := 0
        this.OSDPos := { x: -1, y: -1 }

        this.afkTimeout := 0
        this.PTTDelay := 100

        this.LinkedApp := ""
        this.ForegroundAppsOnly := 1

        this.OnscreenOverlay := { Enabled: 0
            , Position: [ { x: -1, y: -1 } ]
            , ShowOnState: 2
            , Theme: 0
            , Size: 48
            , UseCustomIcons: 0 }

        if (IsObject(p_name_Obj)) {
            ; Ensure compatibility with old versions
            onMuteOnly := p_name_Obj.Delete("OverlayOnMuteOnly")
            if (onMuteOnly)
                this.OnscreenOverlay.ShowOnState := onMuteOnly

            ; Ensure compatibility with old versions
            if (!IsObject(p_name_Obj.OnscreenOverlay)){
                this.OnscreenOverlay.Enabled := p_name_Obj.Delete("OnscreenOverlay")
                this.OnscreenOverlay.Position[1] := p_name_Obj.Delete("OverlayPos")
                this.OnscreenOverlay.ShowOnState := p_name_Obj.Delete("OverlayShow")
                this.OnscreenOverlay.Theme := p_name_Obj.Delete("OverlayTheme")
                this.OnscreenOverlay.Size := p_name_Obj.Delete("OverlaySize")
                this.OnscreenOverlay.UseCustomIcons := p_name_Obj.Delete("OverlayUseCustomIcons")
            }

            for prop, val in p_name_Obj {
                this[prop] := val
            }

            ; Ensure compatibility with old versions
            if (!IsObject(this.Microphone)) {
                this.Microphone := Array(new MicrophoneTemplate(this.Delete("Microphone")
                    , this.Delete("MuteHotkey")
                    , this.Delete("UnmuteHotkey")
                    , this.Delete("PushToTalk")))
            }
        }
    }
}