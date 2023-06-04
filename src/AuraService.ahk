#Requires AutoHotkey v1.1.35+

#Include, <IPC>
#Include, <AuraSync>
#Include, <WinUtils>
#Include, %A_ScriptDir%\..\ahkpm-modules\github.com\G33kDude\cJson.ahk\Dist\JSON.ahk

#NoEnv
#Persistent
#NoTrayIcon
#ErrorStdOut UTF-16
#SingleInstance, Off

SetBatchLines, -1

global parentPID := A_Args[1]
    , servicePID:= DllCall("GetCurrentProcessId")
    , auraReady := false
    , tasks:= []
    , lastTask
    , A_IsDebug := A_Args[2] = "/debug"

global parentHwnd := util_getMainWindowHwnd(parentPID)

if (!parentPID || parentPID == servicePID)
    ExitService(-1)

OnError(Func("ExitService"))

; Register IPC handler
IPC_SetHandler(Func("AddTask"))

; Initialize Aura Sync
global currentTicks := A_TickCount
global aura := new AuraSync()

IPC_Send(parentHwnd, "Aura Sync initialized successfully in " A_TickCount - currentTicks " ms", 50)
IPC_Send(parentHwnd, "auraReady", 50)

; Set tasks timer
SetTimer, RunTasks, 60

AddTask(parentHwnd, data){
    Critical, On
    if (!data)
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

    if (tasks.Length() = 0)
        return

    if(aura.isReleasingControl)
        return

    task := tasks.RemoveAt(1)

    if(A_IsDebug)
        currentTicks := A_TickCount

    if (!IsObject(task)) {
        task := JSON.Load(task)
    }

    Try {
        switch task.type {
            case "setAllDevicesColor":
                aura.setAllDevicesColor(AuraSync.hexToBgr(task.color))
                lastTask := task
            case "resetService":
                aura.releaseControl()
                tasks.Push(lastTask)
            case "pauseService":
                aura.releaseControl()
                lastTask := ""
            case "stopService":
                ExitService()
        }
    }
    
    if(A_IsDebug)
        IPC_Send(parentHwnd, "Task " util_toString(task) " took " A_TickCount - currentTicks " ms", 50)
}

ExitService(errorCode:=0) {
    if(IsObject(errorCode)){
        IPC_Send(parentHwnd, "An error occured: " errorCode.Message, 50)
        errorCode := 1
    }
    aura.releaseControl()
    ExitApp, %errorCode%
}