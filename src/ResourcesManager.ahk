class ResourcesManager {
    static RES_FOLDER:= A_ScriptDir . "\resources\"
    , UI_FOLDER:= A_ScriptDir . "\UI\"
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

    __New(){
        if(A_IsCompiled){
            ;if we're running the compiled version -> set icon's 'file' property to executable full path
            for obj, ico in this.icoFile {
                ico.file:= A_ScriptFullPath
            }
            this.defaultIcon.file:= A_ScriptFullPath
        }else{
            ; if not -> prepend the path to the 'file' property
            for type, file in this.SoundFile {
                this.soundFile[type]:= this.RES_FOLDER . file
            }
            for obj, ico in this.icoFile {
                ico.file:= this.RES_FOLDER . ico.file
                ico.group:= "1"
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

    getIcoFile(state){
        color:= sys_theme? "white" : "black"
        state:= state? "mute" : "unmute"
        return this.icoFile[color "_" state]
    }
}