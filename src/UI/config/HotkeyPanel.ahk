class HotkeyPanel{
    static modifier_regex:= "i)(([RL]?)(\w+))"
    , symbol_regex:= "([<>])?([+^!#])"
    , nt_regex:= "i)[RL][SAWC]|[<>][+^!#]"
    mute:= { hotkey: ""
           , wildcard: 0
           , passthrough: 0
           , nt: 1
           , hotkey_h: ""}
    unmute:= { hotkey: ""
             , wildcard: 0
             , passthrough: 0
             , nt: 1
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
        this.updateOption(type, "wildcard", this[type].wildcard)
        this.updateOption(type, "passthrough", this[type].passthrough)
        this[type].hotkey_h:= this.hotkeyToKeys(this[type].hotkey)
    }

    updateOption(type, option, enable){
        this[type][option]:= enable
        symb:=""
        switch option {
            case "wildcard": symb:="*"
            case "passthrough": symb:="~"
            case "nt": return
        }
        if(enable){
            if(!InStr(this[type].hotkey, symb))
                this[type].hotkey:= symb . this[type].hotkey
        }else{
            this[type].hotkey:= StrReplace(this[type].hotkey, symb)
        }
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
            ; if the part is a modifier and the hotkey is not a modifier-only hotkey => append symbol
            if (this.isModifier(value) && !isModifierHotkey)
                str .=  this.modifierToSymbol(value)
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

    hotkeyToKeys(str, useNeutralModifers:=0){
        finalStr:=""
        ;remove wildcard and passthrough symbols
        str:= StrReplace(str, "*")
        str:= StrReplace(str, "~")
        while(str){
            modifier:=""
            if(RegExMatch(str, this.symbol_regex, symbol)){
                ;match modifier symbols
                str:= StrReplace(str, symbol, "",, 1)
                modifier:= this.symbolToModifier(symbol)
                finalStr.= (useNeutralModifers? this.modifierToNeutral(modifier) : modifier) . " + "
            }else if(RegExMatch(str, this.modifier_regex, modifier)){ ; no more symbols
                ;match modifiers
                str:= StrReplace(str, modifier, "",, 1)
                finalStr.= (useNeutralModifers? this.modifierToNeutral(modifier) : modifier) . " + "
            }else{ ;no more modifiers
                ;match keys
                Loop, Parse, str, % "&", %A_Space%%A_Tab%
                {
                    if(A_LoopField){
                        str:= StrReplace(str, A_LoopField, "",, 1)
                        finalStr.= A_LoopField . " + "
                    }
                }
                ;remove spaces and '&' from str
                str:= StrReplace(str, " ", "")
                str:= StrReplace(str, "&", "")
            }
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
            case 0: return this.mute.hotkey && this.unmute.hotkey
            case 1,2: return this.mute.hotkey == this.unmute.hotkey
        }
    }

}