class Updater {
    latestVersionInfo:= { "scoop": { "url": "https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/micmute.json"
                                  , "prop": "version" }
                       , "github": { "url": "https://api.github.com/repos/SaifAqqad/AHK_MicMute/releases/latest"
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
        if(!this.isInternetConnected()){
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
        if(!latestInfo){
            this.logError("Failed to fetch latest release info")
            return -1
        }

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
            FileRead, actualHash, % this.installDir . "latest_MicMute.sha256"
            downloadedHash:= this.getFileHash(this.installDir . "latest_MicMute.exe")
            if(actualHash != downloadedHash){
                this.logError("Hash mismatch.`nExpected: " actualHash " Got: " downloadedHash)
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
        this.loggerFunc.call("Waiting for powershell to finish...")
        psScript = 
        ( LTrim Join`s
            "& {
                scoop update;
                scoop update micmute;
                Write-Host -NoNewLine 'Press any key to exit...';
                $null=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                Exit $LASTEXITCODE;
            }"
        )
        RunWait, Powershell.exe -NoProfile -NonInteractive -Command %psScript%, %A_ScriptDir%, UseErrorLevel, powershellPID
        if(ErrorLevel){
            this.logError("Scoop update failed")
            return -1
        }
        arg_installPath.= "\..\current"
        this.loggerFunc.call("Scoop update successful", 1)
        return 0
    }

    logError(err){
        this.loggerFunc.call("Error: " err, -1)
    }

    CheckForUpdates(isBackground:=1){
        if(!this.isInternetConnected()){
            this.loggerFunc.call("No internet connection")
            return
        }
        latestVersion:= this.getLatestVersion()
        if(latestVersion && VerCompare(latestVersion, A_Version) > 0){
            if(isBackground){
                TrayTip, MicMute, % "A new version of MicMute is available, click 'Check for updates' in the tray menu to update"
                onUpdateState(mic_controllers[1])
            }
            return latestVersion
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
        if(!this.isInternetConnected()){
            this.loggerFunc.call("No internet connection")
            return
        }
        infoJson := this.latestVersionInfo[this.installationMethod]
        return this.getPropFromURL(infoJson.url, infoJson.prop) 
    }

    getPropFromURL(url, prop){
        util_log("[Updater] Fetching " prop " from " url)
        obj:= this.getObjFromURL(url)
        return obj[prop]
    }

    getObjFromURL(url){
        try {
            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", url, true)
            http.Send()
            http.WaitForResponse()
            obj:= JSON.Load(http.ResponseText)
            ObjRelease(http)
            return obj
        } catch err {
            this.logError("Failed to fetch " url "`n" err.message)
            return ""
        }
    }

    cleanUp(){
        Try FileDelete, % this.installDir . "latest_MicMute.exe"
        Try FileDelete, % this.installDir . "latest_MicMute.sha256"
    }

    isInternetConnected(){
        if(!DllCall("Wininet.dll\InternetGetConnectedState", "Str", 0x43, "Int", 0))
            return 0
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        try{
            http.Open("HEAD", "https://api.github.com", false)
            http.send()
        }catch e {
            ObjRelease(http)
            return 0
        }
        is_success:= http.Status == 200
        ObjRelease(http)
        return is_success
    }

    downloadToFile(url, name){
        UrlDownloadToFile, % url, % this.installDir . "\" . name
    }
}
