class VersionChecker{
    static scoop_manifest_url:= "https://github.com/lukesampson/scoop-extras/raw/master/bucket/micmute.json"
    , github_latest_url:=  "https://api.github.com/repos/SaifAqqad/AHK_MicMute/releases/latest"
    , isScoopInstall:= InStr(A_ScriptFullPath, A_UserName "\scoop")

    getLatestVersion(){
        return VersionChecker.isScoopInstall? VersionChecker.getPropFromURL(VersionChecker.scoop_manifest_url, "version") 
            : VersionChecker.getPropFromURL(VersionChecker.github_latest_url, "tag_name")
    }

    getPropFromURL(url, prop){
        util_log("[VersionChecker] Fetching " prop " from " url)
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, true)
        http.Send()
        http.WaitForResponse()
        obj:= cJson.loads(http.ResponseText)
        ObjRelease(http)
        return obj[prop]
    }
    
    CheckForUpdates(isTray:=0){
        static isRetry:= 0
        util_log("[VersionChecker] Checking for updates...")
        Try {
            if(!DllCall("Wininet.dll\InternetGetConnectedState", "Str", 0x43, "Int", 0)){ ; no internet
                util_log("[VersionChecker] No internet connection")
                if(!isTray && !isRetry){ ; retry after 1min if auto checking for updates
                    util_log("[VersionChecker] Retrying in 1 minute...")
                    cfunc:= ObjBindMethod(VersionChecker, "CheckForUpdates")
                    SetTimer, % cfunc, -60000
                    isRetry:= 1
                    return
                }
                Throw, Exception("No internet connection") 
            }
            latestVer := VersionChecker.getLatestVersion()
        }catch err{
            util_log("[VersionChecker] An error occured: " err.Message)
            if(isTray){
                MsgBox, 16, MicMute, An error occured while fetching the latest version
            }
            return
        }        
        util_log("[VersionChecker] latest version: " latestVer)
        if(latestVer && latestVer != A_Version){
            txt:= "A new version of MicMute is available`n"
            if(VersionChecker.isScoopInstall)
                MsgBox, 64, MicMute, % txt 
                    . "You can update by running 'scoop update micmute' from powershell"
            else
                MsgBox, 68, MicMute, %txt%Do you want to download the update from GitHub?
            IfMsgBox, OK
                return
            IfMsgBox, No
                return
            Run, https://github.com/SaifAqqad/AHK_MicMute/releases/latest
        }else if(isTray){
            MsgBox, 64, MicMute, You have the latest version installed
        }
    }
}