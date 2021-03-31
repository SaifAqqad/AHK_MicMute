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
            this.setFromHotkey("mute",muteStr)
        if(unmuteStr)
            this.setFromHotkey("unmute",unmuteStr)
        this.hotkeyType:= type
    }

    setFromHotkey(type, str){
        this[type].hotkey:= str
        this[type].wildcard:= InStr(str, "*")? 1 : 0
        this[type].passthrough:= InStr(str, "~")? 1 : 0
        this[type].nt:= RegExMatch(str, this.nt_regex)? 0 : 1
        this[type].hotkey_h:= this.hotkeyToKeys(str)
    }

    setFromKeySet(type, keys_set, wildcard, passthrough, nt){
        this[type].hotkey:= this.keySetToHotkey(keys_set)
        this[type].wildcard:= wildcard
        this[type].passthrough:= passthrough || InStr(this.unmute.hotkey, "~")
        this[type].nt:= nt
        ;apply options to hotkey
        updateOption(type, "wildcard", this[type].wildcard)
        updateOption(type, "passthrough", this[type].passthrough)
        this[type].hotkey_h:= this.hotkeyToKeys(this[type].hotkey)
    }

    updateOption(type, option, enable){
        this[type][option]:= enable
        symb:=""
        switch option {
            case "wildcard": symb:="*"
            case "passthrough": symb:="~"
        }
        if(enable)
            if(!InStr(this[type].hotkey, symb))
                this[type].hotkey:= symb . this[type].hotkey
        else
            this[type].hotkey:= StrReplace(this[type].hotkey, symb)
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