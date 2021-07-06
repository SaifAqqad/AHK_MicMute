global ui_obj, about_obj, current_profile, hotkey_panels, current_hp
, onExitCallback, UI_scale:= A_ScreenDPI/96
, input_hook, input_hook_timer, key_set, modifier_set, is_multiple_mics:=0
, template_link:= "<link rel='stylesheet' id='css_{1:}' href='{2:}'>"
, template_default_profile:= "<option value='{1:}' {2:} >{1:}</option>"
, template_mic:= "<option value='{1:}' id='mic_{1:}' {2:} >{1:}</option>"
, template_profile_tag:= "
(
    <div class=""tag is-large"" id=""tag_profile_{1:}"" oncontextmenu=""ahk.UI_displayProfileRename('{1:}')"" onClick=""ahk.UI_setProfile('{1:}')"">
        <label class=""radio"">
            <input type=""radio"" name=""profiles_radio"" value=""{1:}"" id=""profile_{1:}"" disabled>
            <span data-title=""Right click to edit profile name"" >{1:}</span>
        </label>
    </div>
)"
, UI_tooltips:= [ { selector: ".passthrough-label"
                     , string: "The hotkey's keystrokes won't be hidden from the OS"}
                  ,{ selector: ".wildcard-label"
                     , string: "Fire the hotkey even if extra modifiers are held down"}
                  ,{ selector: ".nt-label"
                     , string: "Use neutral modifiers (i.e. Alt instead of Left Alt / Right Alt)"}
                  ,{ selector: ".ptt-delay-label"
                     , string: "Delay between releasing the key and the audio cutting off"}
                  ,{ selector: ".afk-label"
                     , string: "Mute the microphone when idling for a length of time"}
                  ,{ selector: ".ExcludeFullscreen-label"
                     , string: "Don't show the OSD if the active app/game is fullscreen"}
                  ,{ selector: ".SwitchProfileOSD-label"
                     , string: "Show an OSD when switching between profiles"}
                  ,{ selector: ".SoundFeedback-label"
                     , string: "Play a sound when muting or unmuting the microphone"}
                  ,{ selector: ".OnscreenFeedback-label"
                     , string: "Show an OSD when muting or unmuting the microphone"}
                  ,{ selector: ".OnscreenOverlay-label"
                     , string: "Show the microphone's state in an always-on-top overlay"}
                  ,{ selector: ".OverlayOnMuteOnly-label"
                     , string: "Only show the overlay when the microphone is muted"}
                  ,{ selector: ".multiple-mics-label"
                     , string: "Setup hotkeys for multiple microphones simultaneously"}]

UI_create(p_onExitCallback){
    features:= {"FEATURE_GPU_RENDERING": 0x1
            ,"FEATURE_BROWSER_EMULATION": 0x2AF8
            ,"FEATURE_96DPI_PIXEL": 0x1}
    UI_enableIeFeatures(features)
    ui_obj:= new NeutronWindow()
    ui_obj.load(resources_obj.htmlFile.UI)
    UI_enableIeFeatures(features,1)
    UI_loadCss(ui_obj)
    onExitCallback:= p_onExitCallback
    UI_createAbout()
}

UI_Show(p_profile){
    Thread, NoTimers
    ;@Ahk2Exe-IgnoreBegin
    OutputDebug, % "Showing config UI`n"
    ;@Ahk2Exe-IgnoreEnd
    updateSysTheme()
    UI_reset()
    UI_setProfile("", p_profile)
    UI_addTooltips()
    updateSysTheme()
    tray_defaults()
    ui_obj.Gui(Format("+LabelUI_ +MinSize{:i}x{:i}",700*UI_scale,440*UI_scale))
    ui_obj.Show(Format("Center w{:i} h{:i}",830*UI_scale,650*UI_scale),"MicMute")
}

UI_enableIeFeatures(f_obj, delete:=0){
    static reg_dir:= "SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\"
         , executable:= A_IsCompiled? A_ScriptName : util_splitPath(A_AhkPath).fileName
    for feature, value in f_obj
        if(!delete)
            RegWrite, REG_DWORD, % "HKCU\" reg_dir feature, % executable, % value
        else
            RegDelete, % "HKCU\" reg_dir feature, % executable

}

