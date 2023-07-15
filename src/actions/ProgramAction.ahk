class ProgramAction extends MicrophoneAction {
    static TypeName := "Program"

    __New(program, args) {
        base.__New()
        this.Program := program
        this.Args := args
        this.ActionFormattedText := this._formatAction()
    }

    run(controller) {
        action := Format(this.ActionFormattedText, this._getControllerParams(controller)*)

        try {
            Run, % action, % A_ScriptDir, Hide
        } catch e {
            util_log("[MicrophoneAction] Error running '" this.TypeName "' action: " e.Message)
        }
    }

    getConfig(){
        return { "Type": this.TypeName, "Program": this.Program, "Args": this.Args}
    }

    _formatAction(){
        return this._substituteVarIndexes(Format("""{1}"" {2}", this.Program, this.Args))
    }
}