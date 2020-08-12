<h1 align="center">
  AHK_MicMute
</h1>
<p align="center">
  Control your microphone using keyboard/mouse shortcuts.
</p>

## Usage
A config file will be created the first time you run the Script:
```ini
[settings]
Microphone=""
MuteHotkey=""
UnmuteHotkey=""
PushToTalk=
SoundFeedback=
OnscreenFeedback=
ExcludeFullscreen=
UpdateWithSystem=
```

1. `Microphone` can be any substring of your microphone's name or the controller's name as shown in this image:
   <details><summary>image</summary>

   ![](./resources/Controlpaneldialog.png)

   </details>
   
   you can also leave it as `""` to select the default microphone
### 
2. Both `MuteHotkey` and `UnmuteHotkey` can be any hotkey supported by AHK, use this [List of keys](https://www.autohotkey.com/docs/KeyList.htm) as a reference, you can also combine them with [hotkey modifiers](https://www.autohotkey.com/docs/Hotkeys.htm#Symbols).

   You can set both to the same hotkey to make it a toggle.


   Examples: `"<^M"`: left ctrl+M, `"RShift"`: right shift, `"^!T"`: ctrl+alt+T, `"LControl & XButton1"`: left ctrl+ mouse 4


3. Set `PushToTalk` to `1` to enable PTT,  `MuteHotkey` and `UnmuteHotkey` need to be set to the same hotkey first.

4. Both `SoundFeedback` and `OnscreenFeedback` can be set to either `0` or `1`, you can also set `ExcludeFullscreen` to 1 to stop the OSD from showing on top of fullscreen applications
   <details><summary>On screen feedback</summary>

   ![](./resources/OSD.gif)

   </details>
   
5. If `UpdateWithSystem` is set to 1, the tray icon will update whenever the microphone is muted/unmuted by the OS or other applications, it increases CPU usage by 1% at most

   
### 
<details><summary>Example of a correct config</summary>

```ini
[settings]
Microphone="amazonbasics"
MuteHotkey="*RShift"
UnmuteHotkey="*RShift"
PushToTalk=0
SoundFeedback=1
OnscreenFeedback=1
ExcludeFullscreen=0
UpdateWithSystem=1
```           

</details>

### You can always edit the config file by clicking on *Edit config* from the tray menu.

## Install using [Scoop](https://scoop.sh)

1. Install scoop using powershell
    
        iwr -useb get.scoop.sh | iex
2. Add my bucket to scoop
        
        scoop install git
        scoop bucket add utils https://github.com/SaifAqqad/utils.git
3. Install MicMute

        scoop install micmute

#### Note: If you Install the application using scoop, it will run at startup, you can disable this from task manager.
