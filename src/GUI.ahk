#Include, <Neutron>
#Include, <UStack>
;GUI Globals
Global neutron :=, GUI_mute_hotkey:=new UStack(), GUI_unmute_hotkey:=new UStack(),GUI_input_hook:= 
,GUI_modifiers:= {"Alt":"!","RAlt":">!","LAlt":"<!","Shift":"+","RShift":">+","LShift":"<+","Control":"^"
,"RControl":">^","LControl":"<^","LWin":"<#","RWin":">#"},GUI_modifier_symbols:={"<^":"LControl",">^":"RControl"
,"^":"Control","<+":"LShift",">+":"RShift","+":"Shift","<!":"LAlt",">!":"RAlt","!":"Alt","<#":"LWin",">#":"RWin","#":"LWin"}
,GUI_nt_modifiers:= {"RAlt":"Alt","LAlt":"Alt","RShift":"Shift","LShift":"Shift","RControl":"Control","LControl":"Control"}
,GUI_mute_passthrough:=0,GUI_mute_wildcard:=0,GUI_unmute_passthrough:=0,GUI_unmute_wildcard:=0
,GUI_mute_nt:=1,GUI_unmute_nt:=1, GUI_passthrough_tt:="When the hotkey fires, its keys will not be hidden from the system."
,GUI_wildcard_tt:= "Fire the hotkey even if extra modifiers are held down.", GUI_nt_tt:="Use neutral modifiers (i.e. Alt instead of Left Alt / Right Alt)"
,GUI_afk_tt:= "Mute the microphone when idling for longer than the AFK timeout"
,GUI_profile_tag_template:= "
(
    <div class=""tag is-large"" id=""tag_profile_{1:}"" onClick=""ahk.checkProfileTag('{1:}')"">
        <label unselectable=""on"" class=""radio"">
            <input type=""radio"" name=""profiles_radio"" value=""{1:}"" id=""profile_{1:}"">
            <span>{1:}</span>
        </label>
    </div>
)"
;------init-functions------
GUI_show(){ 
    RegWrite, REG_DWORD, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_GPU_RENDERING, MicMute.exe, 0x1
    Menu, Tray, Icon, %A_ScriptFullPath%, 1
    neutron := new NeutronWindow()
    neutron.load("GUI.html")
    if(sys_theme){
        load_css("dark.css") 
    }
    add_tooltips()
    restoreConfig()
    neutron.Gui("+MinSize700x440")
    neutron.show("w830 h650","MicMute")
    WinSet, Transparent, 252, % "ahk_id " . neutron.hWnd
    WinWaitClose, % "ahk_id " . neutron.hWnd
    neutron.Destroy()
}

restoreConfig(){
    neutron.doc.getElementById("def_profile").innerHTML:=""
    for i, prfl in conf.Profiles {
        addDefProfileOpt(prfl.ProfileName,(conf.DefaultProfile=prfl.ProfileName))
        addProfileTag(prfl.ProfileName)
    }
    checkProfileTag(neutron,current_profile.ProfileName)
    fetchDeviceList(neutron)
    onRestoreProfile(neutron)
}

fetchDeviceList(neutron){
    selected_device:= current_profile.Microphone
    dList := VA_GetCaptureDeviceList()
    micSelect:= neutron.doc.getElementByID("microphone")
    micSelect.innerHTML:=""
    ;add default option
    option:= neutron.doc.createElement("option")
    option.id:= "mic_capture"
    option.value:= "capture"
    option.innerText:= "Default"
    if(!selected_device || selected_device = "capture")
        option.selected:= "true"
    micSelect.appendChild(option)
    ;add mics
    for i, device in dList {
        option:= neutron.doc.createElement("option")
        option.id:= "mic_" . device.Name
        option.value:= device.Name
        option.innerText:= device.Name
        if(selected_device && InStr(device.Name, selected_device)){
            option.selected:= "true"
        }
        micSelect.appendChild(option)
    }
}

