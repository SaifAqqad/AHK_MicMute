/* Title:	IPC
			*Inter-Process Communication*.
 :
			An AHK script or DotNet application can use this module to send text or binary data to another AHK script or DotNet application using WM_COPYDATA message.
			AHK module is implemented in IPC.ahk. DotNet library is implemented in IPC.cs. API is the same up to the language differences.

 */

/*
 Function:	 Send
			 Send the message to another process (receiver).

 Parameters:
			 Hwnd	- Handle of the receiver.
			 Data	- Data to be sent, by default empty. Optional.
			 Port	- Port, by default 100. Positive integer. Optional.
			 DataSize - If this parameter is used, Data contains pointer to the buffer holding binary data.
						Omit this parameter to send textual messages to the receiver.

 Remarks:
			The data being passed must not contain pointers or other references to objects not accessible to the script receiving the data.
			While this message is being sent, the referenced data must not be changed by another thread of the sending process.
			The receiving script should consider the data read-only. The receiving script should not free the memory referenced by Data parameter.
			If the receiving script must access the data after function returns, it must copy the data into a local buffer.

			This function uses Gui +Lastfound to obtain the handle of the sender.

 Returns:
			Returns TRUE if message was or FALSE if sending failed. Error message is returned on invalid usage.
 */
IPC_Send(Hwnd, Data, timeout:= 500) {
    static WM_COPYDATA = 74
    VarSetCapacity(Struct, 3*A_PtrSize, 0)
    
	NumPut(StrPut(Data, "utf-16")*2, &Struct, A_PtrSize)
    NumPut(&Data, Struct, A_PtrSize*2)

    DetectHiddenWindows, On
    SendMessage, %WM_COPYDATA%, %A_ScriptHwnd%, &Struct,, ahk_id %Hwnd%,,,, %timeout%
    DetectHiddenWindows, Off

    return ErrorLevel = "FAIL" ? false : true
}

/*
  Function:	 SetHandler
              Set the data handler.

  Parameters:
              Handler - Function that will be called when data is received.

  Handler:
  >			 Handler(Hwnd, Data, Port, DataSize)

             Hwnd	- Handle of the window passing data.
             Data	- Data that is received.
             Port	- Data port.
             DataSize - If DataSize is not empty, Data is pointer to the actuall data. Otherwise Data is textual message.
 */
IPC_SetHandler( Handler ){
    static WM_COPYDATA = 74

    if !IsFunc( Handler )
        return A_ThisFunc "> Invalid handler: " Handler

    OnMessage(WM_COPYDATA, "IPC_onCopyData")
    IPC_onCopyData(Handler, "")
}

IPC_onCopyData(WParam, LParam) {
    static Handler
    if Lparam =
        return Handler := WParam

    size := NumGet(Lparam+0, A_PtrSize)
    dataAddr := NumGet(Lparam+0, A_PtrSize*2)
    
    VarSetCapacity(CopyOfData, size, 0)
    CopyOfData := StrGet(dataAddr, size/2, "utf-16")

    %handler%(WParam, CopyOfData)
    return 1
}

/*
 Group: About
     o IPC AHK & .Net library ver 2.6 by majkinetor.
    o Fixes for 64b systems of IPC.cs made by Lexikos.
    o MSDN Reference: <http://msdn.microsoft.com/en-us/library/ms649011(VS.85).aspx>
    o Licenced under GNU GPL <http://creativecommons.org/licenses/GPL/2.0/>
 */