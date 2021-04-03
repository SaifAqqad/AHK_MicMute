class Config {
    DefaultProfile:=""
    Profiles:=Array()
    MuteOnStartup:=0
    UseCustomSounds:=0
    SwitchProfileOSD:=1
    PreferTheme:=-1

    __New(p_DefaultProfile:=""){
        this["$schema"]:= "https://raw.githubusercontent.com/SaifAqqad/AHK_MicMute/master/src/config_schema.json"
        if(!FileExist("config.json") || util_IsFileEmpty("config.json")){
            if(FileExist("config.ini")){
                isFirstLaunch:=0
                this.importIniConfig()
            }else{
                isFirstLaunch:=1
                this.DefaultProfile:= this.createProfile("Default").ProfileName
                this.exportConfig()
            }
        }else{
            isFirstLaunch:=0
            this.importConfig()
        }
        if(p_DefaultProfile)
            this.DefaultProfile := p_DefaultProfile
    }

    importConfig(){
        jsonFile:=FileOpen("config.json", "R")
        jsonStr:=jsonFile.Read()
        jsonFile.Close()
        jsonObj:= JSON.Load(jsonStr)
        for prop,val in jsonObj { ; apply json object props over config object props
            if(prop = "profiles")
                for i, profile in val ; to ensure new props are added to existing profiles
                    this.Profiles.Push(new ProfileTemplate(profile))
            else 
                this[prop] := jsonObj[prop] 
        }
    }

    importIniConfig(){
        iniProfile:= { "afkTimeout":0
                    , "ExcludeFullscreen":0
                    , "Microphone":"capture"
                    , "MuteHotkey":""
                    , "OnscreenFeedback":0
                    , "ProfileName":"Default"
                    , "PushToTalk":0
                    , "SoundFeedback":0
                    , "UnmuteHotkey":""
                    , "UpdateWithSystem":1}
        for key in iniProfile {
            IniRead, iniVal, config.ini, settings, %key%
            if(iniVal = "ERROR")
                continue
            if val is number
                iniVal+=0
            iniProfile[key]:= iniVal
        }
        dfProfile:= this.createProfile(iniProfile)
        this.DefaultProfile:= dfProfile.ProfileName
        this.exportConfig()
        FileDelete, config.ini
    }

    exportConfig(){
        jsonStr:=JSON.Dump(this,,4)
        jsonFile:=FileOpen("config.json", "w")
        jsonFile.Write(jsonStr)
        jsonFile.Close()
    }

    getProfile(p_name:=""){
        if(!p_name)
            p_name:= this.DefaultProfile
        for i, profile in this.Profiles {
            if(profile.ProfileName == p_name)
                return profile
        }
        Throw, Exception(Format("Profile '{}' not found", p_name))
    }

    deleteProfile(p_name){
        if(p_name = this.DefaultProfile){
            Throw, Exception("Default profile can't be deleted")
            return
        }
        profArr:= Array()
        for i, prof in this.Profiles 
            if(prof.ProfileName != p_name)
                profArr.Push(prof)
        this.Profiles:= profArr
        this.exportConfig()
    }

    createProfile(p_Name){
        this.Profiles.Push(new ProfileTemplate(p_Name))
        this.exportConfig()
        return this.Profiles[this.Profiles.Length()]
    }
}