;------hotkey-generation-functions------

addKey(element_id, InputHook, VK, SC){
    key_name:= GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    inputElem:= neutron.doc.getElementByID(element_id)
    if(element_id = "mute_input"){
        if(GUI_mute_nt && GUI_nt_modifiers.HasKey(key_name)){
            key_name:= GUI_nt_modifiers[key_name]
        }
        GUI_mute_hotkey.push(key_name) && inputElem.value := inputElem.value . key_name . " + "
    }else{
        if(GUI_unmute_nt && GUI_nt_modifiers.HasKey(key_name)){
            key_name:= GUI_nt_modifiers[key_name]
        }
        GUI_unmute_hotkey.push(key_name) && inputElem.value := inputElem.value . key_name . " + "
    }
}

onRecord(neutron, element_id){
    if(element_id = "mute_input"){
        GUI_mute_hotkey:= new UStack()
        hideElemID(neutron, "mute_record")
        showElemID(neutron, "mute_stop")
    }else{
        GUI_unmute_hotkey:= new UStack()
        hideElemID(neutron, "unmute_record")
        showElemID(neutron, "unmute_stop")
    }
    inputElem:= neutron.doc.getElementByID(element_id)
    inputElem.value:=""
    inputElem.placeholder:="Recording"
    GUI_input_hook:= InputHook("L0 T2.5","{Enter}{Escape}")
    GUI_input_hook.KeyOpt("{ALL}", "NI")
    GUI_input_hook.VisibleText:= false
    GUI_input_hook.VisibleNonText:= false
    GUI_input_hook.OnKeyDown:= Func("addKey").Bind(element_id)
    GUI_input_hook.OnEnd:= Func("onStop").Bind(neutron,element_id)
    GUI_input_hook.Start()
    funcObj:= Func("addKey").Bind(element_id,"",0x5, 0x0)
    Hotkey, *XButton1, % funcObj, On
    funcObj:= Func("addKey").Bind(element_id,"",0x6, 0x0)
    Hotkey, *XButton2, % funcObj, On 
}

onStop(neutron, element_id, InputHook:=""){
    if(GUI_input_hook.InProgress){
        GUI_input_hook.Stop()
        return
    }
    Hotkey, *XButton1, Off, UseErrorLevel
    Hotkey, *XButton2, Off, UseErrorLevel
    str:="", inputElem:= neutron.doc.getElementByID(element_id)
    inputElem.placeholder:="Click Record"
    if(element_id = "mute_input"){
        hideElemID(neutron, "mute_stop")
        showElemID(neutron, "mute_record")
        sanitizeHotkey(GUI_mute_hotkey,str)
    }else{
        hideElemID(neutron, "unmute_stop")
        showElemID(neutron, "unmute_record")
        sanitizeHotkey(GUI_unmute_hotkey,str)
    }
    inputElem.value:= str
}

