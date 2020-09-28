#Include, <Neutron>
#Include, <Set>
#If, GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
#If
;auto_exec
Global neutron :=, GUI_mute_hotkey:=new Set(), GUI_unmute_hotkey:=new Set(), GUI_recording_flag:=false, GUI_keys := {}
, GUI_keys_replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right"
, 40: "Down", 45: "Insert", 46: "Delete"}, GUI_modifiers:= {"Alt":"!","RAlt":"!","LAlt":"!","Shift":"+"
,"RShift":"+","LShift":"+","Control":"^","RControl":"^","LControl":"^","LWin":"#","RWin":"#"}
,GUI_mute_passthrough:=0,GUI_mute_wildcard:=0,GUI_unmute_passthrough:=0,GUI_unmute_wildcard:=0
,GUI_mute_adv_hotkey:=0,GUI_unmute_adv_hotkey:=0, GUI_passthrough_tt:="When the hotkey fires, its keys will not be hidden from the system."
,GUI_wildcard_tt:= "Fire the hotkey even if extra modifiers are being held down.", GUI_adv_tt:="Enter a hotkey string using AHK syntax"
,GUI_afk_tt:= "Mute the microphone when idling for longer than the AFK timeout"
; end auto_exec

GUI_show(){ 
    neutron := new NeutronWindow()
    neutron.load("GUI.html")
    if(is_darkmode()){
        load_css("dark.css") 
    }
    getKeys()
    add_tooltips()
    onRestoreConfig(neutron)
    Menu, Tray, Icon, .\assets\MicMute.ico
    neutron.Gui("-Resize")
    neutron.show("w740 h560","MicMute")
    WinSet, Transparent, 252, ahk_class AutoHotkeyGUI
    WinWaitClose, MicMute ahk_class AutoHotkeyGUI
}

onRefreshList(neutron){
    selected_device:= VA_GetDevice(current_config.Microphone)
    dList := VA_GetCaptureDeviceList()
    micSelect:= neutron.doc.getElementByID("microphone")
    micSelect.innerHTML:=""
    loop % dList.Length()
    {
        deviceName:= dList[A_Index].Name
        option:= neutron.doc.createElement("option")
        option.value:= deviceName
        option.innerText:= deviceName
        if(dList[A_Index].isDefault){
            option.innerText:= "(Default) " . option.innerText
            option.selected:= "true"
        }
        if(selected_device && VA_GetDeviceName(selected_device)=deviceName){
            option.selected:= "true"
        }
        micSelect.appendChild(option)
    }
}

getKeys(){
    Loop 350 {
	    code := Format("{:x}", A_Index)
        if(A_Index >=158 && A_Index <= 165)
            continue
	    if(GUI_keys_replacements.HasKey(A_Index)){
	    	n := GUI_keys_replacements[A_Index]
	    } else {
	    	n := GetKeyName("vk" code)
	    }
	    if (n = "Escape" || n = "LButton" || n = "" || GUI_keys.HasKey(n))
	    	continue
	    GUI_keys[n] := 1
    }
}

bindKeys(neutron, element_id){
    inputElem:= neutron.doc.getElementByID(element_id)
    ,GUI_recording_flag:= true
    if(element_id = "mute_input"){
        GUI_mute_hotkey:= new Set()
        hideElemID(neutron, "mute_record")
        showElemID(neutron, "mute_stop")
    }else{
        GUI_unmute_hotkey:= new Set()
        hideElemID(neutron, "unmute_record")
        showElemID(neutron, "unmute_stop")
    }
    inputElem.value:=""
    inputElem.placeholder:="Recording (Don't hold the keys)"
    Hotkey, If , GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
    for n, in GUI_keys {
        funcObj:= Func("addKey").Bind(n, element_id)
        Hotkey, % GetKeyName(n) , % funcObj, On UseErrorLevel
    }
    remFunc := Func("unbindKeys").Bind(neutron, element_id)
    Hotkey, % GetKeyName("Esc") , % remFunc, On UseErrorLevel
    Hotkey, If
}

