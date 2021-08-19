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

; plays a sound file or waveform data
util_PlaySound(ByRef sound) {
    DllCall( "winmm.dll\PlaySoundW", Ptr,0, UInt,0, UInt, 0 )
    Try SoundPlay, Nonexistent.notype
    if(IsObject(sound)){
        SoundPlay, % sound.path
        return 1
    }
    return DllCall( "winmm.dll\PlaySoundW", Ptr,&sound, UInt,0, UInt, 0x7 )
}

; Reads the executable's resource to a variable
util_ResRead(ByRef var, resName, is_res:=1) {
    if(is_res){
        VarSetCapacity(var, 128), VarSetCapacity(var, 0)
        if hMod := DllCall("GetModuleHandle", UInt,0,PTR)
            if hRes := DllCall("FindResource", UInt,hMod, Str,resName, UInt,10,PTR)
                if hData := DllCall("LoadResource", UInt,hMod, UInt,hRes,PTR)
                    if pData := DllCall("LockResource", UInt,hData,PTR)
                        return VarSetCapacity(var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes,PTR))
                            , DllCall("RtlMoveMemory", Str,var, UInt,pData, UInt,nSize)
        return 1
    }
    if(!FileExist(resName))
        return 0
    SplitPath, resName,,, ext,,
    if(ext = "wav")
        FileRead, var, *c %resName%
    else
        var:= {path:resName}
    return 1
}

; Creates a scheduled task to run micmute at user login
util_CreateStartupTask(){
    scheduler:= ComObjCreate("Schedule.Service")
    scheduler.Connect()
    task:= scheduler.NewTask(0) ;TaskDefinition object
    task.RegistrationInfo.Description:= "Launch MicMute on startup"
    task.Settings.ExecutionTimeLimit:= "PT0S" ;enable the task to run indefinitely
    task.Settings.DisallowStartIfOnBatteries:= 0  ;why is this enabled by default o_o
    task.Settings.StopIfGoingOnBatteries:= 0 ;bruh ^^^
    trigger:= task.Triggers.Create(9) ;onLogon trigger = 9
    trigger.UserId:= A_ComputerName . "\" . A_UserName
    trigger.Delay:= "PT10S"
    task.Principal.RunLevel:= A_IsAdmin
    action:= task.Actions.Create(0) ;ExecAction = 0
    action.Path:= A_ScriptFullPath 
    action.WorkingDirectory:= A_ScriptDir 
    Try scheduler.GetFolder("\").RegisterTaskDefinition("MicMute",task,6,"","",3)
    Catch {
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