UI_setProfile(neutron, p_profile){
    current_profile:= config_obj.getProfile(p_profile)
    ui_obj.doc.getElementById("profile_" p_profile).checked:= 1
    innerCont:= ui_obj.doc.getElementById("profile")
    innerCont.classList.add("hidden")
    sleep, 200
    hotkey_panels:= {}
    for i, mic in current_profile.Microphone {
        if(mic.Name = "capture" || !ui_obj.doc.getElementById("mic_" mic.Name))
            mic.Name:= "Default"
        hType:= mic.MuteHotkey == mic.UnmuteHotkey? (mic.PushToTalk? 2 : 1) : 0
        hotkey_panels[mic.Name]:= new HotkeyPanel(mic.MuteHotkey,mic.UnmuteHotkey,htype)
    }
    ui_obj.doc.getElementById("multiple_mics").checked:= is_multiple_mics:= current_profile.Microphone.Length()>1
    UI_onToggleMultiple("")
    ui_obj.doc.getElementById("profile_name_field").value:= current_profile.ProfileName
    ui_obj.doc.getElementById("microphone").value:= current_profile.Microphone[1].Name
    UI_setHotkeyPanel(hotkey_panels[current_profile.Microphone[1].Name])
    ui_obj.doc.getElementById("SoundFeedback").checked:= current_profile.SoundFeedback
    ui_obj.doc.getElementById("OnscreenFeedback").checked:= current_profile.OnscreenFeedback
    ui_obj.doc.getElementById("OnscreenOverlay").checked:= current_profile.OnscreenOverlay
    ui_obj.doc.getElementById("OverlayOnMuteOnly").checked:= current_profile.OverlayOnMuteOnly
    ui_obj.doc.getElementById("ExcludeFullscreen").checked:= current_profile.ExcludeFullscreen
    UI_onOSDToggle("")
    UI_onOverlayToggle("")
    ui_obj.doc.getElementById("OSDPos_x").value:= current_profile.OSDPos.x==-1? "" : current_profile.OSDPos.x
    ui_obj.doc.getElementById("OSDPos_y").value:= current_profile.OSDPos.y==-1? "" : current_profile.OSDPos.y
    ui_obj.doc.getElementById("LinkedApp").value:= current_profile.LinkedApp
    ui_obj.doc.getElementById("afkTimeout").value:= !current_profile.afkTimeout? "" : current_profile.afkTimeout
    ui_obj.doc.getElementById("PTTDelay").value:= current_profile.PTTDelay
    UI_onUpdateDelay("",current_profile.PTTDelay)
    innerCont.classList.remove("hidden")
}

UI_reset(){
    UI_resetMicSelect()
    profiles:= ui_obj.doc.getElementById("profiles")
    defaultProfile:= ui_obj.doc.getElementById("default_profile")
    profiles.innerHTML:=""
    defaultProfile.innerHTML:=""
    for i, profile in config_obj.Profiles {
        profiles.insertAdjacentHTML("beforeend",Format(template_profile_tag,profile.ProfileName))
        selected:= profile.ProfileName == config_obj.DefaultProfile? "selected" : ""
        defaultProfile.insertAdjacentHTML("beforeend",Format(template_default_profile, profile.ProfileName, selected))
    }
    config_obj.DefaultProfile:= ui_obj.doc.getElementById("default_profile").value
    if(config_obj.MuteOnStartup)
        ui_obj.doc.getElementById("MuteOnStartup").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("MuteOnStartup").removeAttribute("checked")
    if(config_obj.UseCustomSounds)
        ui_obj.doc.getElementById("UseCustomSounds").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("UseCustomSounds").removeAttribute("checked")
    if(config_obj.SwitchProfileOSD)
        ui_obj.doc.getElementById("SwitchProfileOSD").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("SwitchProfileOSD").removeAttribute("checked")
    ui_obj.doc.getElementById("PreferTheme").value:= config_obj.PreferTheme
}

UI_resetMicSelect(){
    select:= ui_obj.doc.getElementById("microphone")
    select.innerHTML:=""
    select.insertAdjacentHTML("beforeend", Format(template_mic, "Default", "selected"))
    devices:= VA_GetCaptureDeviceList()
    for i, device in devices {
        select.insertAdjacentHTML("beforeend", Format(template_mic, device,""))
    }
}

