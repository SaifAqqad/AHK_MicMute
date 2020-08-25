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
global mute_ico, default_ico
global mute_sound:="assets\mute.mp3", unmute_sound:="assets\unmute.mp3"
global startup_shortcut:= A_AppData . "\Microsoft\Windows\Start Menu\Programs\Startup\MicMute.lnk"
show_feedback(){
    if (current_config.OnscreenFeedback){
        if (global_mute)
            OSD_spawn("Microphone Muted", "DC3545", current_config.ExcludeFullscreen)
        else
            OSD_spawn("Microphone Online", "007BFF", current_config.ExcludeFullscreen)
    }
    if (current_config.SoundFeedback){
        SoundPlay,% global_mute? mute_sound : unmute_sound
    }
}
update_tray(){
    Menu, Tray, Icon, % global_mute? mute_ico : default_ico
    Menu, Tray, Tip, % global_mute? "Microphone Muted" : "Microphone Online"
}
init_tray(){
    RegRead, sysTheme
    , HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    default_ico:= sysTheme? "assets\default_black.ico" : "assets\default_white.ico"
    mute_ico:= sysTheme? "assets\mute_black.ico" : "assets\mute_white.ico"
    if (FileExist(default_ico)) {
        Menu, Tray, Icon, %default_ico%
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
    if (!FileExist(startup_shortcut))
        Menu, Tray, Uncheck, Start on &boot
    else
        Menu, Tray, Check, Start on &boot
}
launch_help(){
    Run, https://github.com/SaifAqqad/AHK_MicMute#usage
}
exit(){
    ExitApp
}
auto_start(){
    if (!FileExist(startup_shortcut)){
        FileCreateShortcut, %A_ScriptFullPath%, %startup_shortcut%, %A_ScriptDir%
        Menu, Tray, Check, Start on &boot
    }else{
        FileDelete, %startup_shortcut%
        Menu, Tray, Uncheck, Start on &boot
    }
}