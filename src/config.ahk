#Include, <JSON>
class Config {
    DefaultProfile:=""
    Profiles:=Array()

    __New(p_DefaultProfile:=""){
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
        this.DefaultProfile:= jsonObj.DefaultProfile
        this.Profiles:= jsonObj.Profiles
    }

    importIniConfig(){
        dfProfile:= this.createProfile("Default")
        this.DefaultProfile:= dfProfile.ProfileName
        for key in dfProfile {
            IniRead, %key%, config.ini, settings, %key%, % dfProfile[key]? dfProfile[key] : A_Space
            dfProfile[key]:= %key%
        }
        this.exportConfig()
        FileDelete, config.ini
    }

    exportConfig(){
        jsonStr:=JSON.Dump(this)
        jsonFile:=FileOpen("config.json", "w")
        jsonFile.Write(jsonStr)
        jsonFile.Close()
    }

    getProfile(p_name:=""){
        if(!p_name)
            p_name:= this.DefaultProfile
        for i, profile in this.Profiles {
            if(profile.ProfileName = p_name)
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
        for i, prof in this.Profiles {
            if(prof.ProfileName != p_name)
                profArr.Push(prof)
        }
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
    __New(p_name){
        this.ProfileName:= p_name
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
    }
}
