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

; Returns true if the file is empty (size = 0)
util_IsFileEmpty(file){
    FileGetSize, size , %file%
    return !size
}

; Creates a scheduled task to run micmute at user login
util_CreateStartupTask(){
    scheduler:= ComObjCreate("Schedule.Service")
    scheduler.Connect()
    task:= scheduler.NewTask(0) ;TaskDefinition object
    task.RegistrationInfo.Description:= "Launch MicMute on startup"
    task.Settings.ExecutionTimeLimit:= "PT0S" ;enable the task to run indefinitely
    trigger:= task.Triggers.Create(9) ;onLogon trigger = 9
    trigger.UserId:= A_ComputerName . "\" . A_UserName
    trigger.Delay:= "PT10S"
    task.Principal.RunLevel:= A_IsAdmin
    task.Actions.Create(0).Path:= A_ScriptFullPath ; action run executable = 0
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