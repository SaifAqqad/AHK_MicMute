class ProgramActionEditor extends ActionEditor {
    __New(actionConfig, exitCallback){
        base.__New(actionConfig, exitCallback)
        this.load(resources_obj.htmlFile.ProgramActionEditor)
        this.loadCss()
        this.updateUITheme()
    }

}