UI_setHotkeyPanel(hotkey_panel, delay:=0){
    innerCont:= ui_obj.doc.getElementById("hotkeys_panel")
    innerCont.classList.add("hidden")
    if(delay)
        sleep, %delay%
    current_hp:= hotkey_panel
    ; hotkey type
    ui_obj.doc.getElementById("hktype_" . current_hp.hotkeyType).checked:=1
    UI_onHotkeyType("",current_hp.hotkeyType)
    ; mute panel
    ui_obj.doc.getElementById("mute_input").value:= current_hp.mute.hotkey_h
    ui_obj.doc.getElementById("mute_wildcard").checked:= current_hp.mute.wildcard
    ui_obj.doc.getElementById("mute_passthrough").checked:= current_hp.mute.passthrough
    ui_obj.doc.getElementById("mute_nt").checked:= current_hp.mute.nt
    ; unmute panel
    ui_obj.doc.getElementById("unmute_input").value:= current_hp.unmute.hotkey_h
    ui_obj.doc.getElementById("unmute_wildcard").checked:= current_hp.unmute.wildcard
    ui_obj.doc.getElementById("unmute_passthrough").checked:= current_hp.unmute.passthrough
    ui_obj.doc.getElementById("unmute_nt").checked:= current_hp.unmute.nt
    innerCont.classList.remove("hidden")
    UI_checkMicOptions()
}

UI_updateHotkeyOption(neutron, option){
    elem:= ui_obj.doc.getElementById(option)
    option:= StrSplit(option, "_")
    current_hp.updateOption(option[1], option[2], elem.checked? 1 : 0)
    ;@Ahk2Exe-IgnoreBegin
    OutputDebug, % Format("{} hotkey set to: {}`n", option[1], current_hp[option[1]].hotkey)
    ;@Ahk2Exe-IgnoreEnd
}

UI_onSaveProfile(neutron){
    current_profile.SoundFeedback:= ui_obj.doc.getElementById("SoundFeedback").checked? 1 : 0
    current_profile.OnscreenFeedback:= ui_obj.doc.getElementById("OnscreenFeedback").checked? 1 : 0
    current_profile.OnscreenOverlay:= ui_obj.doc.getElementById("OnscreenOverlay").checked? 1 : 0
    current_profile.ExcludeFullscreen:= ui_obj.doc.getElementById("ExcludeFullscreen").checked? 1 : 0
    current_profile.OverlayOnMuteOnly:= ui_obj.doc.getElementById("OverlayOnMuteOnly").checked? 1 : 0
    current_profile.afkTimeout:= (val:= ui_obj.doc.getElementById("afkTimeout").value)? val+0 : 0
    current_profile.LinkedApp:= ui_obj.doc.getElementById("LinkedApp").value
    current_profile.PTTDelay:= ui_obj.doc.getElementById("PTTDelay").value+0
    current_profile.OSDPos.x:= (val:= ui_obj.doc.getElementById("OSDPos_x").value)? val : -1
    current_profile.OSDPos.y:= (val:= ui_obj.doc.getElementById("OSDPos_y").value)? val : -1
    current_profile.Microphone:= Array()
    for mic, hp in hotkey_panels {
        if(!hp.mute.hotkey && !hp.unmute.hotkey)
            Continue
        if(hp.hotkeyType)
            hp.unmute:= hp.mute
        if(!hp.isTypeValid())
            Continue
        current_profile.Microphone.Push({ Name: mic
                                        , MuteHotkey: hp.mute.hotkey
                                        , UnmuteHotkey: hp.unmute.hotkey
                                        , PushToTalk: (hp.hotkeyType = 2? 1 : 0) })
    }
    if(!current_profile.Microphone.Length()){
        current_profile.Microphone.Push({ Name: "Default"
                                        , MuteHotkey: ""
                                        , UnmuteHotkey: ""
                                        , PushToTalk: 0 })    
    }
    config_obj.exportConfig()
    UI_reset()
    UI_setProfile(neutron, current_profile.ProfileName)
    neutron.doc.getElementById("top").scrollIntoView()
    UI_notify("Profile saved")   
}