unbindKeys(neutron, element_id){
    GUI_recording_flag := false
    Hotkey, If , GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
    for n, in GUI_keys
        Hotkey, % GetKeyName(n) , Off, UseErrorLevel
    Hotkey, % GetKeyName("Esc")  , Off, UseErrorLevel
    Hotkey, If
    sanitizeHotkeys(element_id)
    if(element_id = "mute_input"){
        hideElemID(neutron, "mute_stop")
        showElemID(neutron, "mute_record")
    }else{
        hideElemID(neutron, "unmute_stop")
        showElemID(neutron, "unmute_record")
    }
}

addKey(key_name, element_id){
    inputElem:= neutron.doc.getElementByID(element_id)
    if(inputElem.value = ""){
        if(element_id = "mute_input")
            GUI_mute_hotkey.push(key_name) && inputElem.value := key_name . " + "
        else
            GUI_unmute_hotkey.push(key_name) && inputElem.value := key_name . " + "
    }else{
        if(element_id = "mute_input")
            GUI_mute_hotkey.push(key_name) && inputElem.value := inputElem.value . key_name . " + "
        else
            GUI_unmute_hotkey.push(key_name) && inputElem.value := inputElem.value . key_name . " + "
    }
}

sanitizeHotkeys(element_id){
    inputElem:= neutron.doc.getElementByID(element_id)
    inputElem.placeholder:="Click Record"
    hotkey_var:= element_id = "mute_input"? GUI_mute_hotkey : GUI_unmute_hotkey
    isModifierHotkey:= 0
    ; check hotkey length
    while(hotkey_var.data.Length()>3)
        hotkey_var.pop()
    ; check modifier count
    modifierCount:= 0
    for i, value in hotkey_var.data 
        modifierCount += GUI_modifiers.HasKey(value)
    ; if the hotkey contains 3 modifiers or 3 keys it's invalid
    if(modifierCount > 2 || (modifierCount = 0 && hotkey_var.data.Length() > 2))
        Goto, clearHotkey
    ; check whether the hotkey is modifier-only
    if(modifierCount = hotkey_var.data.Length())
        isModifierHotkey:= 1
    ; append hotkey parts
    str := "", inputElem.value := ""
    for i, value in hotkey_var.data {
        ; if the part is a modifier and the hotkey is not a modifier-only hotkey => prepend symbol
        ; else => append the part
        if (GUI_modifiers.HasKey(value) && !isModifierHotkey){ 
            str :=  GUI_modifiers[value] . str
            inputElem.value := value . " + " . inputElem.value
        }else{
            str .= value . " & "
            inputElem.value := inputElem.value . value . " + "
        }
    }
    ; remove trailing " + " and " & "
    if(SubStr(str, -2) = " & ")
        str := SubStr(str,1,-3)
    inputElem.value := SubStr(inputElem.value,1,-3)
    ; set hotkey var to final string
    if(element_id = "mute_input")
        GUI_mute_hotkey := str
    else
        GUI_unmute_hotkey := str
    return
    clearHotkey:
    if(element_id = "mute_input")
        GUI_mute_hotkey := new Set()
    else
        GUI_unmute_hotkey := new Set()
    inputElem.value:=""
}

