<h1 align="center">
 <img src="./assets/MicMute.ico" width="32" height="32"></img> 
MicMute
</h1>
<p align="center">
  Control your microphone using keyboard/mouse shortcuts.
</p>

## Features

   * Separate hotkeys for Mute/Unmute 
   * Single toggle/push-to-talk hotkey
   * Hotkeys can be (optionally) set up using AHK's syntax
   * Optional sound and on-screen feedback
   * AFK timeout (auto mute when the user is AFK for longer than a specified time interval)
   * Auto-start on boot

## Install using [Scoop](https://scoop.sh)

1. Install scoop using powershell
    
        Set-ExecutionPolicy RemoteSigned -scope CurrentUser
        iwr -useb get.scoop.sh | iex
2. Add my bucket to scoop
        
        scoop install git
        scoop bucket add utils https://github.com/SaifAqqad/utils.git
3. Install MicMute

        scoop install micmute


## Usage

On the first run, you will be asked to set up MicMute:

![](./assets/firstsetupdialog.png)

Click OK and a new configuration window will open:

![](./assets/configwindow.png)

1. Choose your microphone from the drop down list.

2. Choose whether you want Separate hotkeys for Mute and Unmute or Toggle/Push To Talk.

3. Based on your choice, you will either need to setup both hotkeys or just one of them.
        
   - Click on the empty box for the hotkey then choose the key(s) you want.
   - Check the "Wildcard" box if you want to fire the hotkey even if extra modifiers are being held down.
   - Check the "Passthrough key" box if you don't want the key's native function to be blocked (hidden from the system).
   - Check the "Advanced hotkey" box if you want to enter an AHK hotkey string instead (see [AHK docs](https://www.autohotkey.com/docs/KeyList.htm) for more info).
   
4. Choose whether you want sound feedback when muting/unmuting the microphone or on-screen feedback or both.

   <details><summary>On screen feedback</summary>
   
   ![](./assets/OSD.gif)
   
   </details>

5. Choose whether you want the OSD to exclude fullscreen apps/games (this is needed for games that lose focus when the OSD is shown).

6. Set up "AFK Timeout" if you want it to automatically mute the microphone when you idle for longer than a set interval (in minutes).

7. Click "Save Config"


<details><summary><b>You can also write/edit the config file in a text editor:</b></summary> 

###### config.ini

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
afkTimeout=
```

1. `Microphone` can be any substring of your microphone's name or the controller's name as shown in this image:
   <details><summary>image</summary>

   ![](./assets/Controlpaneldialog.png)

   </details>
   
   you can also leave it as `""` to select the default microphone
### 
2. Both `MuteHotkey` and `UnmuteHotkey` can be any hotkey supported by AHK, use this [List of keys](https://www.autohotkey.com/docs/KeyList.htm) as a reference, you can also combine them with [hotkey modifiers](https://www.autohotkey.com/docs/Hotkeys.htm#Symbols).

   You can set both to the same hotkey to make it a toggle.


   Examples: `"<^M"`: left ctrl+M, `"RShift"`: right shift, `"^!T"`: ctrl+alt+T, `"LControl & XButton1"`: left ctrl+ mouse 4


3. Set `PushToTalk` to `1` to enable PTT,  `MuteHotkey` and `UnmuteHotkey` need to be set to the same hotkey first.

4. Both `SoundFeedback` and `OnscreenFeedback` can be set to either `0` or `1`, you can also set `ExcludeFullscreen` to 1 to stop the OSD from showing on top of fullscreen applications
   <details><summary>On screen feedback</summary>

   ![](./assets/OSD.gif)

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
afkTimeout=5
```           

</details>

</details>

## Libraries and resources used:

   * [VA.ahk](https://autohotkey.com/board/topic/21984-vista-audio-control-functions/)
   * [OSD.ahk](https://github.com/SaifAqqad/AHK_Script/blob/master/src/Lib/OSD.ahk)
   * [Material Design icons](https://github.com/Templarian/MaterialDesign)
