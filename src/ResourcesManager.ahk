class ResourcesManager {
    
    ;@Ahk2Exe-AddResource %U_Res%\MicMute.png
    ;@Ahk2Exe-AddResource %U_Res%\MicMute.ico, 2000
    ;@Ahk2Exe-AddResource %U_Res%\black_unmute.ico, 3080
    ;@Ahk2Exe-AddResource %U_Res%\black_mute.ico, 4080
    ;@Ahk2Exe-AddResource %U_Res%\white_unmute.ico, 3090
    ;@Ahk2Exe-AddResource %U_Res%\white_mute.ico, 4090
    ;@Ahk2Exe-AddResource %U_Res%\mute.wav
    ;@Ahk2Exe-AddResource %U_Res%\unmute.wav
    ;@Ahk2Exe-AddResource %U_Res%\ptt_off.wav
    ;@Ahk2Exe-AddResource %U_Res%\ptt_on.wav
    ;@Ahk2Exe-AddResource *10 %U_UI%\html\UI.html
    ;@Ahk2Exe-AddResource *10 %U_UI%\html\about.html
    ;@Ahk2Exe-AddResource %U_UI%\css\bulma.css
    ;@Ahk2Exe-AddResource %U_UI%\css\base.css
    ;@Ahk2Exe-AddResource %U_UI%\css\dark.css

    static RES_FOLDER:= A_ScriptDir . "\resources\"
    , UI_FOLDER:= A_ScriptDir . "\UI\config\"
    soundFile:= { mute: "mute.wav"
                , unmute: "unmute.wav"
                , ptt_off: "ptt_off.wav"
                , ptt_on: "ptt_on.wav"}
    icoFile:= { black_mute: {file:"black_mute.ico",group:"-4080"}
              , black_unmute: {file:"black_unmute.ico",group:"-3080"}
              , white_mute: {file:"white_mute.ico",group:"-4090"}
              , white_unmute: {file:"white_unmute.ico",group:"-3090"}}
    defaultIcon:= {file:"MicMute.ico",group:"-2000"}
    pngIcon:= "MicMute.png"
    htmlFile:= { UI: "UI.html"
               , about: "about.html"}
    cssFile:= [{ name:"bulma",file: "bulma.css"}
              ,{ name:"base",file:"base.css"}
              ,{ name:"dark",file:"dark.css"}]
    __New(){
        if(A_IsCompiled){
            ;if we're running the compiled version -> set icon's 'file' property to executable full path
            this.defaultIcon.file:= A_ScriptFullPath
            for obj, ico in this.icoFile {
                ico.file:= A_ScriptFullPath
            }
            for type, file in this.SoundFile {
                this.soundFile[type]:= this.getResourcePtr(file)
            }
        }else{
            ; if not -> prepend the path to all resources
            for type, filePath in this.SoundFile {
                this.soundFile[type]:= {file: this.RES_FOLDER . filePath}
            }

            for obj, ico in this.icoFile {
                ico.file:= this.RES_FOLDER . ico.file
                ico.group:= "1"
            }
            for name,file in this.htmlFile { ;neutron prepends "A_WorkingDir/" to the file
                this.htmlFile[name]:= "UI/config/html/" . file
            }
            for i,css in this.cssFile {
                css.file:= this.UI_FOLDER . "css\" . css.file
            }
            this.defaultIcon.file:= this.RES_FOLDER . this.defaultIcon.file
            this.defaultIcon.group:= "1"
            this.pngIcon:= this.RES_FOLDER . this.pngIcon
        }
    }

    getSoundFile(state, isPtt:=0){
        if(isPtt){
            return state? this.soundFile.ptt_off : this.soundFile.ptt_on
        }else{
            return state? this.soundFile.mute : this.soundFile.unmute
        }
    }

    getResourcePtr(resource){
        if hMod := DllCall("GetModuleHandle", "UInt", 0, "PTR")
            if hRes := DllCall("FindResource", "UInt", hMod, "Str", resource, "UInt", 10, "PTR")
                if hData := DllCall("LoadResource", "UInt", hMod, "UInt", hRes, "PTR")
                    if pData := DllCall("LockResource", "UInt", hData, "PTR")
                        return { ptr: pData
                              , size: DllCall( "SizeofResource", "UInt", hMod, "UInt", hRes, "PTR")}
    }

    loadCustomSounds(){
        for s_type in this.soundFile {
            Loop, Files, %s_type%.*
            {
                if A_LoopFileExt in wav,mp3,ogg 
                {
                    this.soundFile[s_type]:= {file: A_LoopFileLongPath}
                    break
                }
            }
        }
    }

    getIcoFile(state){
        color:= sys_theme? "white" : "black"
        state:= state? "mute" : "unmute"
        return this.icoFile[color "_" state]
    }
}