onSaveConfig(neutron, event){
    formData:= neutron.GetFormData(event.target)
    current_config.Microphone:= formData.microphone
    mute_str:="",mute_input:="",unmute_str:="",unmute_input:=""
    if(GUI_mute_adv_hotkey)
        mute_input:= formData.mute_input
    else
        mute_input:= !IsObject(GUI_mute_hotkey)? GUI_mute_hotkey:""
    if(mute_input = "")
        Goto, invalidHotkey
    mute_str:= GUI_mute_passthrough && !InStr(mute_input, "~")? "~":""
    mute_str.= GUI_mute_wildcard && !InStr(mute_input, "*")? "*":""
    mute_str.= mute_input
    current_config.MuteHotkey:= current_config.UnmuteHotkey:= mute_str
    if(formData.hotkeyType = 1){
        if(GUI_unmute_adv_hotkey)
            unmute_input:= formData.unmute_input
        else
            unmute_input:= !IsObject(GUI_unmute_hotkey)? GUI_unmute_hotkey:""
        if(unmute_input = "")
            Goto, invalidHotkey
        unmute_str:= GUI_unmute_passthrough && !InStr(unmute_input, "~")? "~":""
        unmute_str.= GUI_unmute_wildcard && !InStr(unmute_input, "*")? "*":""
        unmute_str.= unmute_input
        current_config.UnmuteHotkey:= unmute_str
    }
    current_config.PushToTalk:= formData.hotkeyType > 2
    current_config.afkTimeout:= formData.afk_timeout? formData.afk_timeout : 0
    current_config.OnscreenFeedback:= formData.on_screen_fb? 1 : 0
    current_config.ExcludeFullscreen:= formData.on_screen_fb_excl? 1 : 0
    current_config.SoundFeedback:= formData.sound_fb? 1 : 0
    current_config.writeIni()
    neutron.Destroy()
    return
    invalidHotkey:
    neutron.Destroy()
}

onRestoreConfig(neutron){
    neutron.doc.getElementById("form").reset()
    onRefreshList(neutron)
    if(current_config.PushToTalk)
        neutron.doc.getElementById("ptt_hotkey").checked:="true"
    else if(current_config.MuteHotkey && current_config.MuteHotkey = current_config.UnmuteHotkey)
        neutron.doc.getElementById("tog_hotkey").checked:="true"
    else
        neutron.doc.getElementById("sep_hotkey").checked:="true"
    onHotkeyType(neutron)
    if(current_config.MuteHotkey){
        neutron.doc.getElementById("mute_adv_hotkey").checked:="true"
        onOption(neutron,"mute_adv_hotkey",0,0)
        str:=current_config.MuteHotkey
        if(InStr(str, "~")){
            neutron.doc.getElementById("mute_passthrough").checked:="true"
            onOption(neutron,"mute_passthrough",0,-1)
            str:= StrReplace(str, "~")
        }
        if(InStr(str, "*")){
            neutron.doc.getElementById("mute_wildcard").checked:="true"
            onOption(neutron,"mute_wildcard",0,1)
            str:= StrReplace(str, "*")
        }
        neutron.doc.getElementById("mute_input").value:= str
    }
    if(current_config.UnmuteHotkey){
        neutron.doc.getElementById("unmute_adv_hotkey").checked:="true"
        onOption(neutron,"unmute_adv_hotkey",1,0)
        str:=current_config.UnmuteHotkey
        if(InStr(str, "~")){
            neutron.doc.getElementById("unmute_passthrough").checked:="true"
            onOption(neutron,"unmute_passthrough",1,-1)
            str:= StrReplace(str, "~")
        }
        if(InStr(str, "*")){
            neutron.doc.getElementById("unmute_wildcard").checked:="true"
            onOption(neutron,"unmute_wildcard",1,1)
            str:= StrReplace(str, "*")
        }
        neutron.doc.getElementById("unmute_input").value:= str
    }
    if (current_config.SoundFeedback)
        neutron.doc.getElementByID("sound_fb").checked:= "true"
    if (current_config.OnscreenFeedback)
        neutron.doc.getElementByID("on_screen_fb").checked:= "true"
    onOSDfb(neutron)
    if (current_config.ExcludeFullscreen)
        neutron.doc.getElementByID("on_screen_fb_excl").checked:= "true"
    if (current_config.afkTimeout)
        neutron.doc.getElementByID("afk_timeout").value:= current_config.afkTimeout
}

