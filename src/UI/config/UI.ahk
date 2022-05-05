global ui_obj, about_obj, current_profile, hotkey_panels, current_hp
, onExitCallback, UI_scale:= A_ScreenDPI/96, UI_profileIsDirty:= 0
, input_hook, input_hook_timer, key_set, modifier_set, is_multiple_mics:=0
, template_link:= "<link rel='stylesheet' id='css_{1:}' href='{2:}'>"
, template_default_profile:= "<option value='{1:}' {2:} >{1:}</option>"
, template_mic:= "<option value='{1:}' id='mic_{1:}' {2:} >{3:}</option>"
, template_output:= "<option value='{1:}' id='output_{1:}' {2:}>{1:}</option>"
, template_app:= "<option value='{1:}' {3:} >{2:}</option>"
, template_profile_tag:= "
(
    <span class=""tag is-medium has-tooltip"" tabindex=0 role=""button"" aria-label=""{1:}"" aria-pressed=""false""  onkeydown=""switch(event.keyCode){case 32:case 69: event.preventDefault(); this.oncontextmenu.call() ;break; case 13:this.click()}""
        id=""tag_profile_{1:}"" oncontextmenu=""ahk.UI_displayProfileRename('{1:}')"" onClick=""ahk.UI_setProfile('{1:}');this.blur()"">
        <label class=""radio"">
            <input type=""radio"" name=""profiles_radio"" value=""{1:}"" id=""profile_{1:}"" disabled>
            <span data-title=""Right click to edit profile name"" >{1:}</span>
        </label>
    </span>
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
                  ,{ selector: ".multiple-mics-label"
                     , string: "Right click to view instructions"}
                  ,{ selector: ".ForceMicrophoneState-label"
                     , string: "Prevent other apps from changing the mic's state"}
                  ,{ selector: ".UseCustomSounds-label"
                     , string: "Right click to view instructions"}
                  ,{ selector: ".OverlayUseCustomIcons-label"
                     , string: "Right click to view instructions"}]
