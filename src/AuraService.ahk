#Requires AutoHotkey v1.1.35+

#Include, <IPC>
#Include, <AuraSync>
#Include, %A_ScriptDir%\..\ahkpm-modules\github.com\G33kDude\cJson.ahk\Dist\JSON.ahk

#NoEnv
#Persistent
#NoTrayIcon
#ErrorStdOut UTF-16
#SingleInstance, Off

global parentPID := A_Args[1]
    , servicePID:= DllCall("GetCurrentProcessId")
    , auraReady := false
    , tasks:= []
    , lastTask

if (!parentPID || parentPID == servicePID)
    ExitService(-1)

OnError(Func("ExitService"))

; Set tasks timer
SetTimer, RunTasks, 60

; Register IPC handler
IPC_SetHandler(Func("AddTask"))

; Initialize Aura Sync
global aura := new AuraSync()
auraReady := true

AddTask(parentHwnd, data){
    Critical, On
    ; Parse JSON
    data := JSON.Load(data)
    if (data == "")
        return

    ; Add task to queue
    if(tasks.Length() == 2)
        tasks.Pop()
    tasks.Push(data)
    Critical, Off
}

RunTasks(){
    ; Check if parent process is dead
    Process, Exist, %parentPID%
    if (!ErrorLevel)
        ExitService()

    if (!auraReady || tasks.Length() = 0)
        return

    if(aura.isReleasingControl)
        return

    task := tasks.RemoveAt(1)

    Try {
        switch task.type {
            case "setAllDevicesColor":
                aura.setAllDevicesColor(AuraSync.hexToBgr(task.color), task.releaseDelay)
                lastTask := task
            case "resetService":
                aura.releaseControl()
                if (lastTask.releaseDelay == 0)
                    tasks.Push(lastTask)
            case "pauseService":
                aura.releaseControl()
            case "stopService":
                ExitService()
        }
    }
}

ExitService(errorCode:=0) {
    aura.releaseControl()
    ExitApp, %errorCode%
}