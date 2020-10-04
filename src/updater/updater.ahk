#Include, JSON.ahk
global install_folder:= A_AppData . "\..\Local\SaifAqqad\MicMute"
,api_url:= "https://api.github.com/repos/SaifAqqad/AHK_MicMute/releases/latest"
,prog:=10, reg_path:="SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\MicMute"
,latest_ver:=,curr_ver:=,latest_url:=,latest_updater_url:=
,GUI_state:=0,GUI_prog:=,GUI_txt:=

if(A_ScriptDir != A_Temp){
    FileCopy, %A_ScriptFullPath%, %A_Temp%\*, 1
    Run, *RunAs %A_Temp%\%A_ScriptName%
    ExitApp
}
if(InStr(A_Args[1], "-u"))
    uninstall()
getLatestVer()
if(isInstalled())
    update()
MsgBox, 68, MicMute Updater, Install MicMute?
IfMsgBox, No
    ExitApp
install()
GUI_spawn(100,"MicMute Installed")
Sleep, 1000
ExitApp
return

getLatestVer(){
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", api_url, true)
    whr.Send()
    whr.WaitForResponse()
    response := JSON.Load(whr.ResponseText)
    latest_ver:= response.tag_name
    if(response.assets[1].name="MicMute.exe"){
        latest_url:= response.assets[1].browser_download_url
        latest_updater_url:= response.assets[2].browser_download_url
    }else{
        latest_url:= response.assets[2].browser_download_url
        latest_updater_url:= response.assets[1].browser_download_url
    }
}
isInstalled(){
    RegRead, curr_ver, HKEY_LOCAL_MACHINE, %reg_path%, DisplayVersion
    return curr_ver || FileExist(install_folder . "\MicMute.exe") 
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

update(){
    Gui +LastFound
    hWnd := WinExist()
    DllCall( "RegisterShellHookWindow", UInt,hWnd )
    MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
    OnMessage( MsgNum, "ShellMessage" )
    MsgBox, 67, MicMute Updater, MicMute is installed
    IfMsgBox, No
        uninstall()
    IfMsgBox, Cancel
        ExitApp
    if(curr_ver=latest_ver){
        MsgBox, 64, MicMute Updater, You already have the latest verison installed
        ExitApp
    }
    FileCopy, %install_folder%\config.ini, %A_Temp%\MicMuteConfig.ini, 1
    install()
    FileCopy, %A_Temp%\MicMuteConfig.ini, %install_folder%\config.ini, 1
    GUI_spawn(100, "MicMute Updated")
    Sleep, 1000
    ExitApp
}

uninstall(){
    MsgBox, 68, MicMute Updater, Uninstall MicMute?
    IfMsgBox, No
    ExitApp
    GUI_spawn(prog,"Closing MicMute")
    Process, close, MicMute.exe
    Sleep, 800
    prog+=30
    GUI_spawn(prog,"Removing MicMute")
    if(FileExist(install_folder))
        FileRemoveDir, %install_folder%, 1
    prog+=30
    Sleep, 800
    GUI_spawn(prog,"Removing Shortcuts")
    if(FileExist(A_StartMenu . "\SaifAqqad\MicMute"))
        FileRemoveDir, %A_StartMenu%\SaifAqqad\MicMute\, 1
    if(FileExist(A_Startup . "\MicMute.lnk"))
        FileDelete, %A_Startup%\MicMute.lnk
    Sleep, 800
    RegDelete, HKEY_LOCAL_MACHINE, %reg_path%
    GUI_spawn(100, "MicMute Uninstalled")
    Sleep, 1000
    ExitApp
}

install(){
    GUI_spawn(prog,"Creating directory")
    FileCreateDir, %install_folder%
    sleep 500
    prog+=10
    GUI_spawn(prog,"Downloading MicMute")
    UrlDownloadToFile, %latest_url%, %install_folder%\MicMute.exe
    prog+=30
    GUI_spawn(prog,"Downloading MicMute")
    UrlDownloadToFile, %latest_updater_url%, %install_folder%\updater.exe
    Sleep, 500
    prog+=30
    GUI_spawn(prog,"Creating shortcuts")
    FileCreateDir, %A_StartMenu%\SaifAqqad\MicMute
    FileCreateShortcut, %install_folder%\MicMute.exe, %A_StartMenu%\SaifAqqad\MicMute\MicMute.lnk, %install_folder%
    FileCreateShortcut, %install_folder%\updater.exe,%A_StartMenu%\SaifAqqad\MicMute\MicMute Updater.lnk, %install_folder%
    prog+=10
    GUI_spawn(prog,"Creating shortcuts")
    FileGetSize, size, %install_folder%\MicMute.exe, K
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayIcon, %install_folder%\MicMute.exe
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayName, MicMute
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, DisplayVersion, %latest_ver%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, Publisher, Saif Aqqad
    RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, %reg_path%, EstimatedSize, %size%
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, UninstallString, "%install_folder%\updater.exe"
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, %reg_path%, InstallLocation, %install_folder%
}
GUI_spawn(prog,txt){
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
}
GUI_destroy(){
    Gui, Destroy
    GUI_state := 0
}