#Requires AutoHotkey v1.1.36+

#Include, <IPC>
#Include, <AuraSync>
#Include, <WinUtils>
#Include, %A_ScriptDir%\..\ahkpm-modules\github.com\SaifAqqad\cJson.ahk\Dist\JSON.ahk

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

global parentHwnd := util_getAhkMainWindowHwnd(parentPID)

if (!parentPID || parentPID == servicePID)
    ExitService(-1)

OnError(Func("logMsg"), -1)

logMsg("AuraService started")

; Register IPC handler
IPC_SetHandler(Func("AddTask"))

if (!AuraSync.isInstalled()){
    logMsg("Aura Sync is not installed")
    ExitService(-1)
}

; Initialize Aura Sync
global currentTicks := A_TickCount
global aura := new AuraSync()

logMsg("Aura Sync initialized in " A_TickCount - currentTicks " ms")
logMsg("auraReady")

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

    if (task && !IsObject(task)) {
        try task := JSON.Load(task)
    }

    Try {
        switch task.type {
            case "setAllDevicesColor":
                aura.setAllDevicesColor(AuraSync.hexToBgr(task.color))
                lastTask := task
            case "resetService":
                aura.releaseControl()
                Sleep, 100
                tasks := [{type: "startService"}, lastTask]
            case "startService":
                aura.takeControl()
                Sleep, 100
            case "pauseService":
                aura.releaseControl()
                lastTask := ""
                Sleep, 100
            case "stopService":
                ExitService()
        }
    }
    
    logMsg("Task " util_toString(task) " took " A_TickCount - currentTicks " ms", true)
}

ExitService(errorCode:=0) {
    if (IsObject(errorCode))
        errorCode := 1
    logMsg("AuraService Exiting with errorCode " errorCode)

    aura.releaseControl()
    ExitApp, %errorCode%
}

logMsg(msg, debugOnly:=0) {
    if (IsObject(msg))
        msg := "Exception: " msg.Message

    if(!debugOnly || A_IsDebug)
        IPC_Send(parentHwnd, msg, 50)
}