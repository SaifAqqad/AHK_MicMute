FileCreateDir, assets
FileInstall, .\assets\mute.mp3, assets\mute.mp3 
FileInstall, .\assets\unmute.mp3, assets\unmute.mp3
FileInstall, .\assets\default_white.ico, assets\default_white.ico 
FileInstall, .\assets\default_black.ico, assets\default_black.ico 
FileInstall, .\assets\mute_white.ico, assets\mute_white.ico 
FileInstall, .\assets\mute_black.ico, assets\mute_black.ico 
show_feedback(){
    if (OSD_feedback){
        if (global_mute)
            OSD_spawn("Microphone Muted", "DC3545", exclude_fullscreen)
        else
            OSD_spawn("Microphone Online", "007BFF", exclude_fullscreen)
    }
    if (sound_feedback){
        SoundPlay,% global_mute? "assets\mute.mp3" : "assets\unmute.mp3"
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
    Menu, Tray, Add, &Toggle Microphone, toggle_hotkey
    Menu, Tray, Add, &Edit Config, edit_config
    Menu, Tray, Add, &Help, launch_help
    Menu, Tray, Add, E&xit, exit
    Menu, Tray, Click, 1.
    Menu, Tray, Default, 1&
}
launch_help(){
    Run, https://github.com/SaifAqqad/AHK_MicMute#usage
}
exit(){
    ExitApp
}