; Stripped down wrapper for Bass audio library (https://www.un4seen.com)
; based on https://autohotkey.com/board/topic/33963-bass-library-extreme-ahk-multimedia-power/
class SoundPlayer {
    static BASS_STREAM_AUTOFREE := 0x40000
                ,  BASS_UNICODE := 0x80000000
    static BASS_DLLPATH := A_ScriptDir . "\", BASS_DLL:= "bass.dll"
    BASS_DLLCALL:= "", devices:=""

    __New(){
        if(!A_IsCompiled)
            this.BASS_DLLPATH.= "Lib\"
        this.BASS_DLLCALL := DllCall("LoadLibrary", Str, this.BASS_DLLPATH . this.BASS_DLL)
        DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_Init", Int, 0, Int, 44100, Int, 0, UInt, 0, UInt, 0)
        DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_SetConfig", UInt, this.BASS_UNICODE, UInt, 1)
        onExit(ObjBindMethod(this, "__free"))
        this.getDevices()
    }

    play(p_sound, volume:=1){
        static previousStream:=0
        if(!IsObject(p_sound)){
            Throw, Exception("[SoundPlayer] play: p_sound is not an object")
            return
        }
        if(previousStream) ;mute previous stream
            DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_ChannelSetAttribute", UInt, previousStream, UInt, 2, Float, 0.0)
        ; create a new stream
        flags:= this.BASS_STREAM_AUTOFREE | this.BASS_UNICODE
        if(p_sound.ptr){
            stream:= DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_StreamCreateFile"
            , UInt, 1, UInt, p_sound.ptr, UInt64, 0, UInt64, p_sound.size, UInt, flags)
        }else{
            filePath:= p_sound.file
            stream:= DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_StreamCreateFile"
            , UInt, 0, UInt, &filePath, UInt64, 0, UInt64, 0, UInt, flags)
        }
        ; play the stream on the current device
        if(stream == 0){
            err := DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_ErrorGetCode", Int) 
            Throw, Exception("[SoundPlayer] play: BASS_StreamCreateFile failed with error code (" err ")")
        }else{
            previousStream:= stream
            ; set the volume
            DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_ChannelSetAttribute", UInt, stream, UInt, 2, Float, volume)
            return DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_ChannelPlay", UInt, stream, Int, 1)
        }
    }
    
    getDevices(){
        this.devices:= Array()
        Loop {
            VarSetCapacity(devInfo, 12, 0)
            err:= DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_GetDeviceInfo", UInt, A_Index, UInt, &devInfo)
            if(!err) 
                break
            this.devices[A_Index]:= StrGet(NumGet(devInfo, 0, "UInt"),"UTF-8")
        }
        return this.devices
    }

    getDevice(){
        return this.devices[DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_GetDevice")]
    }

    setDevice(p_device){
        for i, device in this.devices {
            if(device && InStr(device, p_device)){
                this.__initDevice(i)
                return DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_SetDevice", UInt, i)
            }
        }
    }
    
    __initDevice(p_device){
        DllCall(this.BASS_DLLPATH . this.BASS_DLL . "\BASS_Init", Int, p_device, Int, 44100, Int, 0, UInt, 0, UInt, 0)
    }

    __free(){
        DllCall("FreeLibrary", UInt, this.BASS_DLLCALL)
    }
}