UI_onDeleteProfile(neutron){
    if(current_profile.ProfileName == config_obj.DefaultProfile){
        UI_notify("Default profile cannot be deleted")
        return
    }
    config_obj.deleteProfile(current_profile.ProfileName)
    UI_reset()
    UI_setProfile(neutron, config_obj.DefaultProfile)
    neutron.doc.getElementById("top").scrollIntoView()
    UI_notify("Profile deleted")
}

UI_onCreateProfile(neutron){
    static profileIndex:= 0
    if(!profileIndex)
        profileIndex:= config_obj.Profiles.Length()+1
    Try config_obj.getProfile("Profile " . profileIndex)
    catch {
        newProf:= config_obj.createProfile("Profile " . profileIndex)
        UI_reset()
        UI_setProfile(neutron, "Profile " . profileIndex++)
        UI_notify("Profile created")
        return
    }
    ;if no error is thrown -> Profile %num% already exists
    profileIndex++
    UI_onCreateProfile(neutron)
}

UI_onRecord(neutron, type){
    ;stop any other input hook
    if(input_hook.InProgress){
        input_hook.Stop()
        sleep, 30
    }
    ;reset hotkey stackset
    key_set:= new StackSet()
    modifier_set:= new StackSet()
    ;hide record button and show stop button
    UI_hideElemID(neutron, type . "_record")
    UI_showElemID(neutron, type . "_stop")
    ;setup stop button timer
    input_hook_timer:= Func("UI_updateStopTimer").Bind(type . "_stop")
    input_hook_timer.Call()
    SetTimer, % input_hook_timer, 1000
    ;reset textbox content
    inputElem:= ui_obj.doc.getElementByID(type . "_input")
    inputElem.value:=""
    inputElem.placeholder:="Recording"
    ;setup a new input hook 
    input_hook:= InputHook("L0 T3","{Enter}{Escape}")
    input_hook.KeyOpt("{ALL}", "NI")
    input_hook.VisibleText:= false
    input_hook.VisibleNonText:= false
    input_hook.OnKeyDown:= Func("UI_addKey").Bind(type)
    input_hook.OnEnd:= Func("UI_onStop").Bind(neutron,type)
    input_hook.Start()
    ;setup workaround for mouse back and forward buttons
    funcObj:= Func("UI_addKey").Bind(type,"",0x5, 0x0)
    Hotkey, *XButton1, % funcObj, On UseErrorLevel
    funcObj:= Func("UI_addKey").Bind(type,"",0x6, 0x0)
    Hotkey, *XButton2, % funcObj, On UseErrorLevel
}

UI_addKey(type, InputHook, VK, SC){
    key_name:= GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    , inputElem:= ui_obj.doc.getElementByID(type "_input")
    , unq:=""
    if(StrLen(key_name) == 1)
        key_name:= Format("{:U}", key_name)
    key_name:= current_hp[type].nt? current_hp.modifierToNeutral(key_name) : key_name
    if(current_hp.isModifier(key_name))
        unq:= modifier_set.push(key_name)
    else
        unq:= key_set.push(key_name)

    if(unq)
        inputElem.value := inputElem.value . key_name . " + "
}

UI_onStop(neutron, type, InputHook:=""){
    ;if the func is not called by the input hook -> stop the input hook
    if(input_hook.InProgress){
        input_hook.Stop()
        return
    }
    inputElem:= ui_obj.doc.getElementByID(type "_input")
    stopElem:= ui_obj.doc.getElementById(type "_stop").firstElementChild
    hp:= current_hp[type]
    tempSet:= new StackSet()

    inputElem.placeholder:="Click Record"
    stopElem.value:= 3
    stopElem.innerText:="Stop"

    SetTimer, % input_hook_timer, Off
    UI_hideElemID(neutron,type "_stop")
    UI_showElemID(neutron,type "_record")
    ;turn off the extra hotkeys for mouse buttons workaround
    Hotkey, *XButton1, Off, UseErrorLevel
    Hotkey, *XButton2, Off, UseErrorLevel

    loop % modifier_set.data.Length()
        tempSet.push(modifier_set.dequeue())
    loop % key_set.data.Length()
        tempSet.push(key_set.dequeue())
    try current_hp.setFromKeySet(type, tempSet, hp.wildcard, hp.passthrough, hp.nt)
    catch err{
        UI_notify(err)
        hp.hotkey:= hp.hotkey_h:= ""
    }
    UI_setHotkeyPanel(current_hp)

    ;@Ahk2Exe-IgnoreBegin
    OutputDebug, % Format("{} hotkey set to: {}`n", type, current_hp[type].hotkey)
    ;@Ahk2Exe-IgnoreEnd
}

