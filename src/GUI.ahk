#Include, <Neutron>
#Include, <Set>
;auto_exec
Global neutron :=, GUI_mute_hotkey:=new Set(), GUI_unmute_hotkey:=new Set(), GUI_recording_flag:=false, GUI_keys := {}
, GUI_keys_replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right"
, 40: "Down", 45: "Insert", 46: "Delete"}, GUI_modifiers:= {"Alt":"!","RAlt":"!","LAlt":"!","Shift":"+"
,"RShift":"+","LShift":"+","Control":"^","RControl":"^","LControl":"^"}
; end auto_exec
#If, GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
#If

GUI_show(){ 
    neutron := new NeutronWindow()
    neutron.load("GUI.html")
    if(is_darkmode()){
        load_css("dark.css") 
    }
    getKeys()
    RestoreConfig(neutron)
    Menu, Tray, Icon, .\assets\MicMute.ico
    neutron.show("w840 h560","MicMute")
    WinWaitClose, MicMute ahk_class AutoHotkeyGUI
}

RefreshList(neutron){
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

saveConfig(neutron, event){
    formData := neutron.GetFormData(event.target)
    current_config.Microphone:= formData.microphone
    if (formData.mute_adv_hotkey="on"){
        current_config.MuteHotkey:= formData.mute_input_hotkey , current_config.UnmuteHotkey:= formData.mute_input_hotkey
    }else{ ;select elems
        if (formData.mute_wildcard="on"){
            GUI_mute_hotkey_string := "*" . GUI_mute_hotkey_string
        }else{
            GUI_mute_hotkey_string := StrReplace(GUI_mute_hotkey_string, "*")
        }
        if (formData.mute_passthrough="on"){
            GUI_mute_hotkey_string := "~" . GUI_mute_hotkey_string
        }else{
            GUI_mute_hotkey_string := StrReplace(GUI_mute_hotkey_string, "~")
        }
        modif_1:= neutron.doc.getElementByID("mute_modifier_1").value
        modif_2:= neutron.doc.getElementByID("mute_modifier_2").value
        key:= neutron.doc.getElementByID("mute_key").value
        GUI_mute_hotkey_string .=  modif_1 . modif_2 . key
        current_config.MuteHotkey:= GUI_mute_hotkey_string , current_config.UnmuteHotkey:= GUI_mute_hotkey_string
    }
    if (formData.hotkeyType=1){ ; 1 => seperate hotkeys => repeat for unmute
        if (formData.unmute_adv_hotkey="on"){
            current_config.UnmuteHotkey:= formData.unmute_input_hotkey
        }else{ ;select elems
            if (formData.unmute_wildcard="on"){
                GUI_unmute_hotkey_string := "*" . GUI_unmute_hotkey_string
            }else{
                GUI_unmute_hotkey_string := StrReplace(GUI_unmute_hotkey_string, "*")
            }
            if (formData.unmute_passthrough="on"){
                GUI_unmute_hotkey_string := "~" . GUI_unmute_hotkey_string
            }else{
                GUI_unmute_hotkey_string := StrReplace(GUI_unmute_hotkey_string, "~")
            }
            modif_1:= neutron.doc.getElementByID("unmute_modifier_1").value
            modif_2:= neutron.doc.getElementByID("unmute_modifier_2").value
            key:= neutron.doc.getElementByID("unmute_key").value
            GUI_unmute_hotkey_string .=  modif_1 . modif_2 . key
            current_config.UnmuteHotkey:= GUI_unmute_hotkey_string
        }
    }
    current_config.PushToTalk:= formData.hotkeyType>2
    current_config.afkTimeout:= formData.afk_timeout
    current_config.OnscreenFeedback:= formData.on_screen_fb
    current_config.ExcludeFullscreen:= formData.on_screen_fb_excl
    current_config.SoundFeedback:= formData.sound_fb
    current_config.writeIni()
    neutron.Destroy()
}

RestoreConfig(neutron){
    RefreshList(neutron)
    if (current_config.MuteHotkey){
        neutron.doc.getElementByID("mute_adv_hotkey").checked:= "true"
        neutron.doc.getElementByID("mute_input").value:= current_config.MuteHotkey
        if (InStr(current_config.MuteHotkey, "*"))
            neutron.doc.getElementByID("mute_wildcard").checked:= "true"
        else
            neutron.doc.getElementByID("mute_wildcard").removeAttribute("checked")
        if (InStr(current_config.MuteHotkey, "~"))
            neutron.doc.getElementByID("mute_passthrough").checked:= "true"
        else
            neutron.doc.getElementByID("mute_passthrough").removeAttribute("checked")
    }
    if (current_config.UnmuteHotkey && current_config.UnmuteHotkey != current_config.MuteHotkey){
        neutron.doc.getElementByID("unmute_adv_hotkey").checked:= "true"
        neutron.doc.getElementByID("unmute_input").value:= current_config.UnmuteHotkey
        if (InStr(current_config.UnmuteHotkey, "*"))
            neutron.doc.getElementByID("unmute_wildcard").checked:= "true"
        else
            neutron.doc.getElementByID("unmute_wildcard").removeAttribute("checked")
        if (InStr(current_config.UnmuteHotkey, "~"))
            neutron.doc.getElementByID("unmute_passthrough").checked:= "true"
        else
            neutron.doc.getElementByID("unmute_passthrough").removeAttribute("checked")
    }
    if (current_config.PushToTalk){
        neutron.doc.getElementByID("ptt_hotkey").checked:= "true"
    }else if (current_config.MuteHotkey && current_config.MuteHotkey=current_config.UnmuteHotkey){
        neutron.doc.getElementByID("tog_hotkey").checked:= "true"
    }else{
        neutron.doc.getElementByID("sep_hotkey").checked:= "true"
    }
    HotkeyType(neutron)
    if (current_config.afkTimeout)
        neutron.doc.getElementByID("afk_timeout").value:= current_config.afkTimeout
    else
        neutron.doc.getElementByID("afk_timeout").removeAttribute("value")
    if (current_config.OnscreenFeedback)
        neutron.doc.getElementByID("on_screen_fb").checked:= "true"
    else
        neutron.doc.getElementByID("on_screen_fb").removeAttribute("checked")
    feedback_OSD(neutron)
    if (current_config.ExcludeFullscreen)
        neutron.doc.getElementByID("on_screen_fb_excl").checked:= "true"
    else
        neutron.doc.getElementByID("on_screen_fb_excl").removeAttribute("checked")
    if (current_config.SoundFeedback)
        neutron.doc.getElementByID("sound_fb").checked:= "true"
    else
        neutron.doc.getElementByID("sound_fb").removeAttribute("checked")
}


HotkeyType(neutron){
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

feedback_OSD(neutron){
    if(neutron.doc.getElementByID("on_screen_fb").checked)
        showElemID(neutron, "os_fb_excl_tag")
    else
        hideElemID(neutron, "os_fb_excl_tag")
}

hideDDL(neutron, mFlag){
    for i, elem in neutron.Each(neutron.doc.getElementsByClassName(mFlag . "-ddl-col")) {
        elem.classList.add("is-hidden")
    }
}

showDDL(neutron, mFlag){
    for i, elem in neutron.Each(neutron.doc.getElementsByClassName(mFlag . "-ddl-col")) {
        elem.classList.remove("is-hidden")
    }
}

hideinput(neutron, mFlag){
    for i, elem in neutron.Each(neutron.doc.getElementsByClassName(mFlag . "-input-col")) {
        elem.classList.add("is-hidden")
    }
}

showInput(neutron, mFlag){
    for i, elem in neutron.Each(neutron.doc.getElementsByClassName(mFlag . "-input-col")) {
        elem.classList.remove("is-hidden")
    }
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
    inputElem.placeholder:="Recording"
    Hotkey, If , GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
    for n, in GUI_keys {
        funcObj:= Func("addKey").Bind(n, element_id)
        Hotkey, %  GetKeyName(n) , % funcObj, On
    }
    remFunc := Func("unbindKeys").Bind(neutron, element_id)
    Hotkey, % GetKeyName("Esc") , % remFunc, On
    Hotkey, If
}

unbindKeys(neutron, element_id){
    GUI_recording_flag := false
    Hotkey, If , GUI_recording_flag && WinActive("ahk_class AutoHotkeyGUI")
    for n, in GUI_keys
        Hotkey, % n , Off
    Hotkey, % GetKeyName("Esc")  , Off
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
    if(element_id = "mute_input"){
        while(GUI_mute_hotkey.data.Length()>3)
            GUI_mute_hotkey.pop()
        modifierCount:=0
        for i, value in GUI_mute_hotkey.data 
            modifierCount+= modifiers.HasKey(value)
        if(modifierCount>2)
            Goto, clearMuteHotkey
        str := "", inputElem.value := ""
        for i, value in GUI_mute_hotkey.data {
            str.= modifiers.HasKey(value)? modifiers[value] : value
            inputElem.value := inputElem.value . value . " + "
        }
        inputElem.value := SubStr(inputElem.value,1,-3)
        GUI_mute_hotkey:= str
        return
        clearMuteHotkey:
        GUI_mute_hotkey:= new Set()
        inputElem.value:=""
    }else{
        while(GUI_unmute_hotkey.data.Length()>3)
            GUI_unmute_hotkey.pop()
        modifierCount:=0
        for i, value in GUI_unmute_hotkey.data {
            modifierCount+= modifiers.HasKey(value)
        }
        if(modifierCount>2)
            Goto, clearUnmuteHotkey
        str := "", inputElem.value := ""
        for i, value in GUI_unmute_hotkey.data {
            str.= modifiers.HasKey(value)? modifiers[value] : value
            inputElem.value := inputElem.value . value . " + "
        }
        inputElem.value := SubStr(inputElem.value,1,-3)
        GUI_unmute_hotkey:= str
        return
        clearUnmuteHotkey:
        GUI_unmute_hotkey:= new Set()
        inputElem.value:=""
    }
}