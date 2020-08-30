class AssetsLoader {
    static startup_shortcut:= A_AppData . "\Microsoft\Windows\Start Menu\Programs\Startup\MicMute.lnk"
    mute_ico:= "assets\mute_white.ico", default_ico:= "assets\default_white.ico"
    mute_sound:= "assets\mute.mp3", unmute_sound:= "assets\unmute.mp3"
    system_theme:= ; 1 -> light
    
    __New(){
        RegRead, reg, HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
        this.system_theme:= reg
        if(this.system_theme){
            this.default_ico:= "assets\default_black.ico" 
            this.mute_ico:= "assets\mute_black.ico"
        }
    }
    
    show_feedback(){
        if (current_config.SoundFeedback){
            SoundPlay,% global_mute? mute_sound : unmute_sound
        }
        if (current_config.OnscreenFeedback){
            if (global_mute)
                OSD_spawn("Microphone Muted", "DC3545", current_config.ExcludeFullscreen)
            else
                OSD_spawn("Microphone Online", "007BFF", current_config.ExcludeFullscreen)
        }
    }
    
    init_tray(){
        if (FileExist(this.default_ico)) {
            Menu, Tray, Icon, % this.default_ico
        }
        Menu, Tray, Tip, MicMute 
        Menu, Tray, NoStandard
        Menu, Tray, Add, &Toggle microphone, toggle_hotkey
        Menu, Tray, Add, &Edit configuration, edit_config
        Menu, Tray, Add, Start on &boot, auto_start
        Menu, Tray, Add, &Help, launch_help
        Menu, Tray, Add, E&xit, exit
        Menu, Tray, Click, 1.
        Menu, Tray, Default, 1&
        if (!FileExist(this.startup_shortcut))
            Menu, Tray, Uncheck, Start on &boot
        else
            Menu, Tray, Check, Start on &boot
        Return
        
        ; tray labels
        edit_config:
            current_config.edit()
        Return
        
        auto_start:
            if (!FileExist(this.startup_shortcut)){
                FileCreateShortcut, %A_ScriptFullPath%, % this.startup_shortcut, %A_ScriptDir%
                Menu, Tray, Check, Start on &boot
            }else{
                FileDelete, % this.startup_shortcut
                Menu, Tray, Uncheck, Start on &boot
            }
        Return
        
        launch_help:
            Run, https://github.com/SaifAqqad/AHK_MicMute#usage
        Return
        
        exit:
        ExitApp
    }
    
    update_tray(){
        Menu, Tray, Icon, % global_mute? this.mute_ico : this.default_ico
        Menu, Tray, Tip, % global_mute? "Microphone Muted" : "Microphone Online"
    }
    
    install_assets(){
        FileCreateDir, assets
        FileInstall, .\assets\mute.mp3, assets\mute.mp3 
        FileInstall, .\assets\unmute.mp3, assets\unmute.mp3
        FileInstall, .\assets\ptt_mute.mp3, assets\ptt_mute.mp3
        FileInstall, .\assets\ptt_unmute.mp3, assets\ptt_unmute.mp3
        FileInstall, .\assets\default_white.ico, assets\default_white.ico 
        FileInstall, .\assets\default_black.ico, assets\default_black.ico 
        FileInstall, .\assets\mute_white.ico, assets\mute_white.ico 
        FileInstall, .\assets\mute_black.ico, assets\mute_black.ico 
        FileInstall, .\assets\MicMute.ico, assets\MicMute.ico 
    }
}