sanitizeHotkey(ByRef hotkey_str, ByRef keys_str){
    isModifierHotkey:= 0
    ; check hotkey length
    while(hotkey_str.data.Length()>5)
        hotkey_str.pop()
    ; check modifier count
    modifierCount:= 0
    for i, value in hotkey_str.data 
        modifierCount += GUI_modifiers.HasKey(value)
    keyCount:= hotkey_str.data.Length() - modifierCount
    ; check hotkey validity
    switch modifierCount {
        case 0,1: ; (2 keys) | (1 modifier 1 key)
            while(hotkey_str.data.Length()>2)
                hotkey_str.pop()
        case 2: ; (2 modifiers) | (2 modifiers 1 key)
            if(keyCount>1)
                Goto, clearHotkey
        case 3,4: ; (3 modifiers 1 key) | (4 modifiers 1 key)
            if(keyCount!=1)
                Goto, clearHotkey
        default: ; (invalid)
            Goto, clearHotkey
    }
    ; check whether the hotkey is modifier-only
    if(modifierCount = hotkey_str.data.Length())
        isModifierHotkey:= 1
    ; append hotkey parts
    str := "", keys_str := ""
    for i, value in hotkey_str.data {
        ; if the part is a modifier and the hotkey is not a modifier-only hotkey => prepend symbol
        ; else => append the part
        if (GUI_modifiers.HasKey(value) && !isModifierHotkey){ 
            str :=  GUI_modifiers[value] . str
            keys_str := value . " + " . keys_str
        }else{
            str .= value . " & "
            keys_str := keys_str . value . " + "
        }
    }
    ; remove trailing " + " and " & "
    if(SubStr(str, -2) = " & ")
        str := SubStr(str,1,-3)
    keys_str := SubStr(keys_str,1,-3)
    ; add tilde to a modifier-only hotkey that uses neutral modifiers
    switch str {
        case "Shift","Alt","Control":
            str:= "~" . str
    }
    ; set hotkey var to final string
    hotkey_str:= str
    return
    clearHotkey:
    notify(neutron, "Invalid Hotkey")
    hotkey_str:= new UStack()
    keys_str:= ""
}

parseHotkeyString(str){
    finalStr:="",lastIndex:=0
    while(pos:=InStr(str, "<")){
        modifier:= SubStr(str, pos, 2)
        finalStr.= GUI_modifier_symbols.HasKey(modifier)? GUI_modifier_symbols[modifier] . " + " : ""
        str:= StrReplace(str, modifier,,, 1)
    }
    while(pos:=InStr(str, ">")){
        modifier:= SubStr(str, pos, 2)
        finalStr.= GUI_modifier_symbols.HasKey(modifier)? GUI_modifier_symbols[modifier] . " + " : ""
        str:= StrReplace(str, modifier,,, 1)
    }
    Loop, Parse, str 
    {
        if(GUI_modifier_symbols.HasKey(A_LoopField)){
            finalStr.= GUI_modifier_symbols[A_LoopField] . " + "
            lastIndex:=A_Index
        }
    }
    str := SubStr(str, lastIndex+1)
    str:= StrSplit(str, "&"," `t")
    for i,val in str {
        finalStr.= val . " + "
    }
    return SubStr(finalStr,1,-3) 
}

;------profile-handler-functions------

onCreateProfile(neutron){
    static new_profiles:=0,newProf:=""
    Try conf.getProfile("Profile" . new_profiles+1)
    catch {
        newProf:= conf.createProfile("Profile" . ++new_profiles)
        GUI_mute_hotkey:=""
        GUI_unmute_hotkey:=""
        addDefProfileOpt(newProf.ProfileName)
        addProfileTag(newProf.ProfileName)
        checkProfileTag(neutron,newProf.ProfileName)
        notify(neutron, "New profile created")
        return
    }
    ;if no error is thrown -> profile%num% already exists
    new_profiles++
    onCreateProfile(neutron)
}

onProfileSelect(neutron, event:="", p_name:=""){
    profile_name:= event? event.target.value : p_name
    current_profile:= conf.getProfile(profile_name)
    onRestoreProfile(neutron)
    onUpdateOption(neutron,"mute_passthrough")
    onUpdateOption(neutron,"mute_wildcard")
    onUpdateOption(neutron,"mute_nt")
    onUpdateOption(neutron,"unmute_passthrough")
    onUpdateOption(neutron,"mute_wildcard")
    onUpdateOption(neutron,"unmute_nt")
}

onChangeProfileName(neutron, event){
    txt:= event.target.value:= Trim(event.target.value)
    Try{
        if(txt=""){
            txt:= event.target.value:= "Profile"
        }else{
            conf.getProfile(txt)
            notify(neutron, Format("Profile '{}' already exists",txt))
            event.target.value:= current_profile.ProfileName
            return
        }
    }
    changeProfileTagName(txt)
    changeDefProfileOptName(txt)
    current_profile.ProfileName:= txt
    conf.exportConfig()
    notify(neutron, "Profile name saved")
}