UI_onClearHotkey(neutron){
    mic:= ui_obj.doc.getElementById("microphone").value
    hotkey_panels[mic]:= new HotkeyPanel("","",1)
    UI_setHotkeyPanel(hotkey_panels[mic], 200)
}

UI_onRefreshDeviceList(neutron){
    UI_resetMicSelect()
    UI_checkMicOptions()
    if(current_profile.Microphone[1].Name)
        ui_obj.doc.getElementById("microphone").value:= current_profile.Microphone[1].Name
    UI_onSetMicrophone("",ui_obj.doc.getElementById("microphone").value)
}

UI_checkMicOptions(){
    devices:= VA_GetCaptureDeviceList(), numPanels:=0
    devices.Push("Default")
    for i, device in devices {
        micOption:= ui_obj.doc.getElementById("mic_" device)
        if(hotkey_panels[device].mute.hotkey_h){
            micOption.innerText:= (InStr(micOption.innerText, "*")? "" : "* ") . micOption.innerText
            numPanels++
        }else{
            micOption.innerText:= StrReplace(micOption.innerText, "* ")
        }
    }
}

UI_onUpdateDelay(neutron,delay){
    ui_obj.doc.getElementByID("PTTDelay_text").value:= delay . " ms"
}

UI_onOSDToggle(neutron){
    excl_tag:= ui_obj.doc.getElementByID("ExcludeFullscreen_tag")
    pos_row:= ui_obj.doc.getElementByID("OSDPos_group")
    if(ui_obj.doc.getElementByID("OnscreenFeedback").checked){
        excl_tag.classList.remove("hidden")
        pos_row.classList.remove("row-hidden")
    }else{
        excl_tag.classList.add("hidden")
        pos_row.classList.add("row-hidden")
    }
}

UI_onOverlayToggle(neutron){
    excl_tag:= ui_obj.doc.getElementByID("OverlayOnMuteOnly_tag")
    pos_row:= ui_obj.doc.getElementByID("overlay_group")
    if(ui_obj.doc.getElementByID("OnscreenOverlay").checked){
        excl_tag.classList.remove("hidden")
        pos_row.classList.remove("row-hidden")
    }else{
        excl_tag.classList.add("hidden")
        pos_row.classList.add("row-hidden")
    }
}

UI_onHotkeyType(neutron, type, delay:=0){
    static hideElemFunc:= Func("UI_hideElemID").Bind("", "unmute_box")
    innerCont:= neutron.doc.getElementById("hotkey_panels_group")
    innerCont.classList.add("hidden")
    if(delay)
        sleep, %delay%
    u_box:= ui_obj.doc.getElementById("unmute_box")
    afk_row:= ui_obj.doc.getElementById("afkTimeout_group")
    delay_row:= ui_obj.doc.getElementById("PTTDelay_group")
    current_hp.hotkeyType:= type
    if(type == 0){
        u_box.classList.remove("is-hidden")
        u_box.classList.remove("box-hidden")
        afk_row.classList.remove("is-hidden")
        delay_row.classList.add("is-hidden")
        ui_obj.doc.getElementByID("mute_label").innerText:= "Mute hotkey"
    }
    if(type == 1){
        u_box.classList.add("box-hidden")
        afk_row.classList.remove("is-hidden")
        delay_row.classList.add("is-hidden")
        ui_obj.doc.getElementByID("mute_label").innerText:= "Toggle hotkey"
        SetTimer, % hideElemFunc, -100
    }
    if(type == 2){
        u_box.classList.add("box-hidden")
        afk_row.classList.add("is-hidden")
        delay_row.classList.remove("is-hidden")
        ui_obj.doc.getElementByID("mute_label").innerText:= "Push-to-talk hotkey"
        SetTimer, % hideElemFunc, -100
    }
    if(delay)
        Sleep, 40
    innerCont.classList.remove("hidden")
}

