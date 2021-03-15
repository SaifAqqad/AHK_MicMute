;auto_exec begin
SetWorkingDir %A_ScriptDir%
Global conf
, watched_profiles
, current_profile
, watched_profile
, mute_sound
, unmute_sound
, ptt_on_sound
, ptt_off_sound
, sys_theme
, osd_obj
SetTimer, runUpdater, -1
SetTimer, GUI_create, -1
init()
conf.exportConfig()
if(conf.MuteOnStartup)
    setMuteState(1)
OnExit(Func("setMuteState").bind(0))
;auto_exec end

