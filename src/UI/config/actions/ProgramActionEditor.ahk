class ProgramActionEditor extends ActionEditor {
    __New(actionConfig, exitCallback) {
        this.sizeConfig:= {min: {width: 685*UI_scale, height: 400*UI_scale}
        , initial: {width: 720*UI_scale, height: 400*UI_scale}}
        this.actionConfig:= actionConfig

        base.__New(actionConfig, exitCallback, this.sizeConfig)

        this.load(resources_obj.htmlFile.ProgramActionEditor)
        this.loadCss()
        this.updateUITheme()

        this.qs("#Program").value:= this.actionConfig.Program
        this.qs("#Arguments").value:= this.actionConfig.Args
    }

    save(){
        this.actionConfig.Program:= this.qs("#Program").value
        this.actionConfig.Args:= this.qs("#Arguments").value
        base.save()
    }

    browsePrograms(){
        this.Gui("+OwnDialogs +Disabled")
        FileSelectFile, fileOut, 1, % A_Desktop, MicMute - Select a program, Programs (*.exe)
        this.Gui("-OwnDialogs -Disabled")
        if (fileOut) {
            this.qs("#Program").value:= fileOut
        }
    }

    showHelpModal() {
        this.qs("#helpModal > .page-mask").classList.remove("hidden")
        this.qs("#helpModal > .modal-contents").classList.remove("hidden")
        this.qs(".main").classList.add("is-clipped")
    }

    hideHelpModal(event := "") {
        maskElem := this.qs("#helpModal > .page-mask")
        pElem := this.qs("#helpModal > .modal-contents")
        if (!event || event.keyCode = 0x1B || event.keyCode = 0x0D) {
            maskElem.classList.add("hidden")
            pElem.classList.add("hidden")
            this.qs(".main").classList.remove("is-clipped")
        }
    }
}