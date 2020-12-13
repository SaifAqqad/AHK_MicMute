#Include, ..\Lib\JSON.ahk
#NoTrayIcon
EnvGet, localAppData, LOCALAPPDATA
global install_folder:= localAppData . "\SaifAqqad\MicMute", lg_install_folder:= A_AppData . "\..\Local\SaifAqqad\MicMute"
,api_url:= "https://api.github.com/repos/SaifAqqad/AHK_MicMute/releases/latest"
,prog:=10, reg_path:="SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\MicMute"
,latest_ver:=,curr_ver:=,latest_url:=,latest_updater_url:=
,GUI_state:=0,GUI_prog:=,GUI_txt:=,is_silent:=0

;  0 finished successfully
; -1 Cancelled by user
; -2 Latest version already installed
; -3 Error writing/deleting files
; -4 Relaunching updater
; -5 Network error

if(A_Args[1] = "-check-update")
    checkUpdate()

if(A_ScriptDir != A_Temp || !A_IsAdmin){
    relaunch(A_Args*)
}

is_silent:= (A_Args[1] = "-silent" || A_Args[2] = "-silent")

;tray
Menu, Tray, Icon 
Menu, Tray, NoStandard
exObj:= Func("u_exit").bind(-1)
Menu, Tray, Add, Close updater, % exObj
Menu, Tray, Tip , MicMute Updater

getInstalledVer()
getLatestVer()
switch A_Args[1] {
    case "-uninstall":
        uninstall(is_silent)
    case "-update":
        update(is_silent)
    default:
        if(is_silent){
            install(1)
            u_exit()
        }
}

if(curr_ver)
    update()
MsgBox, 68, MicMute Updater, Install MicMute?
IfMsgBox, No
    u_exit(-1)
install()
GUI_destroy()
MsgBox, 68, MicMute Updater, MicMute is installed!`nRun it now?
IfMsgBox, Yes
    Run, %install_folder%\MicMute.exe, %install_folder%, UseErrorLevel
u_exit()
return

getLatestVer(){
    Try{
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", api_url, true)
        whr.Send()
        whr.WaitForResponse()
        response := JSON.Load(whr.ResponseText)
        latest_ver:= response.tag_name
        for i, asset in response.assets {
            if(asset.name = "MicMute.exe")
                latest_url:= asset.browser_download_url
            else if(asset.name = "updater.exe")
                latest_updater_url:= asset.browser_download_url
        }
    } catch {
        latest_ver:= -5
    }
}

getInstalledVer(){
    RegRead, curr_ver, HKEY_LOCAL_MACHINE, %reg_path%, DisplayVersion
    if(!curr_ver && FileExist(install_folder . "\MicMute.exe") )
        FileGetVersion, curr_ver, %install_folder%\MicMute.exe
}

relaunch(args*){
    str:=""
    for i, arg in args
        str.= arg . " "
    FileCopy, %A_ScriptFullPath%, %A_Temp%\*, 1
    Run, *RunAs %A_Temp%\%A_ScriptName% %str%
    u_exit(-4)
}

ShellMessage( wParam,lParam ) {
    if ( wParam = 1 ){
        WinGetTitle, Title, ahk_id %lParam%, MicMute is installed
        if  ( Title = "MicMute Updater"){
             ControlSetText, Button1, &Update   , ahk_id %lParam%
             ControlSetText, Button2, &Uninstall, ahk_id %lParam%
         }
    }
}

checkUpdate(){
    getLatestVer()
    getInstalledVer()
    if(curr_ver=latest_ver)
        u_exit(-2)
    if(latest_ver = -5)
        u_exit(-5)
    MsgBox, 68, MicMute updater, An update is available for MicMute`nInstall the update?
    IfMsgBox, Yes
        relaunch("-update","-silent")
    u_exit(-1)
}

update(p_is_silent:=0){
    if(!p_is_silent){
        Gui +LastFound
        hWnd := WinExist()
        DllCall( "RegisterShellHookWindow", UInt,hWnd )
        MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
        OnMessage( MsgNum, "ShellMessage" )
        MsgBox, 67, MicMute Updater, MicMute is installed
        IfMsgBox, No
            uninstall(p_is_silent)
        IfMsgBox, Cancel
            u_exit(-1)
    }
    if(latest_ver=-5){
        MsgBox, 16, MicMute updater, A network error occurred
        u_exit(-5)
    }else if(curr_ver=latest_ver){
        MsgBox, 64, MicMute Updater, You already have the latest verison installed
        u_exit(-2)
    }
    Process, close, MicMute.exe
    was_running:= ErrorLevel? 1:0
    Try FileCopy, %install_folder%\config.ini, %A_Temp%\MicMuteConfig.ini, 1
    Try FileCopy, %install_folder%\config.json, %A_Temp%\MicMuteConfig.json, 1
    install(p_is_silent)
    Try FileCopy, %A_Temp%\MicMuteConfig.ini, %install_folder%\config.ini, 1
    Try FileCopy, %A_Temp%\MicMuteConfig.json, %install_folder%\config.json, 1
    Menu, Tray, Tip, % GUI_spawn(100, "MicMute Updated")
    Sleep, 1000
    if(was_running)
        Run, %install_folder%\MicMute.exe, %install_folder%, UseErrorLevel
    u_exit()
}

