class HotkeyPanel{
    static modifier_regex:= "i)(([RL]?)(\w+))"
    , symbol_regex:= "([<>])?([+^!#])"
    , nt_regex:= "i)[RL][SAWC]|[<>][+^!#]"
    mute:= { hotkey: ""
           , wildcard: ""
           , passthrough: ""
           , nt: ""
           , hotkey_h: ""}
    unmute:= { hotkey: ""
             , wildcard: ""
             , passthrough: ""
             , nt: ""
             , hotkey_h: ""}
    hotkeyType:=""

    __New(muteStr:="", unmuteStr:="", type:=""){
        if(muteStr)
            this.setMuteHotkey(muteStr)
        if(unmuteStr)
            this.setUnmuteHotkey(unmuteStr)
        this.hotkeyType:= type
    }

    setMuteHotkey(str){
        this.mute.hotkey:= str
        this.mute.wildcard:= InStr(str, "*")? 1 : 0
        this.mute.passthrough:= InStr(str, "~")? 1 : 0
        this.mute.nt:= RegExMatch(str, this.nt_regex)? 0 : 1
        this.mute.hotkey_h:= this.hotkeyToKeys(str)
    }

    setUnmuteHotkey(str){
        this.unmute.hotkey:= str
        this.unmute.wildcard:= InStr(str, "*")? 1 : 0
        this.unmute.passthrough:= InStr(str, "~")? 1 : 0
        this.unmute.nt:= RegExMatch(str, this.nt_regex)? 0 : 1
        this.unmute.hotkey_h:= this.hotkeyToKeys(str)
    }

    setMuteFromKeySet(keys_ss, wildcard, passthrough, nt){
        this.mute.hotkey:= this.keySetToHotkey(keys_ss)
        this.mute.passthrough:= passthrough || InStr(this.mute.hotkey, "~")
        this.mute.wildcard:= wildcard
        this.mute.nt:= nt
        ;apply options to hotkey
        if(this.mute.wildcard && !InStr(this.mute.hotkey, "*"))
            this.mute.hotkey:= "*" . this.mute.hotkey
        if(this.mute.passthrough && !InStr(this.mute.hotkey, "~"))
            this.mute.hotkey:= "~" . this.mute.hotkey
        this.mute.hotkey_h:= this.hotkeyToKeys(this.mute.hotkey)
    }

    setUnmuteFromKeySet(keys_ss, wildcard, passthrough, nt){
        this.unmute.hotkey:= this.keySetToHotkey(keys_ss)
        this.unmute.wildcard:= wildcard
        this.unmute.passthrough:= passthrough || InStr(this.unmute.hotkey, "~")
        this.unmute.nt:= nt
        ;apply options to hotkey
        if(this.unmute.wildcard && !InStr(this.unmute.hotkey, "*"))
            this.unmute.hotkey:= "*" . this.unmute.hotkey
        if(this.unmute.passthrough && !InStr(this.unmute.hotkey, "~"))
            this.unmute.hotkey:= "~" . this.unmute.hotkey
        this.unmute.hotkey_h:= this.hotkeyToKeys(this.unmute.hotkey)
    }

    keySetToHotkey(keySet){
        ; check hotkey length
        while(keySet.data.Length()>5)
            keySet.pop()
        ; check modifier count
        modifierCount:= 0
        for i, value in keySet.data 
            modifierCount += this.isModifier(value)
        keyCount:= keySet.data.Length() - modifierCount
        switch modifierCount {
            case 0,1: ; (1/2 keys) | (1 modifier 1 key)
                while(keySet.data.Length()>2)
                    keySet.pop()
            case 2: ; (2 modifiers) | (2 modifiers 1 key)
                if(keyCount>1)
                    Goto, invalidHk
            case 3,4: ; (3 modifiers 1 key) | (4 modifiers 1 key)
                if(keyCount!=1)
                    Goto, invalidHk
            default: ; (invalid)
                Goto, invalidHk
        }
        ; check whether the hotkey is modifier-only
        isModifierHotkey:= modifierCount = keySet.data.Length()
        ; append hotkey parts
        str := ""
        for i, value in keySet.data {
            ; if the part is a modifier and the hotkey is not a modifier-only hotkey => prepend symbol
            if (this.isModifier(value) && !isModifierHotkey)
                str :=  this.modifierToSymbol(value) . str
            else ; else => append the part
                str .= value . " & "
        }
        ; remove trailing " & "
        if(SubStr(str, -2) = " & ")
            str := SubStr(str,1,-3)
        ; add tilde to a modifier-only hotkey that uses neutral modifiers
        switch str {
            case "Shift","Alt","Control":
                str:= "~" . str
        }
        return str

        invalidHk:
            Throw, "Invalid Hotkey"
    }

    hotkeyToKeys(str){
        str:= StrReplace(str, "*")
        str:= StrReplace(str, "~")
        finalStr:="",lastIndex:=0
        while(pos:=InStr(str, "<") || pos:=InStr(str, ">")){
            symbol:= SubStr(str, pos, 2)
            modifier:= this.symbolToModifier(symbol)
            finalStr.= this.isModifier(modifier)? modifier . " + " : ""
            str:= StrReplace(str, symbol,,, 1)
        }
        Loop, Parse, str 
        {
            modifier:= this.symbolToModifier(A_LoopField)
            if(this.isModifier(modifier)){
                finalStr.= modifier . " + "
                lastIndex:= A_Index
            }
        }
        str := SubStr(str, lastIndex+1)
        str:= StrSplit(str, "&"," `t")
        for i,val in str {
            finalStr.= val . " + "
        }
        return SubStr(finalStr,1,-3) 
    }

    modifierToSymbol(modifier){
        out:= str:= ""
        RegExMatch(modifier, this.modifier_regex, out)
        switch out2 { 
            case "R": str.=">"
            case "L": str.="<"
        }
        switch out3 {
            case "Alt": str.= "!"
            case "Shift": str.= "+"
            case "Control": str.= "^"
            case "Win": str.= "#"
        }
        return str
    }

    modifierToNeutral(modifier){
        return RegExReplace(modifier,this.modifier_regex,"$3")
    }

    isModifier(key){
        RegExMatch(key, "Alt|Shift|Control|Win", out)
        return out? 1 : 0
    }

    symbolToModifier(symbol){
        out:= str:= ""
        RegExMatch(symbol, this.symbol_regex, out)
        switch out1 {
            case "<": str.= "L"
            case ">": str.= "R"
        }
        switch out2 {
            case "!": str.= "Alt" 
            case "+": str.= "Shift" 
            case "^": str.= "Control" 
            case "#": str.= "Win" 
        }
        return str
    }

    isTypeValid(){
        switch this.hotkeyType {
            case 0: return 1
            case 1,2: return this.mute.hotkey == this.unmute.hotkey
        }
    }

}