onSaveProfile(neutron){
    formElem:= neutron.doc.getElementById("form")
    formData:= neutron.GetFormData(formElem)
    mute_str:="",mute_input:="",unmute_str:="",unmute_input:=""
    mute_input:= IsObject(GUI_mute_hotkey)? "" : GUI_mute_hotkey
    if(mute_input = ""){
        notify(neutron,"Hotkeys need to be setup")
        return
    }
    current_profile.Microphone:= formData.microphone
    mute_str:= GUI_mute_passthrough && !InStr(mute_input, "~")? "~":""
    mute_str.= GUI_mute_wildcard && !InStr(mute_input, "&") ? "*":""
    mute_str.= mute_input
    current_profile.MuteHotkey:= current_profile.UnmuteHotkey:= mute_str
    if(formData.hotkeyType = 1){
        unmute_input:= !IsObject(GUI_unmute_hotkey)? GUI_unmute_hotkey:""
        if(unmute_input = ""){
            notify(neutron,"Hotkeys need to be setup")
            current_profile.UnmuteHotkey:=""
            return
        }
        unmute_str:= GUI_unmute_passthrough && !InStr(unmute_input, "~")? "~":""
        unmute_str.= GUI_unmute_wildcard && !InStr(unmute_input, "&")? "*":""
        unmute_str.= unmute_input
        current_profile.UnmuteHotkey:= unmute_str
    }
    current_profile.PushToTalk:= formData.hotkeyType > 2
    current_profile.afkTimeout:= formData.afk_timeout? formData.afk_timeout : 0
    current_profile.OnscreenFeedback:= formData.on_screen_fb? 1 : 0
    current_profile.ExcludeFullscreen:= formData.on_screen_fb_excl? 1 : 0
    current_profile.SoundFeedback:= formData.sound_fb? 1 : 0
    current_profile.LinkedApp:= formData.linked_app
    conf.exportConfig()
    onRestoreProfile(neutron)
    notify(neutron,Format("Profile '{}' saved", formData.profile_name_field))
    ControlSend,, {Home}, % "ahk_id " . neutron.hWnd
}

