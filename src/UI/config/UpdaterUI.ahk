class UpdaterUI extends NeutronWindow{
    static UI_STATES := ["pre-update", "during-update", "post-update"]
    
    __New(){
        base.__New()
        this.load(resources_obj.htmlFile.Updater)
        this.loadCss()
        updater_obj:= new Updater(arg_installPath, ObjBindMethod(this, "onUpdateState"))
        this.show()
    }

    loadCss(){
        this.doc.getElementById("MicMute_icon").setAttribute("src", resources_obj.pngIcon)
        for i, css in resources_obj.cssFile {
            if(!this.doc.getElementById("css_" css.name))
                this.doc.head.insertAdjacentHTML("beforeend",Format(template_link, css.name, css.file))
        }
        RegRead, isLightTheme, HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
        if(isLightTheme)
            this.doc.getElementById("css_dark").setAttribute("disabled","1")
    }

    show(){
        this.setUIState("pre-update")
        this.resetDetail()
        this.appendDetail("Current version: " A_Version)
        this.appendDetail("Latest version: " updater_obj.getLatestVersion())
        this.appendDetail("Installation method: " updater_obj.installationMethod)
        base.Gui("+LabelUpdaterUI_ +MinSize780x510 -Resize")
        base.Show("Center w780 h510","MicMute Updater")
    }

    setUIState(currentState){
        for i, state in this.UI_STATES {
            for i, elem in this.Each(this.qsa("." state)) {
                elem.classList.add("is-hidden")
            }
        }
        for i, elem in this.Each(this.qsa("." currentState)) {
            elem.classList.remove("is-hidden")
        }
    }

    onUpdateState(str, updaterStatus:=0){
        this.appendDetail(str)
        this.doc.getElementById("current_status").innerText := str
        if(updaterStatus)
            this.setUIState("post-update")
    }

    onClickUpdate(){
        this.setUIState("during-update")
        this.resetDetail()
        updater_obj.update()
    }

    onClickExit(restart:=0){
        if(restart)
            Run, % arg_installPath "\MicMute.exe" , % arg_installPath, UseErrorLevel
        ExitApp, 0
    }

    resetDetail(){
        this.doc.getElementById("details").innerHTML := ""
    }

    appendDetail(str){
        detailBox := this.doc.getElementById("details")
        detailBox.insertAdjacentHTML("beforeend", "<p>" str "</p>")
        detailBox.scrollTop := detailBox.scrollHeight
    }

    Close(){
        ExitApp, -2
    }
}

UpdaterUI_Close(){
    ExitApp, -2
}