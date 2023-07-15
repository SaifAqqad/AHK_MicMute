class AuraSyncActionEditor extends ActionEditor {
    __New(actionConfig, exitCallback) {
        this.sizeConfig:= {min: {width: 580, height: 240}, initial: {width: 620, height: 240}}
        this.actionConfig:= actionConfig

        base.__New(actionConfig, exitCallback, this.sizeConfig)

        this.load(resources_obj.htmlFile.AuraSyncActionEditor)
        this.loadCss()
        this.updateUITheme()
        this.loadJs()

        defaultColor := "#ff572d"
        this.qs("#MuteColor").value := this.actionConfig.MuteColor ? this.actionConfig.MuteColor : defaultColor
        this.qs("#UnmuteColor").value := this.actionConfig.UnmuteColor ? this.actionConfig.UnmuteColor : defaultColor
        
        initColorInputsFunc:= ObjBindMethod(this, "initColorInputs")
        SetTimer, % initColorInputsFunc, -1
    }

    initColorInputs(){
        theme := util_getSystemTheme()
        backgroundColor := theme.Apps ? "#323232" : "#FBFBFB"

        inputConfig := JSON.Dump(
        ( Join LTrim ; ahk
            {
                width: 201,
                height: 81,
                position: "bottom",
                previewPosition: "left",
                previewSize: 55,
                backgroundColor: backgroundColor,
                borderColor: backgroundColor,
                controlBorderColor: backgroundColor
            }
        ))

        colorInputs := this.qsa(".color-input")
        for _i, colorInput in this.Each(colorInputs) {
            colorInput.dataset.jscolor:= inputConfig
        }

        checkJsColorLoaded:
        try{
            js:= this.wnd.jscolor
        }catch err{
            Sleep, 150
            goto checkJsColorLoaded
        }

        this.wnd.jscolor.init()
    }

    loadJs(){
        for _i, js in resources_obj.jsFile {
            if js.name in jscolor {
                scriptTag:= this.doc.createElement("script")
                scriptTag.type:= "text/javascript"
                scriptTag.src:= js.file
                this.doc.head.appendChild(scriptTag)
            }
        }
    }

    save(){
        this.actionConfig.MuteColor := this.qs("#MuteColor").value
        this.actionConfig.UnmuteColor := this.qs("#UnmuteColor").value
        
        base.save()
    }
}