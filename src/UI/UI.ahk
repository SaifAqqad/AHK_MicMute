global ui_obj, about_obj, current_profile, hotkey_panels, current_hp
, onExitCallback, UI_scale:= A_ScreenDPI/96
, template_link:= "<link rel='stylesheet' id='css_{1:}' href='{2:}'>"
, template_default_profile:= "<option value='{1:}' {2:} >{1:}</option>"
, template_mic:= "<option value='{1:}' {2:} >{1:}</option>"
, template_profile_tag:= "
(
    <div class=""tag is-large"" id=""tag_profile_{1:}"" oncontextmenu=""ahk.displayProfileRename('{1:}')"" onClick=""ahk.UI_setProfile('{1:}')"">
        <label class=""radio"">
            <input type=""radio"" name=""profiles_radio"" value=""{1:}"" id=""profile_{1:}"">
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
                     , string: "Auto mute the microphone when idling for a length of time"}
                  ,{ selector: ".ExcludeFullscreen-label"
                     , string: "Turn off the OSD if the active app/game is fullscreen"}
                  ,{ selector: ".SwitchProfileOSD-label"
                     , string: "Show an OSD when switching between profiles"}]

UI_create(p_onExitCallback){
    if(ui_obj)
        ui_obj.Destroy()
    UI_enableIeFeatures({"FEATURE_GPU_RENDERING": 0x1
                        ,"FEATURE_BROWSER_EMULATION": 0x2AF8
                        ,"FEATURE_96DPI_PIXEL": 0x1})
    ui_obj:= new NeutronWindow()
    ui_obj.load(resources_obj.htmlFile.UI)
    onExitCallback:= p_onExitCallback
    UI_loadCss(ui_obj)
    UI_createAbout()
}

UI_Show(p_profile){
    UI_reset()
    UI_setProfile("", p_profile)
    UI_addTooltips()
    SetTimer, UI_checkTheme, 1500
    UI_checkTheme()
    ui_obj.Gui(Format("+MinSize{:i}x{:i}",700*UI_scale,440*UI_scale))
    ui_obj.Show(Format("Center w{:i} h{:i}",830*UI_scale,650*UI_scale),"MicMute")
}

UI_enableIeFeatures(f_obj){
    static reg_dir:= "SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\"
         , executable:= A_IsCompiled? A_ScriptName : util_splitPath(A_AhkPath).fileName
    for feature, value in f_obj
        RegWrite, REG_DWORD, HKCU, % reg_dir feature, % executable, % value
}

UI_setProfile(neutron, p_profile){
    ;insert animation
    innerCont:= ui_obj.doc.getElementById("profile")
    innerCont.classList.add("hidden")
    sleep, 100
    current_profile:= config_obj.getProfile(p_profile)
    ui_obj.doc.getElementById("profile_" p_profile).checked:= 1
    hotkey_panels:= {}
    for i, mic in current_profile.Microphone {
        hType:= mic.MuteHotkey == mic.UnmuteHotkey? (mic.PushToTalk? 2 : 1) : 0
        hotkey_panels[mic.Name]:= new HotkeyPanel(mic.MuteHotkey,mic.UnmuteHotkey,htype)
    }
    ui_obj.doc.getElementById("microphone").value:= current_profile.Microphone[1].Name
    UI_setHotkeyPanel(hotkey_panels[current_profile.Microphone[1].Name])
    ui_obj.doc.getElementById("SoundFeedback").checked:= current_profile.SoundFeedback
    ui_obj.doc.getElementById("OnscreenFeedback").checked:= current_profile.OnscreenFeedback
    ui_obj.doc.getElementById("ExcludeFullscreen").checked:= current_profile.ExcludeFullscreen
    UI_onOSDToggle("")
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
        select.insertAdjacentHTML("beforeend", Format(template_mic, device, selected))
    }
}

UI_setHotkeyPanel(hotkey_panel){
    innerCont:= neutron.doc.getElementById("hotkeys_panel")
    innerCont.classList.add("hidden")
    sleep, 100
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

UI_onHotkeyType(neutron,type){
    static hideElemFunc:= Func("UI_hideElemID").Bind("", "unmute_box")
    innerCont:= neutron.doc.getElementById("hotkey_panels_group")
    innerCont.classList.add("hidden")
    sleep, 120
    u_box:= ui_obj.doc.getElementById("unmute_box")
    afk_row:= ui_obj.doc.getElementById("afkTimeout_group")
    delay_row:= ui_obj.doc.getElementById("PTTDelay_group")
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
    Sleep, 40
    innerCont.classList.remove("hidden")
}

UI_onSetMicrophone(neutron){
    mic_name:= ui_obj.doc.getElementById("microphone").value
    panel:= hotkey_panels[mic_name]
    if(panel){
        UI_setHotkeyPanel(panel)
    }else{ ;new panel

    }
}

UI_onGlobalOption(neutron, option, setState){
    elem:= ui_obj.doc.getElementById(option)
    if(setState)
        elem.checked:= !elem.checked
    config_obj[option]:= elem.checked? 1 : 0
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_updateThemeOption(neutron:=""){
    config_obj.PreferTheme:= ui_obj.doc.getElementById("PreferTheme").value+0
    UI_checkTheme()
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_updateDefaultProfile(neutron){
    config_obj.DefaultProfile:= ui_obj.doc.getElementById("default_profile").value
    config_obj.exportConfig()
    UI_notify("Configuration saved")
}

UI_loadCss(neutron){
    for i, css in resources_obj.cssFile 
        neutron.doc.head.insertAdjacentHTML("beforeend",Format(template_link, css.name, css.file))
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

UI_exit(neutron){
    SetTimer, UI_checkTheme, Off
    onExitCallback.Call()
    ui_obj.Close()
}

UI_checkTheme(){
    UpdateSysTheme()
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
    UI_loadCss(about_obj)
    UI_checkTheme()
    about_obj.Gui("-Resize")
}

UI_showAbout(neutron:=""){
    tray_defaults()
    about_obj.show(Format("Center w{:i} h{:i}",500*UI_scale,300*UI_scale),"About MicMute")
}

UI_exitAbout(neutron){
    about_obj.Close()
}

launchURL(neutron:="", url:=""){
    Run, %url%, %A_Desktop%
}
