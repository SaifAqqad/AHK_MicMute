<h1 align="center">
    <img src="./src/resources/MicMute.ico" width="32" height="32"></img>
    MicMute
</h1>
<p align="center">
    Control your microphone using keyboard shortcuts.
</p>
<p align="center">
    <a href="https://github.com/SaifAqqad/AHK_MicMute/actions?query=workflow%3Acompile_prerelease"><img src="https://img.shields.io/github/workflow/status/SaifAqqad/AHK_MicMute/compile_prerelease/master?color=%23FC4C20&logo=ahk&style=for-the-badge"></img></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img alt="GitHub release(latest SemVer)"src="https://img.shields.io/github/v/release/SaifAqqad/AHK_MicMute?color=%23FF5B20&label=Latest&style=for-the-badge"></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img src="https://img.shields.io/github/downloads/SaifAqqad/AHK_MicMute/total?color=%23FF6920&style=for-the-badge"></img></a>
    <a href="https://www.autohotkey.com/docs/AHKL_ChangeLog.htm#v1.1.33.02"><img src="https://img.shields.io/badge/AHK-v1.1.33.02-%23FF7720?style=for-the-badge"></img></a>
</p>

## Features

   * Set up multiple profiles and link them to apps/games
   * Control multiple microphones simultaneously 
   * Use separate hotkeys for Mute/Unmute or a single toggle/push-to-talk hotkey
   * Optional sound and on-screen feedback with ability to use custom sounds
   * AFK timeout (auto mute when idling for longer than a specific time interval)

## Installation
### A. Install using [Scoop](https://scoop.sh)

```powershell
# Add the extras bucket
scoop bucket add extras

# Install MicMute
scoop install micmute
```

   <small> You can update MicMute using `scoop update micmute`, your config file will be saved between updates.</small>