onRestoreProfile(neutron, event:=""){
    innerCont:= neutron.doc.getElementById("profile")
    innerCont.classList.add("hidden")
    sleep, 100
    neutron.doc.getElementById("form").reset()
    neutron.doc.getElementById("profile_name_field").value:= current_profile.ProfileName
    fetchDeviceList(neutron)
    if(current_profile.PushToTalk)
        neutron.doc.getElementById("ptt_hotkey").checked:="true"
    else if(current_profile.MuteHotkey && current_profile.MuteHotkey = current_profile.UnmuteHotkey)
        neutron.doc.getElementById("tog_hotkey").checked:="true"
    else
        neutron.doc.getElementById("sep_hotkey").checked:="true"
    onHotkeyType(neutron)
    if(current_profile.MuteHotkey){
        str:=current_profile.MuteHotkey
        if(InStr(str, "~")){
            neutron.doc.getElementById("mute_passthrough").checked:="true"
            onUpdateOption(neutron,"mute_passthrough")
            str:= StrReplace(str, "~")
        }
        if(InStr(str, "*") || InStr(str, "&")){
            neutron.doc.getElementById("mute_wildcard").checked:="true"
            onUpdateOption(neutron,"mute_wildcard")
            str:= StrReplace(str, "*")
        }
        if(!InStr(str, ">") && !InStr(str, "<")
         && !InStr(str, "RS") && !InStr(str, "LS")
          && !InStr(str, "RC") && !InStr(str, "LC")
           && !InStr(str, "RA") && !InStr(str, "LA")){
            neutron.doc.getElementById("mute_nt").checked:="true"
        }
        onUpdateOption(neutron,"mute_nt")
        GUI_mute_hotkey:= str
        neutron.doc.getElementById("mute_input").value:= parseHotkeyString(str)
    }else{
        neutron.doc.getElementById("mute_nt").checked:="true"
    }
    if(current_profile.UnmuteHotkey){
        str:=current_profile.UnmuteHotkey
        if(InStr(str, "~")){
            neutron.doc.getElementById("unmute_passthrough").checked:="true"
            onUpdateOption(neutron,"unmute_passthrough")
            str:= StrReplace(str, "~")
        }
        if(InStr(str, "*")){
            neutron.doc.getElementById("unmute_wildcard").checked:="true"
            onUpdateOption(neutron,"mute_wildcard")
            str:= StrReplace(str, "*")
        }
        if(!InStr(str, ">") && !InStr(str, "<")
         && !InStr(str, "RS") && !InStr(str, "LS")
          && !InStr(str, "RC") && !InStr(str, "LC")
           && !InStr(str, "RA") && !InStr(str, "LA")){
            neutron.doc.getElementById("unmute_nt").checked:="true"
        }
        onUpdateOption(neutron,"unmute_nt")
        GUI_unmute_hotkey:= str
        neutron.doc.getElementById("unmute_input").value:= parseHotkeyString(str)
    }else{
        neutron.doc.getElementById("unmute_nt").checked:="true"
    }
    if (current_profile.SoundFeedback)
        neutron.doc.getElementByID("sound_fb").checked:= "true"
    if (current_profile.OnscreenFeedback)
        neutron.doc.getElementByID("on_screen_fb").checked:= "true"
    onOSDfb(neutron)
    if (current_profile.ExcludeFullscreen)
        neutron.doc.getElementByID("on_screen_fb_excl").checked:= "true"
    if (current_profile.afkTimeout)
        neutron.doc.getElementByID("afk_timeout").value:= current_profile.afkTimeout
    if (current_profile.linkedApp)
        neutron.doc.getElementByID("linked_app").value:= current_profile.linkedApp
    innerCont.classList.remove("hidden")
}

onDeleteProfile(neutron){
    prfName:= current_profile.ProfileName
    Try conf.deleteProfile(prfName)
    Catch {
        notify(neutron, "Can't delete default profile")
        return
    }
    removeProfileTag(prfName)
    removeDefProfileOpt(prfName)
    checkProfileTag(neutron,conf.DefaultProfile)
    notify(neutron,Format("Profile '{}' deleted",prfName))
    ControlSend,, {Home}, % "ahk_id " . neutron.hWnd
}

addProfileTag(profile_name){
    profileTag:= Format(GUI_profile_tag_template,profile_name)
    profiles:= neutron.doc.getElementByID("profiles")
    profiles.insertAdjacentHTML("beforeend",profileTag)
}

removeProfileTag(profile_name){
    profileTag:= neutron.doc.getElementByID("tag_profile_" . profile_name)
    profiles:= neutron.doc.getElementByID("profiles")
    profiles.removeChild(profileTag)
}

checkProfileTag(neutron,profile_name){
    neutron.doc.getElementByID("profile_" . profile_name).checked:=1
    onProfileSelect(neutron,,profile_name)
}

changeProfileTagName(profile_name){
    origProfName:= current_profile.ProfileName
    profTag:= neutron.doc.getElementByID("tag_profile_" . origProfName)
    profTag.id:= "tag_profile_" . profile_name
    profTag.setAttribute("onclick", Format("ahk.checkProfileTag('{}')", profile_name))
    profTag.firstElementChild.firstElementChild.value:= profile_name
    profTag.firstElementChild.firstElementChild.id:= "profile_" . profile_name
    profTag.firstElementChild.lastElementChild.innerText:= profile_name
}

addDefProfileOpt(profile_name, pre_selected:=0){
    defProfileSelect:= neutron.doc.getElementById("def_profile")
    profOption:= neutron.doc.createElement("option")
    profOption.value:= profile_name
    profOption.id:= "def_profile_" . profile_name
    profOption.innerText:= profile_name
    if(pre_selected)
        profOption.selected:=1
    defProfileSelect.appendChild(profOption)
}

