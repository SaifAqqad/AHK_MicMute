
; the following uses BinMod https://github.com/AutoHotkey/Ahk2Exe/blob/master/BinMod.ahk
; and ScriptGuard1 https://www.autohotkey.com/boards/viewtopic.php?f=6&t=80229
; to disguise that micmute is an autohotkey compiled script
;@Ahk2Exe-Obey U_au, = "%A_IsUnicode%" ? 2 : 1 
;@Ahk2Exe-PostExec "BinMod.exe" "%A_WorkFileName%"
;@Ahk2Exe-Cont  "1%U_au%2.>AUTOHOTKEY SCRIPT<. MICMUTE           "
;@Ahk2Exe-Cont  "%U_au%.AutoHotkeyGUI.MicMute_UI"
;@Ahk2Exe-PostExec "BinMod.exe" "%A_WorkFileName%" "11.UPX." "1.UPX!.", 2

; ------------------------------  ScriptGuard1  --------------------------------
ScriptGuard1()                    ; Hides AutoHotkey source in compiled scripts
{ ; By TAC109, Edition: 23Aug2020 ; To use just include this code in your script
  static _ := ScriptGuard1()      ; Is automatically actioned when script starts
  local ahk:=">AUTOHOTKEY SCRIPT<", pt:=rc:=sz:=0
  if A_IsCompiled                 ; See bit.ly/ScriptGuard for more details
  { if (rc:=DllCall("FindResource",  "Ptr",0, "Str",ahk, "Ptr",10, "Ptr"))
    && (sz:=DllCall("SizeofResource","Ptr",0, "Ptr",rc,  "Uint"))
    && (pt:=DllCall("LoadResource",  "Ptr",0, "Ptr",rc,  "Ptr"))
    && (pt:=DllCall("LockResource",  "Ptr",pt,"Ptr"))
    && (DllCall("VirtualProtect", "Ptr",pt, "Ptr",sz, "UInt",0x40, "UInt*",rc))
      DllCall("RtlZeroMemory", "UInt",pt, "Int",sz) ; Wipe script from memory
    else MsgBox 64,,% "Warning: ScriptGuard1 not active!`n`nError = "
      . (A_LastError=1814 ? ("Resource Name '" ahk "' not found.`nTo fix, see "
      . "the 'Example 1' comments at http://bit.ly/BinMod.") : A_LastError)
} }                               ; For additional security, see bit.ly/BinMod
; ------------------------------------------------------------------------------
