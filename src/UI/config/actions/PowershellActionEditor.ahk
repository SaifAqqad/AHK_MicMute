class PowershellActionEditor extends ActionEditor {
    __New(actionConfig, exitCallback){
        base.__New(actionConfig, exitCallback)
        this.load(resources_obj.htmlFile.PowershellActionEditor)
        this.loadCss()
        this.updateUITheme()
    }

}