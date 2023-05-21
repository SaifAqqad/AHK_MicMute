#Requires AutoHotkey v1.1.35+

#Include, %A_ScriptDir%\IPC.ahk
#Include, %A_ScriptDir%\AuraSync.ahk
#Include, %A_ScriptDir%\..\..\ahkpm-modules\github.com\G33kDude\cJson.ahk\Dist\JSON.ahk

#NoEnv
#Persistent
#NoTrayIcon
#ErrorStdOut UTF-16
#SingleInstance, ignore

global parentPID := A_Args[1]
    , servicePID:= DllCall("GetCurrentProcessId")
    , auraReady := false
    , tasks:= []

if (!parentPID || parentPID == servicePID)
    ExitService(-1)

OnError(Func("ExitService"))

; Set tasks timer
SetTimer, RunTasks, 160

; Register IPC handler
IPC_SetHandler(Func("AddTask"))

; Initialize Aura Sync
global aura := new AuraSync()
auraReady := true

AddTask(parentHwnd, data){
    ; Parse JSON
    data := JSON.Load(data)
    if (data == "")
        return

    ; Add task to queue
    tasks.Push(data)
}

RunTasks(){
    ; Check if parent process is dead
    Process, Exist, %parentPID%
    if (!ErrorLevel)
        ExitService()

    if (!auraReady || tasks.Length() = 0)
        return

    task := tasks.RemoveAt(1)

    if (task.type == "setAllDevicesColor")
        Try aura.setAllDevicesColor(AuraSync.hexToBgr(task.color), task.releaseDelay)
    else if (task.type == "releaseControl")
        Try aura.releaseControl()
    else if (task.type == "stopService")
        ExitService()
}

ExitService(errorCode:=0) {
    ExitApp, %errorCode%
}