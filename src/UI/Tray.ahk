Global startup_shortcut:= A_Programs . "\Startup\MicMute.lnk"

tray_init(){
    global
    Menu, Tray, DeleteAll
    Menu, Tray, NoStandard
    Menu, Tray, UseErrorLevel, On
    util_log("[Tray] Initilizing tray menu")
    tray_defaults()
    tray_createProfilesMenu()
    tray_createDebugMenu()

    tray_add("Toggle microphone", Func("tray_noFunc"))
    tray_add("Profile", ":profiles")
    tray_add("Edit configuration", Func("editConfig"))

    Menu, Tray, Add, ;seperator line
    
    tray_add("Start on boot",Func("tray_autoStart"))
    if(Arg_isDebug || A_DebuggerName)
        tray_add("Debug", ":Debug")
    tray_add("Check for updates", Func("tray_checkForUpdates"))
    tray_add("Help",Func("tray_launchHelp"))
    if(!arg_noUI)
        tray_add("About",Func("tray_about"))
    tray_add("Reload",Func("tray_Reload"))
    tray_add("Exit",Func("tray_exit"))  

    Menu, Tray, Click, 1
    Menu, Tray, Default, 1&
    
    if (util_StartupTaskExists())
        Menu, Tray, Check, Start on boot
    else
        Menu, Tray, Uncheck, Start on boot
}

tray_init_updater(){
    Menu, Tray, DeleteAll
    Menu, Tray, NoStandard
    Menu, Tray, UseErrorLevel, On
    util_log("[Tray] Initilizing updater tray menu")
    tray_defaults()
    tray_add("Help",Func("tray_launchHelp"))
    tray_add("Exit",Func("tray_exit"))  
}

tray_defaults(){
    ico:= resources_obj.defaultIcon
    Menu, Tray, Tip, MicMute 
    Menu, Tray, Icon, % ico.file, % ico.group,0
}

tray_update(mic_obj){
    tooltipText:= mic_obj.generic_state_string[mic_obj.state]
    ico:= resources_obj.getIcoFile(mic_obj.state)
    Menu, Tray, Tip, % tooltipText
    Menu, Tray, Icon, % ico.file, % ico.group,0
}

tray_add(name, funcObj){
    Menu, Tray, Add, %name%, %funcObj%
}

tray_remove(item){
    Menu, Tray, Delete, %item%
}

tray_autoStart(){
    if (util_StartupTaskExists()){
        Menu, Tray, % util_DeleteStartupTask()? "Uncheck" : "Check", Start on boot
    }else{
        if(FileExist(startup_shortcut)){
            MsgBox, 36, MicMute, A startup shortcut in '%A_Programs%\Startup\' was found`nDo you want to replace it with a scheduled task?
            IfMsgBox, No
                return
            Try FileDelete, %startup_shortcut%
        }
        Menu, Tray, % util_CreateStartupTask()? "Check" : "Uncheck", Start on boot
    }
}

tray_toggleMic(onOff){
    if(onOff){
        Menu, Tray, Enable, 1&
        Menu, Tray, Default, 1&
    }else{
        Menu, Tray, Disable, 1&
        Menu, Tray, NoDefault
    }
    
}

tray_createProfilesMenu(){
    Try Menu, profiles, DeleteAll
    for i, p_profile in config_obj.Profiles{
        funcObj:= Func("switchProfile").bind(p_profile.ProfileName)
        Menu, profiles, Add, % p_profile.ProfileName, % funcObj, +Radio
    }
}

tray_createDebugMenu(){
    Menu, Debug, Add, List Hotkeys, lh
    Menu, Debug, Add, List Vars, lv
    Menu, Debug, Add, View Log, tray_showLog
    return
    lh:
        ListHotkeys
    return
    lv:
        ListVars
    return
}

tray_launchHelp(){
    if(GetKeyState("Shift", "P"))
        tray_showLog()
    else
        UI_launchURL("", "README.md#usage")
}

tray_about(){
    UI_showAbout()
}

tray_exit(){
    ExitApp
}

tray_Reload(){
    initilizeMicMute(current_profile.ProfileName)
}

tray_checkForUpdates(){
    UI_showAbout("",1)
}

tray_noFunc(){
    return
}

tray_showLog(){
    tray_defaults()
    Gui, llv:New, +Labeltray_llv
    Gui, Add, ListView, NoSortHdr r20 w700, Log
    Gui, Add, Button, w80 gtray_llvRefresh, Refresh Log
    Gui, Add, Button, w80 x+5 gtray_llvCopy, Copy Log
    tray_llvRefresh()
    Gui, show, , MicMute Logs
}

tray_llvRefresh(){
    Gui, llv:Default
    LV_Delete()
    for i, line in StrSplit(A_log, "`n") {
        LV_Add("",line)
    }
    LV_Modify(LV_GetCount(), "Vis")
}

tray_llvCopy(){
    Clipboard := StrReplace(A_Log, A_UserName, "***")
}

tray_llvClose(){
    Gui, llv:Default
    Gui, Destroy
}