removeDefProfileOpt(profile_name){
    defProfileSelect:= neutron.doc.getElementById("def_profile")
    profOption:= neutron.doc.getElementById("def_profile_" . profile_name)
    defProfileSelect.removeChild(profOption)
}

changeDefProfileOptName(profile_name){
    origProfName:= current_profile.ProfileName
    if(conf.DefaultProfile = origProfName)
        conf.DefaultProfile:= profile_name    
    profOption:= neutron.doc.getElementById("def_profile_" . origProfName)
    profOption.value:= profile_name
    profOption.id:= "def_profile_" . profile_name
    profOption.innerText:= profile_name
}

onChangeDefault(neutron){
    defProfileSelect:= neutron.doc.getElementById("def_profile")
    conf.DefaultProfile:= defProfileSelect.value
    conf.exportConfig()
    notify(neutron, "Default profile saved")
}

;------options-handler-functions------

onUpdateOption(neutron, event){
    targetElem:= IsObject(event)? event.target : neutron.doc.getElementById(event)
    varName:= targetElem.id
    GUI_%varName%:= targetElem.checked ? 1 : 0
}

onHotkeyType(neutron){
    u_box:= neutron.doc.getElementById("unmute_box")
    afk_row:= neutron.doc.getElementById("afk_timeout_row")
    if(neutron.doc.getElementByID("sep_hotkey").checked){
        u_box.classList.remove("box-hidden")
        afk_row.classList.remove("row-hidden")
        neutron.doc.getElementByID("mute_label").innerText:= "Mute hotkey"
    }
    if(neutron.doc.getElementByID("tog_hotkey").checked){
        u_box.classList.add("box-hidden")
        afk_row.classList.remove("row-hidden")
        neutron.doc.getElementByID("mute_label").innerText:= "Toggle hotkey"
    }
    if(neutron.doc.getElementByID("ptt_hotkey").checked){
        u_box.classList.add("box-hidden")
        afk_row.classList.add("row-hidden")
        neutron.doc.getElementByID("mute_label").innerText:= "Push-to-talk hotkey"
    }
}

onOSDfb(neutron){
    tag:= neutron.doc.getElementByID("os_fb_excl_tag")
    if(neutron.doc.getElementByID("on_screen_fb").checked){
        tag.classList.remove("hidden")
    }else{
        tag.classList.add("hidden")
    }
}

onSelectApp(neutron){
    FileSelectFile, fileName, 3,, Select an application - MicMute, Application (*.exe)
    SplitPath, fileName, fileName,, fileExt
    linkedAppField:=neutron.doc.getElementById("linked_app")
    if(fileName){
        linkedAppField.value:= fileName
        if(fileExt!= "exe")
            linkedAppField.value:=""
    }else{
        linkedAppField.value:=""
    }
}

onclickFooter(neutron){
    Run, https://github.com/SaifAqqad/AHK_MicMute
}

;------elements-functions------

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
    nt_labels:= neutron.qsa(".nt-label")
    afk_label:= neutron.qs(".afk-label")
    for i, label in neutron.Each(pt_labels)
        label.setAttribute("data-title", GUI_passthrough_tt)
    for i, label in neutron.Each(wc_labels)
        label.setAttribute("data-title", GUI_wildcard_tt)
    for i, label in neutron.Each(nt_labels)
        label.setAttribute("data-title", GUI_nt_tt)
    afk_label.setAttribute("data-title", GUI_afk_tt)
}

notify(neutron, txt){
    notif:= neutron.doc.getElementById("notification")
    notif.firstElementChild.innerText:= txt
    notif.classList.remove("hidden")
    SetTimer, dismissNotif, -1200
}

dismissNotif(){
    notif:= neutron.doc.getElementById("notification")
    notif.classList.add("hidden")
}
