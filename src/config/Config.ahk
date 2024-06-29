class Config {
    DefaultProfile := ""
    Profiles := Array()
    MuteOnStartup := 0
    SwitchProfileOSD := 1
    PreferTheme := -1
    AllowUpdateChecker := -1
    ForceMicrophoneState := 0
    VoicemeeterPath := ""
    VoicemeeterIntegration := 0
    NotifyForAdminApps := 1
    Version := ""

    __New(p_DefaultProfile := "") {
        ; Set Json options
        JSON.EmptyObjectsAsArrays := 1

        if (!FileExist(A_ScriptDir "\config.json") || util_IsFileEmpty(A_ScriptDir "\config.json")) {
            isFirstLaunch := 1
            this.DefaultProfile := this.createProfile("Default").ProfileName
            this.exportConfig()
        } else {
            isFirstLaunch := 0
            Try this.importConfig()
            catch err {
                MsgBox, 65, MicMute, % "Importing the config file failed`nError: "
                    . (IsObject(err) ? err.Message : err) . "`nClick OK to reset configuration"
                IfMsgBox, Cancel
                    return
                isFirstLaunch := 1
                this.DefaultProfile := this.createProfile("Default").ProfileName
                this.exportConfig()
            }
        }

        if (p_DefaultProfile)
            this.DefaultProfile := p_DefaultProfile
    }

    importConfig() {
        util_log("[Config] Importing config.json")
        jsonFile := FileOpen(A_ScriptDir "\config.json", "R")
        jsonStr := jsonFile.Read()
        jsonFile.Close()
        jsonObj := JSON.Load(jsonStr)

        this.Version := jsonObj.Version
        if (!this.Version || VerCompare(A_Version, this.Version) > 0) {
            A_PreviousVersion := this.Version
            A_AfterUpdate := true
        }

        ; Apply json object props over config object props
        for prop, val in jsonObj {
            if (prop = "profiles")
                for i, profile in val
                    this.Profiles.Push(new ProfileTemplate(profile))
            else
                this[prop] := jsonObj[prop]
        }

        ; Update the config version
        this.Version := A_Version
    }

    exportConfig() {
        util_log("[Config] exporting the config object")
        jsonStr := JSON.Dump(this, 4)

        jsonFile := FileOpen(A_ScriptDir "\config.json", "w")
        jsonFile.Write(jsonStr)
        jsonFile.Close()

        FileGetTime, modif_time, config.json
        last_modif_time := modif_time
    }

    getProfile(p_name := "") {
        if (!p_name)
            p_name := this.DefaultProfile

        for i, profile in this.Profiles {
            if (profile.ProfileName == p_name)
                return profile
        }

        Throw, Format("Profile '{}' not found", p_name)
    }

    deleteProfile(p_name) {
        if (p_name = this.DefaultProfile) {
            Throw, "Default profile can't be deleted"
            return
        }

        profiles := Array()
        for i, p in this.Profiles
            if (p.ProfileName != p_name)
                profiles.Push(p)

        this.Profiles := profiles
        this.exportConfig()
    }

    createProfile(p_Name) {
        this.Profiles.Push(new ProfileTemplate(p_Name))
        this.exportConfig()
        return this.Profiles[this.Profiles.Length()]
    }
}