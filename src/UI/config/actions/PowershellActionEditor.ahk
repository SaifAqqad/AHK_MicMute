class PowershellActionEditor extends ActionEditor {
    static PowershellSnippets := 
    ( Join LTrim RTrim0
        {
            "Microphone Data" : "
            $microphone = @{`r`n    
                name = '${microphone.name}';`r`n    
                fullName = '${microphone.fullName}';`r`n    
                state = '${microphone.state}';`r`n    
                isMuted = $${microphone.isMuted};`r`n    
                hotkeyTriggered = $${microphone.hotkeyTriggered};`r`n
            };`r`n",

            "if/else Muted": "
            if($microphone.isMuted){`r`n    
                # microphone is muted`r`n
            }else{`r`n    
                # microphone is not muted`r`n
            }`r`n",

            "Hotkey Trigger condition": "
            if(!$microphone.hotkeyTriggered){`r`n    
                # hotkey was not triggered`r`n    
                # Microphone state was changed by another app`r`n    
                return;`r`n
            }`r`n"
        }
    )

    __New(actionConfig, exitCallback){
        this.sizeConfig:= {min: {width: 685, height: 400}, initial: {width: 720, height: 550}}
        this.actionConfig:= actionConfig

        base.__New(actionConfig, exitCallback, this.sizeConfig)

        this.load(resources_obj.htmlFile.PowershellActionEditor)
        this.loadCss()
        this.loadJs()
        this.updateUITheme()
        
        initCodeMirrorFunc:= ObjBindMethod(this, "initCodeMirror")
        SetTimer, % initCodeMirrorFunc, -1
    }

    loadJs(){
        for _i, js in resources_obj.jsFile {
            if js.name in codemirror,powershell {
                scriptTag:= this.doc.createElement("script")
                scriptTag.type:= "text/javascript" 
                scriptTag.src:= js.file
                this.doc.head.appendChild(scriptTag)
            }
        }
    }

    initCodeMirror(){
        checkJsLoaded:
        try{
            js:= this.wnd.CodeMirror
        }catch err{
            Sleep, 150
            goto checkJsLoaded
        }
        
        script:= this.actionConfig.Script? B64.decode(this.actionConfig.Script) : ""

        codeMirrorConfig := JSON.Dump
        ( Join LTrim ; ahk
            ({ 
                "value": script,
                "mode":  "application/x-powershell",
                "lineSeparator": "`r`n",
                "theme": util_getSystemTheme().Apps == 1 ? "micmute" : "default",
                "lineNumbers": JSON.true,
                "inputStyle": "textarea",
                "showCursorWhenSelecting": JSON.true,
                "autofocus": JSON.true,
                "autocorrect": JSON.true
            })
        )

        this.codeMirrorContainer:= this.doc.getElementById("codeEditor")
        this.codeMirror := this.wnd.CodeMirror(this.codeMirrorContainer, this.wnd.jsonToJsObject(codeMirrorConfig))
    }

    save(){
        script:= Trim(this.codeMirror.getValue("`r`n"))

        if(!script){
            base.Destroy()
            this.exitCallback.Call("")
        }

        this.actionConfig.Script:= B64.encode(script)
        base.save()
    }

    insertSnippet(snippetName:=""){
        snippet:= this.PowershellSnippets[snippetName]
        if(!snippet)
            return

        cursorPos:= this.codeMirror.getCursor()
        if(cursorPos.ch > 0){
            cursorPos.ch := 0
        }

        this.codeMirror.replaceRange(snippet, cursorPos)
        this.codeMirror.focus()
    }
}