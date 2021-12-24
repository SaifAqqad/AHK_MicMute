class Updater {
    latestVersionInfo:= { "scoop": { "url": "https://github.com/lukesampson/scoop-extras/raw/master/bucket/micmute.json"
                                  , "prop": "version" }
                       , "github": { "url": "https://api.github.com/repos/SaifAqqad/exampleRepo/releases/latest"
                                  , "prop": "tag_name" }}

    __New(installDir, loggerFunc:="", skipHashCheck:=0){
        this.installDir:= installDir "\"
        this.loggerFunc:= loggerFunc
        this.skipHashCheck:= skipHashCheck
        this.installationMethod:= InStr(this.installDir, A_UserName "\scoop")? "scoop": "github"
    }

    update(){
        if(InStr(this.installDir, A_ScriptDir))
            return -2
        if(!DllCall("Wininet.dll\InternetGetConnectedState", "Str", 0x43, "Int", 0)){ ; no internet connection
            this.logError("No internet connection")
            return -5
        }
        updateFunc:= this.installationMethod . "Update"
        if(IsObject(this[updateFunc]))
            return this[updateFunc]()
        return -3
    }

    githubUpdate(){
        latestInfo:= this.getObjFromURL(this.latestVersionInfo.github.url)
        version:= latestInfo.tag_name
        this.loggerFunc.call("Updating MicMute to v" + version)
        for i, asset in latestInfo.assets {
            switch asset.name {
                case "MicMute.exe", "MicMute.sha256":
                    this.loggerFunc.call("Downloading " asset.name " (" asset.size/1024/1024 " MB)")
                    Try this.downloadToFile(asset.browser_download_url, "latest_" . asset.name)
                    catch err{
                        this.logError("Downloading " asset.name " failed (" err.message ")")
                        this.cleanUp()
                        return -1
                    }
            }
        }
        if(FileExist(this.installDir . "latest_MicMute.sha256") && !this.skipHashCheck){
            this.loggerFunc.call("Checking hash of MicMute.exe")
            FileRead, latest_hash, % this.installDir . "latest_MicMute.sha256"
            downloadedHash:= this.getFileHash(this.installDir . "latest_MicMute.exe")
            if(latest_hash != downloadedHash){
                this.logError("Hash mismatch.`nExpected: " latest_hash " Got: " downloadedHash)
                this.cleanUp()
                return -1
            }
            this.loggerFunc.call("Hash matches")
        }
        this.loggerFunc.call("Replacing the executable")
        Filecopy, % this.installDir "latest_MicMute.exe", % this.installDir "MicMute.exe", 1
        this.cleanUp()
        this.loggerFunc.call("MicMute Updated successfully", 1)
        return 0
    }

    scoopUpdate(){
        this.loggerFunc.call("Running 'scoop update micmute' in powershell")
        psScript = "& {scoop update;scoop update micmute;Write-Host -NoNewLine 'Press any key to exit...';$null=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');Exit $LASTEXITCODE;}"
        RunWait, Powershell.exe -NoProfile -NonInteractive -Command %psScript%, %A_ScriptDir%, UseErrorLevel, powershellPID
        if(ErrorLevel){
            this.logError("Scoop update failed")
            return -1
        }
        arg_installPath.= "..\current"
        this.loggerFunc.call("Scoop update successful", 1)
        return 0
    }

    logError(err){
        this.loggerFunc.call("Error: " err, -1)
    }

    CheckForUpdates(isTray:=0){
        static isRetry:= 0
        util_log("[Updater] Checking for updates...")
        Try {
            if(!DllCall("Wininet.dll\InternetGetConnectedState", "Str", 0x43, "Int", 0)){ ; no internet
                util_log("[Updater] No internet connection")
                if(!isTray && !isRetry){ ; retry after 1min if auto checking for updates
                    util_log("[Updater] Retrying in 1 minute...")
                    cfunc:= ObjBindMethod(Updater, "CheckForUpdates")
                    SetTimer, % cfunc, -60000
                    isRetry:= 1
                    return
                }
                Throw, Exception("No internet connection") 
            }
            latestVer := this.getLatestVersion()
        }catch err{
            util_log("[Updater] An error occured: " err.Message)
            if(isTray){
                MsgBox, 16, MicMute, An error occured while fetching the latest version
            }
            return
        }        
        util_log("[Updater] latest version: " latestVer)
        if(latestVer && latestVer != A_Version){
            txt:= "A new version of MicMute is available`n"
            MsgBox, 68, MicMute, %txt%Do you want to download the update from GitHub?
            IfMsgBox, OK
                return
            IfMsgBox, No
                return
            runUpdater()
        }else if(isTray){
            MsgBox, 64, MicMute, You have the latest version installed
        }
    }

    getFileHash(file){
        psScript = "& {(Get-FileHash '%file%').Hash > temp_hash.txt }"
        RunWait, Powershell.exe -NoProfile -NonInteractive -Command %psScript%, %A_ScriptDir%, Hide, powershellPID
        FileRead, hash, %A_ScriptDir%\temp_hash.txt
        FileDelete, %A_ScriptDir%\temp_hash.txt
        return hash
    }

    getLatestVersion(){
        infoJson := this.latestVersionInfo[this.installationMethod]
        return this.getPropFromURL(infoJson.url, infoJson.prop) 
    }

    getPropFromURL(url, prop){
        util_log("[Updater] Fetching " prop " from " url)
        obj:= this.getObjFromURL(url)
        return obj[prop]
    }

    getObjFromURL(url){
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, true)
        http.Send()
        http.WaitForResponse()
        obj:= JSON.Load(http.ResponseText)
        ObjRelease(http)
        return obj
    }

    cleanUp(){
        Try FileDelete, % this.installDir . "latest_MicMute.exe"
        Try FileDelete, % this.installDir . "latest_MicMute.sha256"
    }

    downloadToFile(url, name){
        UrlDownloadToFile, % url, % this.installDir . "\" . name
    }
}