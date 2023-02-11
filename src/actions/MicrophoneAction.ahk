class MicrophoneAction {
    static _variablesIndex :=
    ( Join LTrim ; ahk
        {
            "${microphone.name}": "{1}",
            "${microphone.fullName}": "{2}",
            "${microphone.state}": "{3}",
            "${microphone.state.text}": "{4}",
            "${microphone.state.bool}": "{5}"
        }
    )

    Create(config){
        switch config.Type {
            case ProgramAction.TypeName:
                return new ProgramAction(config.Program, config.Args)
            case PowershellAction.TypeName:
                return new PowershellAction(config.Script)
        }
        Throw, Exception("Unknown action type: " config.Type)
    }

    __New(){
        this.ActionFormattedText := ""
    }

    run(controller) {
        Throw, Exception("Not implemented")
    }

    _exportConfig(){
        Throw, Exception("Not implemented")
    }

    _formatAction(){
        Throw, Exception("Not implemented")
    }

    _substituteVarIndexes(text) {
        for name, index in this._variablesIndex {
            text := StrReplace(text, name, index)
        }
        return text
    }

    ; Returns an array of the controller's parameters in the order of _variablesIndex
    _getControllerParams(controller) {
        controllerParams:=
        ( Join LTrim ; ahk
            [
                controller.shortName,
                util_toString(controller.microphoneName),
                controller.state,
                (controller.state? "Muted" : "Online"),
                (controller.state? "true" : "false")
            ]
        )
        return controllerParams
    }
}