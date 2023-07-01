; Returns the full path to the program associated with a given extension
util_GetFileAssoc(extension){
    VarSetCapacity(numChars, 4)
    DllCall("Shlwapi.dll\AssocQueryStringW", "UInt", 0x0, "UInt"
        , 0x2, "WStr", "." . extension, "Ptr", 0, "Ptr", 0, "Ptr", &numChars)
    numChars:= NumGet(&numChars, 0, "UInt")
    VarSetCapacity(progPath, numChars*2)
    DllCall("Shlwapi.dll\AssocQueryStringW", "UInt", 0x0, "UInt"
        , 0x2, "WStr", "." . extension, "Ptr", 0, "Ptr", &progPath, "Ptr", &numChars)
    return StrGet(&progPath,NumGet(&numChars, 0, "UInt"),"UTF-16")
}

; Creates a scheduled task to run micmute at user login
util_CreateStartupTask(){
    scheduler:= ComObjCreate("Schedule.Service")
    scheduler.Connect()

    task:= scheduler.NewTask(0) ; TaskDefinition object
    task.RegistrationInfo.Description:= "Launch MicMute on startup"
    task.Settings.ExecutionTimeLimit:= "PT0S" ; Enable the task to run indefinitely
    task.Settings.DisallowStartIfOnBatteries:= 0
    task.Settings.StopIfGoingOnBatteries:= 0
    task.Principal.RunLevel:= A_IsAdmin

    trigger:= task.Triggers.Create(9) ; onLogonTrigger = 9
    trigger.UserId:= A_ComputerName . "\" . A_UserName
    trigger.Delay:= "PT10S"

    action:= task.Actions.Create(0) ; ExecAction = 0
    action.Path:= A_ScriptFullPath
    action.Arguments:= args_str
    action.WorkingDirectory:= A_ScriptDir

    try scheduler.GetFolder("\").RegisterTaskDefinition("MicMute",task,6,"","",3)
    catch {
        return 0
    }
    return 1
}

; Deletes the scheduled task
util_DeleteStartupTask(){
    scheduler:= ComObjCreate("Schedule.Service")
    scheduler.Connect()
    Try scheduler.GetFolder("\").DeleteTask("MicMute",0)
    return 1
}

; Returns 1 if the scheduled task exists
util_StartupTaskExists(){
    scheduler:= ComObjCreate("Schedule.Service")
    scheduler.Connect()
    Try task:= scheduler.GetFolder("\").GetTask("MicMute")
    return task? 1:0
}

; by jeeswg,jNizM : https://www.autohotkey.com/boards/viewtopic.php?t=43417
util_isProcessElevated(vPID){
    ;PROCESS_QUERY_LIMITED_INFORMATION := 0x1000
    if !(hProc := DllCall("kernel32\OpenProcess", "UInt",0x1000, "Int",0, "UInt",vPID, "Ptr"))
        return -1
    ;TOKEN_QUERY := 0x8
    hToken := 0
    if !(DllCall("advapi32\OpenProcessToken", "Ptr",hProc, "UInt",0x8, "Ptr*",hToken))
    {
        DllCall("kernel32\CloseHandle", "Ptr",hProc)
        return -1
    }
    ;TokenElevation := 20
    vIsElevated := vSize := 0
    vRet := (DllCall("advapi32\GetTokenInformation", "Ptr",hToken, "Int",20, "UInt*",vIsElevated, "UInt",4, "UInt*",vSize))
    DllCall("kernel32\CloseHandle", "Ptr",hToken)
    DllCall("kernel32\CloseHandle", "Ptr",hProc)
    return vRet ? vIsElevated : -1
}

util_getRunningProcesses(includeHidden:=0) {
    static _sysProcesses := new StackSet("svchost.exe", "explorer.exe", "Taskmgr.exe", "SystemSettings.exe")

    _hiddenValue:= A_DetectHiddenWindows
    if (includeHidden)
        DetectHiddenWindows, On

    pSet:= {}
    WinGet, pList, List
    loop %pList%
    {
        pHwnd:= pList%A_Index%

        WinGet, pPath, ProcessPath, ahk_id %pHwnd%
        if (!pPath)
            continue
        pSplitPath := util_splitPath(pPath)

        if(pSplitPath.fileExt != "exe" || pSet.HasKey(pSplitPath.fileName) || _sysProcesses.exists(pSplitPath.fileName))
            continue

        WinGetTitle, pTitle, ahk_id %pHwnd%
        pInfo:= util_getFileInfo(pPath)

        pSet[pSplitPath.fileName] := { hwnd: pHwnd
            , path: pPath
            , name: pSplitPath.fileName
            , title: pTitle
            , description: pInfo.FileDescription }
    }
    DetectHiddenWindows, % _hiddenValue

    return pSet
}

util_getFileInfo(lptstrFilename) {
    List := "Comments InternalName ProductName CompanyName LegalCopyright ProductVersion"
        . " FileDescription LegalTrademarks PrivateBuild FileVersion OriginalFilename SpecialBuild"
    dwLen := DllCall("Version.dll\GetFileVersionInfoSize", "Str", lptstrFilename, "Ptr", 0)
    dwLen := VarSetCapacity( lpData, dwLen + A_PtrSize)
    DllCall("Version.dll\GetFileVersionInfo", "Str", lptstrFilename, "UInt", 0, "UInt", dwLen, "Ptr", &lpData)
    DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\VarFileInfo\Translation", "PtrP", lplpBuffer, "PtrP", puLen )
    sLangCP := Format("{:04X}{:04X}", NumGet(lplpBuffer+0, "UShort"), NumGet(lplpBuffer+2, "UShort"))
    i := {}
    Loop, Parse, % List, %A_Space%
        DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\StringFileInfo\" sLangCp "\" A_LoopField, "PtrP", lplpBuffer, "PtrP", puLen )
            ? i[A_LoopField] := StrGet(lplpBuffer, puLen) : ""
    return i
}

util_getAhkMainWindowHwnd(p_pid){
    WinWait, % "ahk_pid " p_pid, , 1

    ; list all windows
    windowList := util_getWindowList("ahk_pid " p_pid)

    for i, window in windowList {
        if(window.class == "AutoHotkey")
            return window.hwnd
    }

    return windowList[1].hwnd
}

util_getWindowList(winTitle){
    list:= Array()

    DetectHiddenWindows, On
    WinGet, winList, List, % winTitle
    Loop, % winList {
        winHwnd:= winList%A_Index%
        WinGetTitle, winTitle, % "ahk_id " winHwnd
        WinGetClass, winClass, % "ahk_id " winHwnd
        list.Push({"hwnd": winHwnd, "title": winTitle, "class": winClass})
    }
    DetectHiddenWindows, Off

    return list
}

; Returns the current system theme | 0 : light mode, 1 : dark mode
util_getSystemTheme(){
    RegRead, reg
        , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    sysTheme := !reg

    RegRead, reg
        , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
    appsTheme := config_obj.PreferTheme == -1? !reg : config_obj.PreferTheme

    return {"System": sysTheme, "Apps": appsTheme}
}

; By lexikos https://www.autohotkey.com/boards/viewtopic.php?p=49047#p49047
util_indexOfIconResource(Filename, ID)
{
    hmod := DllCall("GetModuleHandle", "str", Filename, "ptr")
    ; If the DLL isn't already loaded, load it as a data file.
    loaded := !hmod
        && hmod := DllCall("LoadLibraryEx", "str", Filename, "ptr", 0, "uint", 0x2, "ptr")

    enumproc := RegisterCallback("util_indexOfIconResource_EnumIconResources","F")
    param := {ID: ID, index: 0, result: 0}

    ; Enumerate the icon group resources. (RT_GROUP_ICON=14)
    DllCall("EnumResourceNames", "ptr", hmod, "ptr", 14, "ptr", enumproc, "ptr", &param)
    DllCall("GlobalFree", "ptr", enumproc)

    ; If we loaded the DLL, free it now.
    if loaded
        DllCall("FreeLibrary", "ptr", hmod)

    return param.result
}

util_indexOfIconResource_EnumIconResources(hModule, lpszType, lpszName, lParam)
{
    param := Object(lParam)
    param.index += 1

    if (lpszName = param.ID)
    {
        param.result := param.index
        return false ; break
    }
    return true
}

; Returns true if the file is empty
util_IsFileEmpty(file){
    FileGetSize, size , %file%
    return !size
}

; returns an object with seperate parts of the input path
util_splitPath(p_input){
    SplitPath, p_input, _t1, _t2, _t3, _t4, _t5
    return { "fileName":_t1
        , "filePath":_t2
        , "fileExt":_t3
        , "fileNameNoExt":_t4
        , "fileDrive":_t5}
}

util_getFileSemVer(file){
    FileGetVersion, _t1, %file%
    RegExMatch(_t1, "^([0-9]+)\.([0-9]+)\.([0-9]+)((\.([0-9]+))+)?$", _match)
    return Format("{}.{}.{}", _match1,_match2,_match3)
}

util_log(msg){
    static logNum:=0
    msg:= Format("#{:i} {}: {}`n", ++logNum, A_TickCount, IsObject(msg)? "Error: " . msg.Message : msg)
    A_log.= msg
    Try FileOpen(arg_logFile, "a").Write(msg)
}

util_toString(obj){
    if(!IsObject(obj))
        return obj . ""
    isArray := obj.Length()? 1 : 0
    output_str := isArray? "[ ": "{ "
    for key, val in obj {
        output_str.= (isArray? "" : (key . ": ")) . util_toString(val) . ", "
    }
    if(InStr(output_str, ","))
        output_str:= SubStr(output_str, 1, -2) . " "
    output_str .= isArray? "]": "}"
    return output_str
}

util_firstNonEmpty(params*) {
    for _, param in params
        if (param && Trim(param))
            return param
    return ""
}

; VerCmp() for Windows by SKAN on D35T/D37L @ tiny.cc/vercmp
util_VerCmp(V1, V2) {
    return ( ( V1 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V1 . "...", ".",, 5)*) )
        < ( V2 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V2 . "...", ".",, 5)*) ) )
        ? -1 : ( V2<V1 ) ? 1 : 0
}