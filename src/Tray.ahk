Global startup_shortcut:= A_Programs . "\Startup\MicMute.lnk"
, U_defaultBlack:= -3080
, U_defaultWhite:= -3090
, U_muteBlack:= -4080
, U_muteWhite:= -4090

tray_init(){
    Menu, Tray, DeleteAll
    Menu, Tray, NoStandard
    Menu, Tray, Icon, %A_ScriptFullPath%, 1
    Menu, Tray, Tip, MicMute 
    tray_add("Exit",Func("tray_exit"))
    tray_add("Help",Func("tray_launchHelp"))
    tray_add("Start on boot",Func("tray_autoStart"))
    if(FileExist(A_ScriptDir . "\updater.exe"))
        tray_add("Check for updates",Func("tray_checkUpdate"))
    Menu, Tray, Insert, 1&
    tray_add("Edit configuration",Func("editConfig"))
    tray_createProfilesMenu()
    tray_add("Profile", ":profiles")
    tray_add("Toggle microphone", Func("setMuteState").bind(-1))
    Menu, Tray, Click, 1
    Menu, Tray, Default, 1&
    if (!FileExist(startup_shortcut))
        Menu, Tray, Uncheck, Start on boot
    else
        Menu, Tray, Check, Start on boot
}

tray_update(icon_group, tooltip_txt){
    Menu, Tray, Icon, %A_ScriptFullPath%, %icon_group%
    Menu, Tray, Tip, %tooltip_txt%
}

tray_add(name, funcObj){
    Menu, Tray, Insert, 1&, %name%, %funcObj%
}

tray_remove(item){
    Menu, Tray, Delete, %item%
}

tray_autoStart(){
    if (!FileExist(startup_shortcut)){
        FileCreateShortcut, %A_ScriptFullPath%, % startup_shortcut, %A_ScriptDir%
        Menu, Tray, % !ErrorLevel? "Check" : "Uncheck", Start on boot
    }else{
        FileDelete, % startup_shortcut
        Menu, Tray, % !ErrorLevel? "Uncheck" : "Check", Start on boot
    }
}

tray_createProfilesMenu(){
    Try Menu, profiles, DeleteAll
    for i, p_profile in conf.Profiles{
        funcObj:= Func("switchProfile").bind(p_profile.ProfileName)
        Menu, profiles, Add, % p_profile.ProfileName, % funcObj, +Radio
    }
}

tray_checkUpdate(){
    funcObj:= Func("runUpdater").bind(0)
    SetTimer, % funcObj, -1
}

tray_launchHelp(){
    if(GetKeyState("Shift", "P"))
        ListHotkeys
    else if(GetKeyState("LWin", "P"))
        ListLines
    else if(GetKeyState("Ctrl", "P"))
        ListVars
    else
        Run, https://github.com/SaifAqqad/AHK_MicMute#usage, %A_Desktop%
}

tray_exit(){
    ExitApp
}