### B. Use standalone executable
   You can download [MicMute](https://github.com/SaifAqqad/AHK_MicMute/releases/latest/download/MicMute.exe) and use it standalone.

## Usage
![The first time you launch MicMute, a configuration window will open](./src/resources/configwindow_1.png)      
<small>The first time you launch MicMute, a configuration window will open</small>

1. Select your microphone from the list.
2. Choose the hotkey type (Toggle, Push-to-talk or seperate hotkeys).
3. Select the hotkey options you want. see [hotkey options](#hotkey-options).
4. Click Record and press the key(s) combination for the hotkey, then click on Stop to save it.
5. Select the feedback options you want. see [feedback options](#feedback-options).
6. If you're setting up multiple profiles, you can link a profile to an app/game. see [linked applications](#linked-applications).
7. If you want the microphone to be auto muted when you idle, type the amount of minutes to wait under AFK timeout.
8. If you're setting up a PTT hotkey, you can change the delay between releasing the key and the audio cutting off by changing the PTT delay option.
9. Click on Save profile.

### Notes
* You can change a profile's name by right clicking it.
* When Changing the microphone, make sure to clear the hotkey for the previous one before setting up the new one.
* When you set up a hotkey for a microphone, a `*` will appear before the microphone's name
<hr>

### Hotkey options
| Option            | Description                                                                                                                                                                                                                                                  |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Passthrough       | If this is turned off, the hotkey will only work for MicMute and will be hidden from the rest of the system. So turn this on if you want the hotkey to work for other apps.                                                                                  |
| Wildcard          | If this is turned on, the hotkey will work even if you press extra modifiers, so for example if the hotkey is `Ctrl + M` and you press `Ctrl + Shift + M` , the hotkey will still be triggered.                                                              |
| Neutral modifiers | If this is turned off, the hotkey can have a specific modifier (Right or Left) instead of a neutral one (example: `RCtrl` instead of `Ctrl`, this will only be triggered by the right control key). This option should be set *before* recording the hotkey. |
<hr>

### Feedback options
#### 1. Sound feedback
Play a sound when muting/unmuting the microphones. You can also use [custom sounds](#1-custom-sounds).
#### 2. On-screen feedback
Show an OSD when muting/unmuting the microphones. 

* You can change the OSD position (default position is the bottom center of the screen, above the taskbar).
* You can exclude fullscreen apps/games from the OSD, this is needed for some games that lose focus when the OSD is shown.

<details>
<summary>OSD.gif</summary>

![OSD](./src/resources/OSD.gif)
</details>
<hr>

### Linked applications
Link a profile to an app/game, when the app is launched, MicMute automatically switches to that profile, when the app closes, MicMute switches back to the default profile.
<hr>

### Global options
These options are shared between all profiles.
#### 1. Custom sounds
 To use custom feedback sounds, turn on the option in the config UI, then make sure the sound files (`mp3`,`wav`) are in the same directory as `MicMute.exe` and rename them as:

* **Mute sound**: `mute` 

* **Unmute sound**: `unmute` 

* **PTT on**: `ptt_on` 

* **PTT off**: `ptt_off`

#### 2. Mute on startup
Mute the profile's microphones when switching to it.
#### 3. Switching-profile OSD
Show an OSD with the profile's name when switching to it.
#### 4. UI Theme
UI Theme can be set to `System Theme`, `Dark` or `Light`

<small>This does *not* affect the tray icon color, which is always based on the system theme</small>
<hr>

### Controlling multiple microphones
Starting with version [0.9.0](https://github.com/SaifAqqad/AHK_MicMute/releases/tag/0.9.0), You can have active hotkeys for multiple microphones simultaneously.
To do this, just select another microphone from the list and setup hotkeys for it.

When using this feature, the following applies:

* The tray icon will be the static MicMute icon
* The tray icon no longer acts as a toggle button, and the tray menu option to toggle the microphone is disabled.
* The [On-screen feedback](#2-on-screen-feedback) OSD will show the microphone name when muting/unmuting
<hr>
  
## Editing the config file
 Hold shift when asked to setup a profile or when clicking "Edit configuration" from the tray menu, and the config file will open in the default JSON editor

```json
//config.json example 
{
    "DefaultProfile": "Default",
    "MuteOnStartup": 0,
    "PreferTheme": -1,
    "SwitchProfileOSD": 1,
    "UseCustomSounds": 0,
    "Profiles": [
        {
            "afkTimeout": 0,
            "ExcludeFullscreen": 0,
            "LinkedApp": "",
            "Microphone": [
                {
                    "MuteHotkey": "~*RShift",
                    "Name": "Default",
                    "PushToTalk": 0,
                    "UnmuteHotkey": "~*RShift"
                }
            ],
            "OnscreenFeedback": 1,
            "OSDPos": {
                "x": -1,
                "y": -1
            },
            "ProfileName": "Default",
            "PTTDelay": 100,
            "SoundFeedback": 1,
            "UpdateWithSystem": 1
        }
    ]
}
```

## CLI arguments
| Argument                  | Description                                                                       |
|---------------------------|-----------------------------------------------------------------------------------|
| `/profile=<profile name>` | Startup with a specific profile.                                                  |
| `/noUI`                   | Disable the configuration UI completely. This makes MicMute use alot less memory. |
| `/debug`                  | Add shortcuts to `ListVars`, `ListHotkeys` and `listKeys`  in the tray menu.      |

Example: `MicMute.exe "/profile=profile 1" /noUI /debug`
## Compile instructions
<small>Note: Starting with version [0.9.0](https://github.com/SaifAqqad/AHK_MicMute/releases/tag/0.9.0), You can run `MicMute.ahk` directly without compiling it.</small>

### 1. Install prerequisites
You will need [AutoHotkey](https://www.autohotkey.com/), [upx](https://upx.github.io/) and [git](https://git-scm.com/download/win).

You can install them using [scoop](https://scoop.sh):

1. Install scoop 
    ```powershell
    # This allows running powershell scripts 
    # that are signed by a trusted publisher.
    # You should type 'yes' when prompted.
    Set-ExecutionPolicy RemoteSigned -scope CurrentUser;

    # This runs the scoop installer script.
    iwr -useb get.scoop.sh | iex;
    ```
2. Install prerequisites
    ```powershell
    scoop install git upx;
    scoop bucket add extras;
    scoop install autohotkey;
    ```
3. Copy upx to the compiler directory
    ```powershell
    cp "$(scoop prefix upx)\upx.exe" -Destination "$(scoop prefix autohotkey)\Compiler\";
    ```
### 2. Clone the repository
    
```powershell
git clone https://github.com/SaifAqqad/AHK_MicMute.git;
cd .\AHK_MicMute\;
```
### 3. Run the compiler

```powershell
ahk2exe /in ".\src\MicMute.ahk" /out ".\src\MicMute.exe" /compress 2;
```
## Known issues
* When running AutoHotkey alongside [Microsoft Powertoys](https://github.com/microsoft/PowerToys), they might conflict with each other, which may result in the hotkeys not working at all. see [microsoft/PowerToys#2132](https://github.com/microsoft/PowerToys/issues/2132).

## Libraries and resources used

| Library                                                                | License                                                                        |
|------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| [G33kDude/Neutron.ahk](https://github.com/G33kDude/Neutron.ahk)        | [MIT](https://github.com/G33kDude/Neutron.ahk/blob/master/LICENSE)             |
| [cocobelgica/JSON.ahk](https://github.com/cocobelgica/AutoHotkey-JSON) | [WTFPL](https://github.com/cocobelgica/AutoHotkey-JSON#json-and-jxon)          |
| [Lexikos/VA.ahk](https://github.com/ahkscript/VistaAudio)              | [License](https://github.com/ahkscript/VistaAudio/blob/master/LICENSE)         |
| [Bulma CSS framework](https://bulma.io/)                               | [MIT](https://github.com/jgthms/bulma/blob/master/LICENSE)                     |
| [Material Design icons](https://github.com/Templarian/MaterialDesign)  | [Apache 2.0](https://github.com/Templarian/MaterialDesign/blob/master/LICENSE) |