uninstall(p_is_silent:=0){
    if(!p_is_silent){
        MsgBox, 68, MicMute Updater, Uninstall MicMute?
        IfMsgBox, No
            u_exit(-1)
    }
    Menu, Tray, Tip, % GUI_spawn(prog,"Closing MicMute")
    Process, close, MicMute.exe
    Sleep, 800
    prog+=30
    Menu, Tray, Tip, % GUI_spawn(prog,"Removing MicMute")
    Try FileRemoveDir, %install_folder%, 1
    Catch, err {
        MsgBox, 16, MicMute Updater
        , % "An error occured while removing MicMute:`n" . err.What . " returned " . err.Message
        u_exit(-3)
    }
    Try FileRemoveDir, %localAppData%\SaifAqqad, 0
    Menu, Tray, Tip, % prog+=30
    Sleep, 800
    Menu, Tray, Tip, % GUI_spawn(prog,"Removing Shortcuts")
    if(FileExist(A_Programs . "\SaifAqqad\MicMute")){
        FileRemoveDir, %A_Programs%\SaifAqqad\MicMute\, 1
        FileRemoveDir, %A_Programs%\SaifAqqad
    }
    if(FileExist(A_Startup . "\MicMute.lnk"))
        FileDelete, %A_Startup%\MicMute.lnk
    Sleep, 800
    RegDelete, HKEY_LOCAL_MACHINE, %reg_path%
    Run, powershell.exe "Remove-MpPreference -ExclusionPath '%install_folder%';Remove-MpPreference -ExclusionPath '%lg_install_folder%'",, Hide UseErrorLevel
    Menu, Tray, Tip, % GUI_spawn(100, "MicMute Uninstalled")
    Sleep, 1000
    u_exit()
}

install(p_is_silent:=0){
    Menu, Tray, Tip, % GUI_spawn(prog,"Creating directory")
    FileCreateDir, %install_folder%
    sleep 500
    prog+=10
    Menu, Tray, Tip, % GUI_spawn(prog,"Downloading MicMute")
    UrlDownloadToFile, %latest_url%, %install_folder%\MicMute.exe
    prog+=30
    Menu, Tray, Tip, % GUI_spawn(prog,"Downloading MicMute")
    UrlDownloadToFile, %latest_updater_url%, %install_folder%\updater.exe
    Sleep, 500
    prog+=30
    Menu, Tray, Tip, % GUI_spawn(prog,"Creating shortcuts")
    FileCreateDir, %A_Programs%\SaifAqqad\MicMute
    FileCreateShortcut, %install_folder%\MicMute.exe, %A_Programs%\SaifAqqad\MicMute\MicMute.lnk, %install_folder%
    FileCreateShortcut, %install_folder%\updater.exe,%A_Programs%\SaifAqqad\MicMute\MicMute Updater.lnk, %install_folder%
    prog+=20
    Menu, Tray, Tip, % GUI_spawn(prog,"Creating shortcuts")
    FileGetSize, size, %install_folder%\MicMute.exe, K
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayIcon, %install_folder%\MicMute.exe
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayName, MicMute
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayVersion, %latest_ver%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, Publisher, Saif Aqqad
    RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, %reg_path%, EstimatedSize, %size%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, UninstallString, "%install_folder%\updater.exe" -uninstall
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, InstallLocation, %install_folder%
    if(!is_excluded()){
        MsgBox, 68, MicMute Updater
        , Allow MicMute to add an exclusion to Windows defender to prevent it from being falsely triggered?
        IfMsgBox, Yes
            Run, powershell.exe "Add-MpPreference -ExclusionPath '%install_folder%' ",, Hide UseErrorLevel
    }
}

GUI_spawn(prog,txt){
    if(is_silent)
        return prog . "% " . txt
    if (GUI_state = 0){
        GUI_Theme:= 0x232323
        GUI_Accent:= 0xff572d
        SetFormat, integer, d
        Gui, Color, %GUI_Theme%, %GUI_Accent%
        Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption -Border
        WinSet, Transparent, 230, ahk_class AutoHotkeyGUI
        Gui, Font, s11, Segoe UI
        Gui, Add, Text, c%GUI_Accent% vGUI_txt W165 Center, %txt%
        if (prog!=-1)
            Gui, Add, Progress, W165 c%GUI_Accent% Background%GUI_Theme% vGUI_prog, %prog%
        SysGet, MonitorWorkArea, MonitorWorkArea, 0
        GUI_yPos:= MonitorWorkAreaBottom * 0.90
        Gui, Show, AutoSize NoActivate xCenter y%GUI_yPos%
        GUI_state:= 1
    }else{
        if (prog!=-1)
            GuiControl,, GUI_prog, %prog%
        GuiControl,, GUI_txt, %txt%
    }
    return prog . "% " . txt
}

GUI_destroy(){
    Gui, Destroy
    GUI_state := 0
}

is_excluded(){
    RunWait, powershell.exe "(Get-MpPreference).ExclusionPath | Out-File '%A_Temp%\ps_out.tmp'",, Hide UseErrorLevel
    output:= FileOpen(A_Temp . "\ps_out.tmp", "R").Read()
    return InStr(output, install_folder) || InStr(output, lg_install_folder)
}

rmFileOnBoot(dir){
    return DllCall("MoveFileExW", "Str", dir, "Str", 0, "UInt", 4)
}

u_exit(code:=0){
    rmFileOnBoot(A_ScriptFullPath)
    ExitApp, % code
}