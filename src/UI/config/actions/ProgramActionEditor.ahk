class ProgramActionEditor extends ActionEditor {
    __New(actionConfig, exitCallback) {
        this.sizeConfig:= {min: {width: 685, height: 400}, initial: {width: 720, height: 400}}
        this.actionConfig:= actionConfig

        base.__New(actionConfig, exitCallback, this.sizeConfig)

        this.load(resources_obj.htmlFile.ProgramActionEditor)
        this.loadCss()
        this.updateUITheme()

        this.qs("#Program").value:= this.actionConfig.Program
        this.qs("#Arguments").value:= this.actionConfig.Args
    }

    save(){
        this.actionConfig.Program:= Trim(this.qs("#Program").value)
        this.actionConfig.Args:= Trim(this.qs("#Arguments").value)

        if(!this.actionConfig.Program){
            base.Destroy()
            this.exitCallback.Call("")
        }

        base.save()
    }

    browsePrograms(){
        this.Gui("+OwnDialogs +Disabled")
        FileSelectFile, fileOut, 1, % A_Desktop, Select a program - MicMute, Programs (*.exe)
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