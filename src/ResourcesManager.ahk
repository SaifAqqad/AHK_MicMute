
global ICON_ID_APP:= 1000
, ICON_ID_TRAY:= 2000
, ICON_ID_OVERLAY:= 3000
, ICON_ID_MUTE:= 100
, ICON_ID_UNMUTE:= 200
, ICON_ID_WHITE:= 10
, ICON_ID_BLACK:= 20

;@Ahk2Exe-AddResource *10 %A_ScriptDir%\AuraService.ahk, AuraService
;@Ahk2Exe-AddResource *10 Lib\bass.dll
; app icons
;@Ahk2Exe-AddResource %U_Res%\icons\1000.png, icon.png
;@Ahk2Exe-AddResource %U_Res%\icons\1000.ico, 1000
; tray icons
;@Ahk2Exe-AddResource %U_Res%\icons\2110.ico, 2110
;@Ahk2Exe-AddResource %U_Res%\icons\2120.ico, 2120
;@Ahk2Exe-AddResource %U_Res%\icons\2210.ico, 2210
;@Ahk2Exe-AddResource %U_Res%\icons\2220.ico, 2220
; overlay icons
;@Ahk2Exe-AddResource %U_Res%\icons\3110.ico, 3110
;@Ahk2Exe-AddResource %U_Res%\icons\3120.ico, 3120
;@Ahk2Exe-AddResource %U_Res%\icons\3210.ico, 3210
;@Ahk2Exe-AddResource %U_Res%\icons\3220.ico, 3220
; mute/unmute sounds
;@Ahk2Exe-AddResource %U_Res%\mute.wav
;@Ahk2Exe-AddResource %U_Res%\unmute.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_off.wav
;@Ahk2Exe-AddResource %U_Res%\ptt_on.wav
; UI resources
;@Ahk2Exe-AddResource *10 %U_UI%\html\UI.html
;@Ahk2Exe-AddResource *10 %U_UI%\html\Updater.html
;@Ahk2Exe-AddResource *10 %U_UI%\html\about.html
;@Ahk2Exe-AddResource *10 %U_UI%\html\PowershellActionEditor.html
;@Ahk2Exe-AddResource *10 %U_UI%\html\ProgramActionEditor.html
;@Ahk2Exe-AddResource *10 %U_UI%\html\AuraSyncActionEditor.html
;@Ahk2Exe-AddResource *10 %U_UI%\js\codemirror.js
;@Ahk2Exe-AddResource *10 %U_UI%\js\powershell.js
;@Ahk2Exe-AddResource *10 %U_UI%\js\jscolor.js
;@Ahk2Exe-AddResource *10 %U_UI%\css\bulma.css
;@Ahk2Exe-AddResource *10 %U_UI%\css\base.css
;@Ahk2Exe-AddResource *10 %U_UI%\css\dark.css
;@Ahk2Exe-AddResource *10 %U_UI%\css\codemirror.css
;@Ahk2Exe-AddResource *10 %U_UI%\css\codemirror_micmute.css

class ResourcesManager {
    static RES_FOLDER:= A_ScriptDir . "\resources\"
    , UI_FOLDER:= A_ScriptDir . "\UI\config\"

    soundFile:= { mute: "mute.wav"
                , unmute: "unmute.wav"
                , ptt_off: "ptt_off.wav"
                , ptt_on: "ptt_on.wav"}
    pngIcon:= "icon.png"
    htmlFile:= { UI: "UI.html"
               , about: "about.html"
               , Updater: "Updater.html"
               , PowershellActionEditor: "PowershellActionEditor.html"
               , ProgramActionEditor: "ProgramActionEditor.html"
               , AuraSyncActionEditor: "AuraSyncActionEditor.html"}
    cssFile:= [{ name:"bulma",file: "bulma.css"}
              ,{ name:"base",file:"base.css"}
              ,{ name:"dark",file:"dark.css"}
              ,{ name:"codemirror",file:"codemirror.css"}
              ,{ name:"codemirror_micmute",file:"codemirror_micmute.css"}]
    jsFile:= [{ name:"codemirror",file:"codemirror.js"}
             ,{ name:"powershell",file:"powershell.js"}
             ,{ name:"jscolor",file:"jscolor.js"}]
    __New(){
        if(A_IsCompiled){
            for type, file in this.SoundFile {
                this.soundFile[type]:= this.getResourcePtr(file)
            }
            this.extractResources("bass.dll")
        }else{
            ; if not -> prepend the path to all resources
            for type, filePath in this.SoundFile {
                this.soundFile[type]:= {file: this.RES_FOLDER . filePath}
            }
            for name,file in this.htmlFile { ;neutron prepends "A_WorkingDir/" to the file
                this.htmlFile[name]:= "UI/config/html/" . file
            }
            for i,css in this.cssFile {
                css.file:= this.UI_FOLDER . "css\" . css.file
            }
            for i,js in this.jsFile {
                js.file:= this.UI_FOLDER . "js\" . js.file
            }
            this.pngIcon:= this.RES_FOLDER "icons\" ICON_ID_APP ".png"
        }
    }

    getSoundFile(state, isPtt:=0){
        if(isPtt){
            return state? this.soundFile.ptt_off : this.soundFile.ptt_on
        }else{
            return state? this.soundFile.mute : this.soundFile.unmute
        }
    }

    ; Based on ResRead() by SKAN https://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/?p=609282
    getResourcePtr(resource){
        if hMod := DllCall("GetModuleHandle", "UInt", 0, "PTR")
            if hRes := DllCall("FindResource", "UInt", hMod, "Str", resource, "UInt", 10, "PTR")
                if hData := DllCall("LoadResource", "UInt", hMod, "UInt", hRes, "PTR")
                    if pData := DllCall("LockResource", "UInt", hData, "PTR")
                        return { ptr: pData
                              , size: DllCall( "SizeofResource", "UInt", hMod, "UInt", hRes, "PTR")}
    }

    extractResources(resource){
        if(FileExist(resource) || !(res:= this.getResourcePtr(resource)))
            return
        _f:= FileOpen(resource, "w")
        _f.RawWrite(res.ptr, res.size)
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

    getTrayIcon(state){        
        if(state = -1)
            return this.getIcon(ICON_ID_APP)
        iconId := ICON_ID_TRAY
        iconId += state? ICON_ID_MUTE : ICON_ID_UNMUTE
        iconId += util_getSystemTheme().System? ICON_ID_WHITE : ICON_ID_BLACK
        return this.getIcon(iconId)
    }

    getIcon(iconId){
        return A_IsCompiled? {file: A_ScriptFullPath, group: -iconId} 
                : {file: this.RES_FOLDER "icons\" iconId ".ico", group: 1}
    }
}