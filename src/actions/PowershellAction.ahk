class PowershellAction extends MicrophoneAction {
    static TypeName := "Powershell"
    , PowershellPath := A_WinDir . "\System32\WindowsPowerShell\v1.0\powershell.exe"
    , DefaultArgs := "-NoProfile -NonInteractive -WindowStyle Hidden"
    
    __New(script) {
        base.__New()
        this.Script := script
        this.ActionFormattedText := this._formatAction()
    }

    run(controller) {
        script := Format(this.ActionFormattedText, this._getControllerParams(controller)*)
        formattedCommand := Format("""{1}"" {2} -EncodedCommand ""{3}""", this.PowershellPath, this.DefaultArgs, util_b64Encode(script))
        
        try {
            Run, % formattedCommand, % A_ScriptDir, Hide
        } catch e {
            util_log("[MicrophoneAction] Error running '" this.TypeName "' action: " e.Message)
        }
    }

    getConfig(){
        return { "Type": this.TypeName, "Script": this.Script}
    }

    _formatAction(){
        return "& {{}" StrReplace(this._substituteVarIndexes(this.Script), "`r`n", ";") "{}}"
    }
}