UI_onSetMicrophone(neutron, mic_name){
    ui_obj.doc.getElementById("hotkeys_panel").classList.add("hidden")
    func:= Func("UI_asyncOnSetMicrophone").Bind(mic_name)
    SetTimer, % func, -200
}

UI_asyncOnSetMicrophone(mic_name){
    if(!hotkey_panels[mic_name]){
        hotkey_panels[mic_name]:= new HotkeyPanel("","",1)
    }
    if(is_multiple_mics){
        UI_setHotkeyPanel(hotkey_panels[mic_name])        
    }else{
        hotkey_panels:= {}
        hotkey_panels[mic_name]:= current_hp
        UI_setHotkeyPanel(hotkey_panels[mic_name]) 
    }
    ui_obj.doc.getElementById("hotkeys_panel").classList.remove("hidden")
}

UI_onGlobalOption(neutron, option, setState){
    elem:= ui_obj.doc.getElementById(option)
    if(setState)
        elem.checked:= !elem.checked
    config_obj[option]:= elem.checked? 1 : 0
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_onSelectApp(neutron){
    FileSelectFile, _f, 3,, Select an application - MicMute, Application (*.exe)
    _f:= util_splitPath(_f)
    linkedAppField:= ui_obj.doc.getElementById("LinkedApp")
    if(_f.fileName && _f.fileExt == "exe")
        linkedAppField.value:= _f.fileName
    else
        linkedAppField.value:=""
}

UI_onOSDset(neutron){
    pox_x:= ui_obj.doc.getElementByID("OSDPos_x")
    pox_y:= ui_obj.doc.getElementByID("OSDPos_y")
    MsgBox, 65, MicMute, Click OK then drag the OSD to the `nwanted position and right click it`nor click Cancel to reset.
    IfMsgBox, Cancel
        Goto, _reset
    ui_obj.Minimize()
    editor_osd:= new OSD(current_profile.OSDPos,,Func("UI_onConfirmOSDPos"))
    editor_osd.setTheme(ui_theme)
    editor_osd.showPosEditor()
    return
    _reset:
        pox_x.value:=""
        pox_y.value:=""
    return
}

UI_onConfirmOSDPos(x,y){
    ui_obj.doc.getElementByID("OSDPos_x").value:= x
    ui_obj.doc.getElementByID("OSDPos_y").value:= y
    Gui, % ui_obj.hWnd ":Restore"
}

UI_onChangeProfileName(neutron, event){
    str:= event.target.value:= StrReplace(Trim(event.target.value), "\")
    Try{
        if(!str || str == current_profile.ProfileName){
            event.target.value:= current_profile.ProfileName
            return
        }else{
            config_obj.getProfile(str) ;if this fails then str is unique, otherwise user gets notified
            UI_notify(Format("Profile '{}' already exists",str))
            event.target.value:= current_profile.ProfileName ; reset changes
            return
        }
    }
    if(current_profile.ProfileName == config_obj.DefaultProfile){
        config_obj.DefaultProfile:= str
    }
    current_profile.ProfileName:= str
    ui_obj.doc.getElementById("profile").classList.add("hidden")
    Sleep, 100
    config_obj.exportConfig()
    UI_reset()
    UI_setProfile(neutron,str)
    UI_notify("Profile name saved")
}

UI_onToggleMultiple(neutron){
    is_multiple_mics:= ui_obj.doc.getElementById("multiple_mics").checked
    if(is_multiple_mics){
        ui_obj.doc.getElementById("OnscreenOverlay_tag").classList.add("hidden")
        ui_obj.doc.getElementById("OverlayOnMuteOnly_tag").classList.add("hidden")
        ui_obj.doc.getElementById("overlay_group").classList.add("row-hidden")
    }else{
        ui_obj.doc.getElementById("OnscreenOverlay_tag").classList.remove("hidden")
        ui_obj.doc.getElementById("OverlayOnMuteOnly_tag").classList.remove("hidden")
        ui_obj.doc.getElementById("overlay_group").classList.remove("row-hidden")
        UI_onOverlayToggle(neutron)
        if(hotkey_panels.Count()>1)
            for mic, panel in hotkey_panels
                if(panel!= current_hp)
                    hotkey_panels.Delete(mic)
    }
    UI_checkMicOptions()
}

UI_updateStopTimer(id){
    buttonElem:= ui_obj.doc.getElementById(id).firstElementChild
    buttonElem.innerText:= Format("Stop ({})", buttonElem.value)
    buttonElem.value := buttonElem.value - 1
    if(buttonElem.value = 0){
        Try SetTimer,, Off
        buttonElem.value := 3
    }

}

UI_clearLinkedApp(neutron,event){
    switch event.keyCode {
        case 0x2E,0x08 :
            ui_obj.doc.getElementById("LinkedApp").value:=""
    }
}

UI_displayProfileRename(neutron, p_profile){
    if(current_profile.ProfileName != p_profile)
        UI_setProfile(neutron,p_profile)
    ui_obj.doc.getElementById("page_mask").classList.remove("hidden")
    ui_obj.doc.getElementById("profile_name").classList.remove("hidden")
    field:= ui_obj.doc.getElementById("profile_name_field")
    field.focus()
    field.setSelectionRange(ln:=StrLen(field.value),ln)
}

UI_hideProfileRename(neutron, event:=""){
    maskElem:= ui_obj.doc.getElementById("page_mask")
    pElem:= ui_obj.doc.getElementById("profile_name")
    if(!event){
        maskElem.classList.add("hidden")
        pElem.classList.add("hidden")
        return
    }
    switch event.keyCode {
        case 0x1B,0x0D:
            pElem.firstElementChild.blur()
            maskElem.classList.add("hidden")
            pElem.classList.add("hidden")
    }
}

UI_updateThemeOption(neutron:=""){
    config_obj.PreferTheme:= ui_obj.doc.getElementById("PreferTheme").value+0
    updateSysTheme()
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_updateDefaultProfile(neutron){
    config_obj.DefaultProfile:= ui_obj.doc.getElementById("default_profile").value
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_loadCss(neutron){
    neutron.doc.getElementById("MicMute_icon").setAttribute("src", resources_obj.pngIcon)
    for i, css in resources_obj.cssFile {
        if(!neutron.doc.getElementById("css_" css.name))
            neutron.doc.head.insertAdjacentHTML("beforeend",Format(template_link, css.name, css.file))
    }
}

UI_addTooltips(){
    for i,tt in UI_tooltips {
        elemList:= ui_obj.qsa(tt.selector)
        for i, element in ui_obj.Each(elemList)
            element.setAttribute("data-title",tt.string)
    }
}

UI_hideElemID(neutron, elemId){
    elem:= ui_obj.doc.getElementByID(elemId)
    elem.classList.add("is-hidden")
}

UI_showElemID(neutron, elemId){
    elem:= ui_obj.doc.getElementByID(elemId)
    elem.classList.remove("is-hidden")
}

UI_notify(txt){
    notif:= ui_obj.doc.getElementById("notification")
    notif.firstElementChild.innerText:= txt
    notif.classList.remove("hidden")
    SetTimer, UI_dismissNotif, -1200
}

UI_dismissNotif(){
    notif:= ui_obj.doc.getElementById("notification")
    notif.classList.add("hidden")
}

UI_close(neutron:=""){
    ui_obj.Hide()
    onExitCallback.Call(current_profile.ProfileName)
    ui_obj.Close()
}

UI_updateTheme(){
    if(ui_theme){
        ui_obj.doc.getElementById("css_dark").removeAttribute("disabled")
        about_obj.doc.getElementById("css_dark").removeAttribute("disabled")
    }
    else{
        ui_obj.doc.getElementById("css_dark").setAttribute("disabled","1")
        about_obj.doc.getElementById("css_dark").setAttribute("disabled","1")
    }
}

UI_createAbout(){
    about_obj:= new NeutronWindow()
    about_obj.load(resources_obj.htmlFile.about)
    about_obj.doc.getElementById("version").innerText:= A_Version
    UI_loadCss(about_obj)
    about_obj.Gui("-Resize")
}

UI_showAbout(neutron:=""){
    tray_defaults()
    updateSysTheme()
    about_obj.show(Format("Center w{:i} h{:i}",500*UI_scale,300*UI_scale),"About MicMute")
}

UI_exitAbout(neutron){
    about_obj.Close()
    about_obj.Destroy()
    UI_createAbout()
}

UI_launchURL(neutron:="", url:=""){
    Run, %url%, %A_Desktop%
}
