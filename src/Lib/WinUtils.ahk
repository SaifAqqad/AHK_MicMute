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
    task:= scheduler.NewTask(0) ;TaskDefinition object
    task.RegistrationInfo.Description:= "Launch MicMute on startup"
    task.Settings.ExecutionTimeLimit:= "PT0S" ;enable the task to run indefinitely
    task.Settings.DisallowStartIfOnBatteries:= 0 ;why is this enabled by default o_o
    task.Settings.StopIfGoingOnBatteries:= 0 ;bruh ^^^
    trigger:= task.Triggers.Create(9) ;onLogon trigger = 9
    trigger.UserId:= A_ComputerName . "\" . A_UserName
    trigger.Delay:= "PT10S"
    task.Principal.RunLevel:= A_IsAdmin
    action:= task.Actions.Create(0) ;ExecAction = 0
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

; VerCmp() for Windows by SKAN on D35T/D37L @ tiny.cc/vercmp
util_VerCmp(V1, V2) {
    return ( ( V1 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V1 . "...", ".",, 5)*) )
        < ( V2 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V2 . "...", ".",, 5)*) ) )
        ? -1 : ( V2<V1 ) ? 1 : 0
}