#Include, <JSON>
class Config {
    DefaultProfile:=""
    Profiles:=Array()
    MuteOnStartup:=0
    UseCustomSounds:=0
    SwitchProfileOSD:=1

    __New(p_DefaultProfile:=""){
        this["$schema"]:= "https://raw.githubusercontent.com/SaifAqqad/AHK_MicMute/master/src/config_schema.json"
        if(!FileExist("config.json")||isFileEmpty("config.json")){
            if(FileExist("config.ini")){
                this.importIniConfig()
            }else{
                this.DefaultProfile:= this.createProfile("Default").ProfileName
                this.exportConfig()
            }
        }else{
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
        dfProfile:= this.createProfile("Default")
        this.DefaultProfile:= dfProfile.ProfileName
        for key, val in dfProfile {
            IniRead, iniVal, config.ini, settings, %key%
            if(iniVal = "ERROR")
                continue
            if val is number
                iniVal+=0
            dfProfile[key]:= iniVal
        }
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

class ProfileTemplate{
    __New(p_name_Obj){
        this.ProfileName:= p_name_Obj
        this.Microphone:="capture"
        this.MuteHotkey:=""
        this.UnmuteHotkey:=""
        this.SoundFeedback:=0
        this.OnscreenFeedback:=0
        this.ExcludeFullscreen:=0
        this.UpdateWithSystem:=1
        this.afkTimeout:=0
        this.LinkedApp:=""
        this.PushToTalk:=0
        this.OSDPos:={x:-1,y:-1}
        if(IsObject(p_name_Obj)){
            for prop, val in p_name_Obj{
                this[prop]:= val
            }
        }
    }
}
