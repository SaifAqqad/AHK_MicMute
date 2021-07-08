class VersionChecker{
    static scoop_manifest_url:= "https://github.com/lukesampson/scoop-extras/raw/master/bucket/micmute.json"
    , github_latest_url:=  "https://api.github.com/repos/SaifAqqad/AHK_MicMute/releases/latest"
    , isScoopInstall:= InStr(A_ScriptFullPath, A_UserName "\scoop")

    getLatestVersion(){
        try{
            return VersionChecker.isScoopInstall? VersionChecker.getPropFromURL(VersionChecker.scoop_manifest_url, "version") 
                : VersionChecker.getPropFromURL(VersionChecker.github_latest_url, "tag_name")
        }catch{
            MsgBox, 16, MicMute, An error occured while fetching the latest version
        }
    }

    getPropFromURL(url, prop){
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, true)
        http.Send()
        http.WaitForResponse()
        obj:= JSON.load(http.ResponseText)
        ObjRelease(http)
        return obj[prop]
    }
    
    CheckForUpdates(isTray:=0){
        latestVer:= VersionChecker.getLatestVersion()
        if(!latestVer)
            return
        if(latestVer != A_Version){
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