, UI_helpText:= { "Custom Sounds" : "
                (LTrim
                <ol>
                    <li>Turn on the option in the config UI</li>
                    <li>Place the sound files (<code>mp3</code>,<code>wav</code>) in the same folder as <code>MicMute.exe</code></li>
                    <li>
                        Rename them as:
                        <ul>
                            <li>
                                <p><strong>Mute sound</strong>: <code>mute</code> </p>
                            </li>
                            <li>
                                <p><strong>Unmute sound</strong>: <code>unmute</code> </p>
                            </li>
                            <li>
                                <p><strong>PTT on</strong>: <code>ptt_on</code> </p>
                            </li>
                            <li>
                                <p><strong>PTT off</strong>: <code>ptt_off</code></p>
                            </li>
                        </ul>
                    </li>
                </ol>
                )"
                , "Custom Icons" : "
                (LTrim
                <ol>
                    <li>Turn on the option in the config UI</li>
                    <li>Place the icons (<code>ico</code>/<code>png</code>/<code>jpeg</code>) in the same folder as <code>MicMute.exe</code></li>
                    <li>
                        Rename them as:
                        <ul>
                            <li>
                                <p><strong>Mute icon</strong>: <code>overlay_mute</code> </p>
                            </li>
                            <li>
                                <p><strong>Unmute icon</strong>: <code>overlay_unmute</code> </p>
                            </li>
                        </ul>
                    </li>
                </ol>
                )"
                , "Multiple Microphones" : "
                (LTrim
                <p>You can have active hotkeys for multiple microphones simultaneously, to do this:</p>
                <ol>
                    <li>Toggle the <div class='tag tag-empty'>Multiple</div> option </li>
                    <li>Select another microphone from the list </li>
                    <li>Setup the hotkeys</li>
                </ol>
                )"}

UI_create(p_onExitCallback){
    util_log("[UI] Creating 'config' window")
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
    util_log("[UI] Showing 'config' window")
    updateSysTheme()
    UI_reset()
    UI_setProfile("", p_profile)
    UI_switchToTab("", ".main-tabs", "profiles_tab")
    UI_addTooltips()
    tray_defaults()
    ui_obj.Gui(Format("+LabelUI_ +MinSize{:i}x{:i} +OwnDialogs",785*UI_scale,500*UI_scale))
    ui_obj.Show(Format("Center w{:i} h{:i}",820*UI_scale,650*UI_scale),"MicMute")
    ui_obj.doc.focus()
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
    if(UI_profileIsDirty)
        UI_warnProfileIsDirty()
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
    UI_onToggleMultiple()
    ui_obj.doc.getElementById("profile_name_field").value:= current_profile.ProfileName
    ui_obj.doc.getElementById("microphone").value:= current_profile.Microphone[1].Name
    UI_setHotkeyPanel(hotkey_panels[current_profile.Microphone[1].Name])
    ui_obj.doc.getElementById("SoundFeedback").checked:= current_profile.SoundFeedback
    ui_obj.doc.getElementById("UseCustomSounds").checked:= current_profile.SoundFeedbackUseCustomSounds
    UI_onRefreshOutputDeviceList("")
    ui_obj.doc.getElementById("output_device").value:= current_profile.SoundFeedbackDevice
    ui_obj.doc.getElementById("OnscreenFeedback").checked:= current_profile.OnscreenFeedback
    ui_obj.doc.getElementById("OnscreenOverlay").checked:= current_profile.OnscreenOverlay
    ui_obj.doc.getElementById("OverlayShow").value:= current_profile.OverlayShow
    ui_obj.doc.getElementById("OverlayUseCustomIcons").checked:= current_profile.OverlayUseCustomIcons
    ui_obj.doc.getElementById("ExcludeFullscreen").checked:= current_profile.ExcludeFullscreen
    ui_obj.doc.getElementById("OSDPos_x").value:= current_profile.OSDPos.x==-1? "" : current_profile.OSDPos.x
    ui_obj.doc.getElementById("OSDPos_y").value:= current_profile.OSDPos.y==-1? "" : current_profile.OSDPos.y
    UI_onRefreshAppsList("")
    ui_obj.doc.getElementById("afkTimeout").value:= !current_profile.afkTimeout? "" : current_profile.afkTimeout
    ui_obj.doc.getElementById("PTTDelay").value:= current_profile.PTTDelay
    UI_onUpdateDelay(current_profile.PTTDelay)
    innerCont.classList.remove("hidden")
    UI_profileIsDirty:= 0
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
    if(config_obj.ForceMicrophoneState)
        ui_obj.doc.getElementById("ForceMicrophoneState").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("ForceMicrophoneState").removeAttribute("checked")
    if(config_obj.SwitchProfileOSD)
        ui_obj.doc.getElementById("SwitchProfileOSD").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("SwitchProfileOSD").removeAttribute("checked")
    if(config_obj.AllowUpdateChecker)
        ui_obj.doc.getElementById("AllowUpdateChecker").setAttribute("checked", 1)
    else
        ui_obj.doc.getElementById("AllowUpdateChecker").removeAttribute("checked")    
    ui_obj.doc.getElementById("PreferTheme").value:= config_obj.PreferTheme
}

UI_onChange(neutron, funcName, params*){
    if(fn:=Func(funcName))
        fn.call(params*)
    UI_profileIsDirty:= 1
}

UI_resetMicSelect(){
    if(config_obj.VoicemeeterIntegration && VoicemeeterController.isVoicemeeterInstalled(config_obj.VoicemeeterPath))
        vm:= VoicemeeterController.initVoicemeeter(config_obj.VoicemeeterPath)
    select:= ui_obj.doc.getElementById("microphone")
    select.innerHTML:=""
    devices:= UI_getMicrophonesList()
    for i, device in devices {
        if(InStr(device, "VMR_") && vm){
            deviceInfo:=""
            RegExMatch(device, VoicemeeterController.BUS_STRIP_REGEX, deviceInfo)
            deviceName:= "Voicemeeter " (vm[deviceInfo.type][deviceInfo.index]).name
            select.insertAdjacentHTML("beforeend", Format(template_mic, device, "", deviceName))
        }else{
            select.insertAdjacentHTML("beforeend", Format(template_mic, device, "", device))
        }
    }    
    select.value:= "Default"
}

UI_setHotkeyPanel(hotkey_panel, delay:=0){
    innerCont:= ui_obj.doc.getElementById("hotkeys_panel")
    innerCont.classList.add("hidden")
    if(delay)
        sleep, %delay%
    current_hp:= hotkey_panel
    ; hotkey type
    ui_obj.doc.getElementById("hktype_" . current_hp.hotkeyType).checked:=1
    UI_onHotkeyType(current_hp.hotkeyType)
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

UI_updateHotkeyOption(option){
    elem:= ui_obj.doc.getElementById(option)
    option:= StrSplit(option, "_")
    current_hp.updateOption(option[1], option[2], elem.checked? 1 : 0)
    util_log(Format("[UI] {} hotkey set to: {}", option[1], current_hp[option[1]].hotkey))
}

UI_onSaveProfile(neutron, noReset:=0){
    UI_profileIsDirty:= 0
    current_profile.SoundFeedback:= ui_obj.doc.getElementById("SoundFeedback").checked? 1 : 0
    current_profile.SoundFeedbackUseCustomSounds:= ui_obj.doc.getElementById("UseCustomSounds").checked? 1 : 0
    current_profile.SoundFeedbackDevice:= ui_obj.doc.getElementById("output_device").value
    current_profile.OnscreenFeedback:= ui_obj.doc.getElementById("OnscreenFeedback").checked? 1 : 0
    current_profile.OnscreenOverlay:= ui_obj.doc.getElementById("OnscreenOverlay").checked? 1 : 0
    current_profile.ExcludeFullscreen:= ui_obj.doc.getElementById("ExcludeFullscreen").checked? 1 : 0
    current_profile.OverlayShow:= ui_obj.doc.getElementById("OverlayShow").value
    current_profile.OverlayUseCustomIcons:= ui_obj.doc.getElementById("OverlayUseCustomIcons").checked? 1 : 0
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
    if(!noReset){
        UI_reset()
        UI_setProfile(neutron, current_profile.ProfileName)
    }
    UI_notify("Profile saved")   
}

UI_onDeleteProfile(neutron){
    if(current_profile.ProfileName == config_obj.DefaultProfile){
        UI_notify("Cannot delete default profile")
        return
    }
    config_obj.deleteProfile(current_profile.ProfileName)
    UI_profileIsDirty:= 0
    UI_reset()
    UI_setProfile(neutron, config_obj.DefaultProfile)
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

UI_onRecord(type){
    ;stop any other input hook
    if(input_hook.InProgress){
        input_hook.Stop()
        sleep, 30
    }
    ;reset hotkey stackset
    key_set:= new StackSet()
    modifier_set:= new StackSet()
    ;hide record button and show stop button
    UI_hideElemID(type . "_record")
    UI_showElemID(type . "_stop")
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
    input_hook.OnEnd:= Func("UI_onStop").Bind(type)
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

UI_onStop(type, InputHook:=""){
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
    UI_hideElemID(type "_stop")
    UI_showElemID(type "_record")
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
    util_log(Format("[UI] {} hotkey set to: {}", type, current_hp[type].hotkey))
}

UI_onClearHotkey(){
    mic:= ui_obj.doc.getElementById("microphone").value
    hotkey_panels[mic]:= new HotkeyPanel("","",1)
    UI_setHotkeyPanel(hotkey_panels[mic], 200)
}

UI_onRefreshDeviceList(neutron){
    UI_resetMicSelect()
    UI_checkMicOptions()
    if(current_profile.Microphone[1].Name)
        ui_obj.doc.getElementById("microphone").value:= current_profile.Microphone[1].Name
    UI_onSetMicrophone(ui_obj.doc.getElementById("microphone").value)
    if(neutron)
        UI_notify("Refreshed devices")
}

UI_onRefreshOutputDeviceList(neutron){
    select:= ui_obj.doc.getElementById("output_device")
    select.innerHTML:= ""
    devices:= new SoundPlayer().devices
    for i, device in devices {
        select.insertAdjacentHTML("beforeend", Format(template_output, device, device = current_profile.SoundFeedbackDevice? "selected":""))
    }
    if(current_profile.SoundFeedbackDevice != select.value)
        select.insertAdjacentHTML("beforeend", Format(template_output, current_profile.SoundFeedbackDevice, "selected"))
    if(neutron)
        UI_notify("Refreshed devices")
}

UI_checkMicOptions(){
    devices:= UI_getMicrophonesList(), numPanels:=0
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

; returns a list of all microphones, even if they are not currently available
UI_getMicrophonesList(){
    inputDevices:= new StackSet("Default", "All Microphones", VA_GetDeviceList("capture")*)
    inputDevices.pushAll(VMR_GetDeviceList()*)
    for i, mic in current_profile.Microphone {
        inputDevices.push(mic.Name)
    }
    return inputDevices.data
}

VMR_GetDeviceList(){
    deviceList:= Array()
    if(config_obj.VoicemeeterIntegration && VoicemeeterController.isVoicemeeterInstalled(config_obj.VoicemeeterPath)){
        vm:= VoicemeeterController.initVoicemeeter(config_obj.VoicemeeterPath)
        for i, bus in vm.bus {
            if(!bus.isPhysical())
                deviceList.push("VMR_Bus[" i "]")
        }
        for i, strip in vm.strip {
            deviceList.push("VMR_Strip[" i "]")
        }
    }
    return deviceList
}

UI_onUpdateDelay(delay){
    ui_obj.doc.getElementByID("PTTDelay_text").value:= delay . " ms"
}

UI_onHotkeyType(type, delay:=0){
    static hideElemFunc:= Func("UI_hideElemID").Bind("unmute_box")
    innerCont:= ui_obj.doc.getElementById("hotkey_panels_group")
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

UI_onSetMicrophone(mic_name){
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

UI_onOSDset(){
    ui_obj.Gui("+OwnDialogs")
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

UI_onToggleMultiple(){
    is_multiple_mics:= ui_obj.doc.getElementById("multiple_mics").checked
    if(is_multiple_mics){
        ui_obj.doc.getElementById("OnscreenOverlay_tag").classList.add("hidden")
        ui_obj.doc.getElementById("onscreen_overlay_group").classList.add("row-hidden")
    }else{
        ui_obj.doc.getElementById("OnscreenOverlay_tag").classList.remove("hidden")
        ui_obj.doc.getElementById("onscreen_overlay_group").classList.remove("row-hidden")
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

UI_onRefreshAppsList(neutron){
    list:= UI_getProcessList()
    select:= ui_obj.doc.getElementById("LinkedApp")
    if(current_profile.LinkedApp)
        list.push(current_profile.LinkedApp)
    select.innerHTML:=""
    select.insertAdjacentHTML("beforeend", Format(template_app, "", "Select an app", "selected"))
    for i, process in list.data {
        WinGetTitle, winTitle, ahk_exe %process%
        winTitle:= winTitle? winTitle " (" process ")" : process
        select.insertAdjacentHTML("beforeend"
        , Format(template_app, process, winTitle, process = current_profile.LinkedApp? "selected" : ""))    
    }
    if(neutron)
        UI_notify("Refreshed running apps")
}

UI_displayProfileRename(neutron, p_profile){
    if(current_profile.ProfileName != p_profile)
        UI_setProfile(neutron,p_profile)
    ui_obj.qs("#profileRenameModal > .page-mask").classList.remove("hidden")
    ui_obj.qs("#profileRenameModal > .modal-contents").classList.remove("hidden")
    ui_obj.qs(".main").classList.add("is-clipped")
    field:= ui_obj.doc.getElementById("profile_name_field")
    field.focus()
    field.setSelectionRange(ln:=StrLen(field.value),ln)
}

UI_hideProfileRename(neutron, event:=""){
    maskElem:= ui_obj.qs("#profileRenameModal > .page-mask")
    pElem:= ui_obj.qs("#profileRenameModal > .modal-contents")
    if(!event){
        maskElem.classList.add("hidden")
        pElem.classList.add("hidden")
        ui_obj.qs(".main").classList.remove("is-clipped")
        return
    }
    switch event.keyCode {
        case 0x1B,0x0D:
            pElem.firstElementChild.blur()
            maskElem.classList.add("hidden")
            pElem.classList.add("hidden")
            ui_obj.qs(".main").classList.remove("is-clipped")
    }
}

UI_showHelpModal(neutron, title){
    ui_obj.qs("#helpModal .modal-card-title").innerText:= title
    ui_obj.qs("#helpModal .content").innerHTML:= UI_helpText[title]
    ui_obj.qs("#helpModal > .page-mask").classList.remove("hidden")
    ui_obj.qs("#helpModal > .modal-contents").classList.remove("hidden")
    ui_obj.qs(".main").classList.add("is-clipped")
    ui_obj.qs("#helpModal .card").focus()
}

UI_hideHelpModal(neutron, event:=""){
    maskElem:= ui_obj.qs("#helpModal > .page-mask")
    pElem:= ui_obj.qs("#helpModal > .modal-contents")
    if(!event || event.keyCode = 0x1B || event.keyCode = 0x0D){
        maskElem.classList.add("hidden")
        pElem.classList.add("hidden")
        ui_obj.qs(".main").classList.remove("is-clipped")
    }
}

UI_switchToTab(neutron, rootSelector, tabID){
    activeTab:= ui_obj.qs(rootSelector " li.is-active")
    activeTabContent:= ui_obj.doc.getElementById(activeTab.id "_content")

    wantedTab:= ui_obj.doc.getElementById(tabID)
    wantedTabContent:= ui_obj.doc.getElementById(tabID "_content")

    if(neutron && activeTab.id == wantedTab.id)
        return 
        
    activeTab.classList.remove("is-active")
    wantedTab.classList.add("is-active")
    activeTabContent.classList.add("hidden")
    if(neutron)
        sleep, 200
    activeTabContent.classList.add("tab-hidden")
    wantedTabContent.classList.remove("tab-hidden")
    wantedTabContent.classList.remove("hidden")
    if(tabID == "profiles_tab")
        UI_switchToTab(neutron, ".profile-tabs", "hotkeys_tab")
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
    neutron.doc.getElementById("version").innerText:= A_Version
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

UI_flipVal(neutron,elemId){
    elem:= ui_obj.doc.getElementById(elemId)
    elem.checked := !elem.checked
    elem.setAttribute("aria-pressed", elem.checked? "true" : "false")
}

UI_hideElemID(elemId){
    elem:= ui_obj.doc.getElementByID(elemId)
    elem.classList.add("is-hidden")
}

UI_showElemID(elemId){
    elem:= ui_obj.doc.getElementByID(elemId)
    elem.classList.remove("is-hidden")
}

UI_warnProfileIsDirty(){
    ui_obj.Gui("+OwnDialogs")
    MsgBox, 52, MicMute, % Format("You have unsaved changes in profile '{}'`nDo you want to save them before continuing?",current_profile.ProfileName)
    IfMsgBox, Yes
        UI_onSaveProfile("", 1)
}

UI_notify(txt){
    ui_obj.doc.getElementById("notification_content").innerText:= txt
    ui_obj.doc.getElementById("notification").classList.remove("hidden")
    SetTimer, UI_dismissNotif, -2000
}

UI_dismissNotif(neutron:=""){
    ui_obj.doc.getElementById("notification").classList.add("hidden")
}

UI_close(neutron:=""){
    if(UI_profileIsDirty)
        UI_warnProfileIsDirty()
    ui_obj.Hide()
    onExitCallback.Call(current_profile.ProfileName)
    ui_obj.Close()
}

UI_updateTheme(){
    if(ui_theme){
        ui_obj.doc.getElementById("css_dark").removeAttribute("disabled")
        ui_obj.SetWindowFillColor(0x272727)
        about_obj.doc.getElementById("css_dark").removeAttribute("disabled")
    }else{
        ui_obj.doc.getElementById("css_dark").setAttribute("disabled","1")
        ui_obj.SetWindowFillColor(0xF3F3F3)
        about_obj.doc.getElementById("css_dark").setAttribute("disabled","1")
    }
}

UI_createAbout(){
    util_log("[UI] Creating 'about' window")
    about_obj:= new NeutronWindow()
    about_obj.load(resources_obj.htmlFile.about)
    UI_loadCss(about_obj)
    updateSysTheme()
    about_obj.Gui("-Resize")
}

UI_showAbout(neutron:="", isCheckingForUpdates:=0){
    util_log("[UI] Showing 'about' window")
    tray_defaults()
    if(isCheckingForUpdates)
        UI_checkForUpdates(neutron)
    about_obj.show(Format("Center w{:i} h{:i}", 500*UI_scale, 300*UI_scale), "About MicMute")
    about_obj.doc.focus()
    about_obj.Gui("+OwnDialogs")
}

UI_exitAbout(neutron){
    about_obj.Close()
    about_obj.Destroy()
    UI_createAbout()
}

UI_checkForUpdates(neutron:=""){
    refreshButton:= about_obj.doc.getElementById("refresh_button")
    refreshButton.classList.add("is-loading")
    Try latestVersion:= updater_obj.getLatestVersion()
    if(latestVersion){
        about_obj.doc.getElementById("latest_version").innerText:= latestVersion
        refreshButton.classList.add("push-right")
        if(util_VerCmp(latestVersion, A_Version) = 1){
            about_obj.doc.getElementById("update_button").classList.remove("is-hidden")
        }
    }
    refreshButton.classList.remove("is-loading")
    refreshButton.blur()
}

UI_launchUpdater(neutron:=""){
    about_obj.Gui("+OwnDialogs")
    MsgBox, 65, MicMute, % "This will restart MicMute in updater mode"
    IfMsgBox, OK
        runUpdater()
    about_obj.doc.getElementById("update_button").blur()
}

UI_launchURL(neutron:="", url:="", isFullUrl:=0){
    repoUrl:= "https://github.com/SaifAqqad/AHK_MicMute/blob/" A_Version "/"
    if(!isFullUrl)
        url:= repoUrl . url
    Run, %url%, %A_Desktop%
}

UI_launchReleasePage(neutron:="", version:=""){
    url:= "https://github.com/SaifAqqad/AHK_MicMute/releases/tag/" . (version? version : A_Version)
    Run, %url%, %A_Desktop%
}

UI_getProcessList(){
    pSet:= new StackSet()
    WinGet, pList, List
    loop %pList% 
    {
        pHwnd:= pList%A_Index%
        WinGet, pName, ProcessName, ahk_id %pHwnd%
        pSet.push(pName)
    }
    return pSet
}