onOption(neutron, event, p_type, p_option){
    event:= IsObject(event)? event.target : neutron.doc.getElementById(event)
    if(p_option<0){ ;passthrough
        if(p_type)
            GUI_unmute_passthrough:= event.checked ? 1 : 0
        else
            GUI_mute_passthrough:= event.checked ? 1 : 0
    }else if(p_option){ ;wildcard
        if(p_type)
            GUI_unmute_wildcard:= event.checked ? 1 : 0
        else
            GUI_mute_wildcard:= event.checked ? 1 : 0
    }else{ ;adv
        inputElem:=,recButton:=,stopButton:=
        if(p_type){
            inputElem:= neutron.doc.getElementById("unmute_input")
            recButton:= "unmute_record"
            stopButton:= "unmute_stop"
            inputElem.value:= !IsObject(GUI_unmute_hotkey)? GUI_unmute_hotkey : ""
        }else{
            inputElem:= neutron.doc.getElementById("mute_input")
            recButton:= "mute_record"
            stopButton:= "mute_stop"
            inputElem.value:= !IsObject(GUI_mute_hotkey)? GUI_mute_hotkey : ""
        }
        if(event.checked){
            hideElemID(neutron,recButton)
            hideElemID(neutron,stopButton)
            inputElem.removeAttribute("disabled")
            inputElem.placeholder:="Enter a hotkey string"
            if(p_type)
                GUI_unmute_adv_hotkey:=1
            else
                GUI_mute_adv_hotkey:=1
        }else{
            showElemID(neutron,recButton)
            inputElem.disabled:="true"
            inputElem.placeholder:="Click Record"
            inputElem.value:=""
            if(p_type)
                GUI_unmute_adv_hotkey:=0
            else
                GUI_mute_adv_hotkey:=0
        }
    }
}

onHotkeyType(neutron){
    if(neutron.doc.getElementByID("sep_hotkey").checked){
        showElemID(neutron, "unmute_box")
        showElemID(neutron, "afk_timeout_col")
        neutron.doc.getElementByID("mute_label").innerText:= "Mute hotkey"
    }
    if(neutron.doc.getElementByID("tog_hotkey").checked){
        hideElemID(neutron, "unmute_box")
        neutron.doc.getElementByID("unmute_ghost_box").style.height := "152.52px"
        showElemID(neutron, "afk_timeout_col")
        neutron.doc.getElementByID("mute_label").innerText:= "Toggle hotkey"
    }
    if(neutron.doc.getElementByID("ptt_hotkey").checked){
        hideElemID(neutron, "unmute_box")
        hideElemID(neutron, "afk_timeout_col")
        neutron.doc.getElementByID("mute_label").innerText:= "Push-to-talk hotkey"
    }
}

onOSDfb(neutron){
    if(neutron.doc.getElementByID("on_screen_fb").checked)
        showElemID(neutron, "os_fb_excl_tag")
    else
        hideElemID(neutron, "os_fb_excl_tag")
}

onclickFooter(neutron){
    Run, https://github.com/SaifAqqad/AHK_MicMute
}

hideElemID(neutron, id){
    elem:= neutron.doc.getElementByID(id)
    elem.classList.add("is-hidden")
}

showElemID(neutron, id){
    elem:= neutron.doc.getElementByID(id)
    elem.classList.remove("is-hidden")
}

load_css(file){
    local head := neutron.doc.querySelector("head"), link
    link:= neutron.doc.createElement("link")
    link.rel:= "stylesheet"
    link.href:= file
    head.appendChild(link)
}

add_tooltips(){
    pt_labels:= neutron.qsa(".passthrough-label")
    wc_labels:= neutron.qsa(".wildcard-label")
    adv_labels:= neutron.qsa(".adv-label")
    afk_label:= neutron.qs(".afk-label")
    for i, label in neutron.Each(pt_labels)
        label.setAttribute("data-title", GUI_passthrough_tt)
    for i, label in neutron.Each(wc_labels)
        label.setAttribute("data-title", GUI_wildcard_tt)
    for i, label in neutron.Each(adv_labels)
        label.setAttribute("data-title", GUI_adv_tt)
    afk_label.setAttribute("data-title", GUI_afk_tt)
}

is_darkmode(){
    local sysTheme
    RegRead, sysTheme
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    return !sysTheme
}

installRes(){
    FileInstall, GUI.html, GUI.html
    FileInstall, bulma.css, bulma.css
    FileInstall, dark.css, dark.css
}