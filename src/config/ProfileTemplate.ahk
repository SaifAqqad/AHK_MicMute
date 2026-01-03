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
        this.AutoExitApps := []

        this.OnscreenOverlay := { Enabled: 0
            , Position: [ { x: -1, y: -1 } ]
            , ShowOnState: 2
            , Theme: 0
            , Size: 48
            , ShowActivityIndicator: 1
            , ActivityIndicatorThreshold: 20
            , UseCustomIcons: 0 }

        if (IsObject(p_name_Obj)) {
            for prop, val in p_name_Obj {
                this[prop] := val
            }

            if (!this.OnscreenOverlay.HasKey("ActivityIndicatorThreshold")) {
                this.OnscreenOverlay.ActivityIndicatorThreshold := 20
                this.OnscreenOverlay.ShowActivityIndicator := 1
            }

            ; Ensure compatibility with old versions
            ; AFK timeout was stored in minutes, now in ms
            ; if it's less than 1000, it's most likely an old value
            if (A_AfterUpdate && p_name_Obj.afkTimeout < 1000)
                this.afkTimeout := p_name_Obj.afkTimeout * 60000
        }
    }
}