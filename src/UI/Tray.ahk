Global startup_shortcut:= A_Programs . "\Startup\MicMute.lnk"

tray_init(){
    global
    Menu, Tray, DeleteAll
    Menu, Tray, NoStandard
    Menu, Tray, UseErrorLevel, On
    tray_defaults()
    tray_createProfilesMenu()
    tray_createDebugMenu()

    tray_add("Toggle microphone", Func("tray_noFunc"))
    tray_add("Profile", ":profiles")
    tray_add("Edit configuration", Func("editConfig"))

    Menu, Tray, Add, ;seperator line
    
    if(FileExist(A_ScriptDir . "\updater.exe"))
        tray_add("Check for updates", Func("tray_checkUpdate"))
    tray_add("Start on boot",Func("tray_autoStart"))
    tray_add("Help",Func("tray_launchHelp"))
    if(A_Args[1] = "/debug" || A_DebuggerName)
        tray_add("Debug", ":Debug")
    tray_add("Exit",Func("tray_exit"))        

    Menu, Tray, Click, 1
    Menu, Tray, Default, 1&
    
    if (util_StartupTaskExists())
        Menu, Tray, Check, Start on boot
    else
        Menu, Tray, Uncheck, Start on boot
}

tray_defaults(){
    ico:= resources_obj.defaultIcon
    Menu, Tray, Tip, MicMute 
    Menu, Tray, Icon, % ico.file, % ico.group,0
}

tray_update(state){
    tooltipText:= state_string[state]
    ico:= resources_obj.getIcoFile(state)
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

tray_checkUpdate(){
    funcObj:= Func("runUpdater").bind(0)
    SetTimer, % funcObj, -1
}

tray_createDebugMenu(){
    Menu, Debug, Add, List Hotkeys, lh
    Menu, Debug, Add, List Lines, ll
    Menu, Debug, Add, List Vars, lv
    Menu, Debug, Add, List Keys, ks
    return
    lh:
        ListHotkeys
    return
    ll:
        ListLines
    return
    lv:
        ListVars
    return
    ks:
        listKeys()
    return
}

tray_launchHelp(){
    Run, https://github.com/SaifAqqad/AHK_MicMute#usage, %A_Desktop%
}

tray_exit(){
    ExitApp
}

listKeys(){
    static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
    Gui, listkeys:New, ,List keys
    Gui, Add, ListView, w200 h300, Key|State
    Gui, Add, Button,grefreshLK,Refresh
    Gui, Show
    Goto, refreshLK
    return
    refreshLK:
        keys := {}
        LV_Delete()
        Loop 350 {
            ; Get the key name
            code := Format("{:x}", A_Index)
            if(ObjHasKey(replacements, A_Index)){
                n := replacements[A_Index]
            } else {
                n := GetKeyName("vk" code)
            }
            if (n = "" || n = "Escape" || ObjHasKey(keys, n))
                continue
            LV_Add(,n, GetKeyState("vk" code))
            keys[n] := 1
        }
        LV_ModifyCol()
    return
}

tray_noFunc(){
    return
}