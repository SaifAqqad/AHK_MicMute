class ActionEditor extends NeutronWindow {
    __New(actionConfig, exitCallback){
        util_log("[ActionEditor] Creating '" actionConfig.Type "' ActionEditor window.")
        
        this.exitCallback:= exitCallback
        this.actionConfig:= actionConfig

        features:= {"FEATURE_GPU_RENDERING": 0x1
            ,"FEATURE_BROWSER_EMULATION": 0x2AF8
            ,"FEATURE_96DPI_PIXEL": 0x1}
        this.enableIeFeatures(features)
        base.__New()
        this.enableIeFeatures(features, 1)
        
        OnMessage(WM_SETTINGCHANGE, ObjBindMethod(this, "updateUITheme"))
    }

    show(ownerHwnd){
        this.ownerHwnd:= ownerHwnd
        this.Gui(Format("+LabelUI_ +MinSize{:i}x{:i} +OwnDialogs +Owner{}", 685*UI_scale, 400*UI_scale, ownerHwnd))
        base.Show(Format("w{:i} h{:i}",720*UI_scale,550*UI_scale), "MicMute")
    }

    close(){
        this.Gui("+OwnDialogs")
        MsgBox, 36, MicMute, Do you want to save the changes to this action
        base.Destroy()
        IfMsgBox, No
            return this.exitCallback.Call("")
        this.exitCallback.Call(this.actionConfig)
    }

    delete(){
        this.Gui("+OwnDialogs")
        MsgBox, 36, MicMute, Are you sure you want to delete this action?
        IfMsgBox, No
            return
        base.Destroy()
        this.exitCallback.Call(-1)
    }

    loadCss(){
        for i, css in resources_obj.cssFile {
            if(!this.doc.getElementById("css_" css.name))
                this.doc.head.insertAdjacentHTML("beforeend",Format(template_link, css.name, css.file))
        }
    }

    updateUITheme(_wParam:="", lParam:=""){
        if(lParam && StrGet(lParam) != "ImmersiveColorSet")
            return
    
        theme := util_getSystemTheme()
        if(theme.Apps){
            this.doc.getElementById("css_dark").removeAttribute("disabled")
            this.SetWindowFillColor(0x272727)
        }else{
            this.doc.getElementById("css_dark").setAttribute("disabled","1")
            this.SetWindowFillColor(0xF3F3F3)
        }
    }

    enableIeFeatures(f_obj, delete:=0){
        static reg_dir:= "SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\"
             , executable:= A_IsCompiled? A_ScriptName : util_splitPath(A_AhkPath).fileName
        for feature, value in f_obj
            if(!delete)
                RegWrite, REG_DWORD, % "HKCU\" reg_dir feature, % executable, % value
            else
                RegDelete, % "HKCU\" reg_dir feature, % executable
    }

}