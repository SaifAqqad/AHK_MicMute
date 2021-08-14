<h1 align="center">
    <img src="./src/resources/MicMute.ico" width="32" height="32"></img>
    MicMute
</h1>
<p align="center">
    Control your microphone using keyboard shortcuts.
</p>
<p align="center">
    <a href="https://wakatime.com/badge/github/SaifAqqad/AHK_MicMute"><img alt="WakaTime"src="https://wakatime.com/badge/github/SaifAqqad/AHK_MicMute.svg"></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img src="https://img.shields.io/github/downloads/SaifAqqad/AHK_MicMute/total"></img></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img alt="GitHub release(latest SemVer)"src="https://img.shields.io/github/v/release/SaifAqqad/AHK_MicMute?label=Latest"></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/actions?query=workflow%3Acompile_prerelease"><img src="https://img.shields.io/github/workflow/status/SaifAqqad/AHK_MicMute/compile_prerelease/master"></img></a>
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
* ~~When Changing the microphone, make sure to clear the hotkey for the previous one before setting up the new one, unless you want to control multiple microphones simultaneously.~~ This no longer applies for version [1.1.0](https://github.com/SaifAqqad/AHK_MicMute/releases/tag/1.1.0) and later.
* When you set up a hotkey for a microphone, a `*` will appear before the microphone's name
<hr>

### Hotkey options
| Option            | Description                                                                                                                                                                                                                                                                    |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Passthrough       | If this is turned off, the hotkey will only work for MicMute and will be hidden from the rest of the system. So turn this on if you want the hotkey to work for other apps.                                                                                                    |
| Wildcard          | If this is turned on, the hotkey will work even if you press extra modifiers, so for example if the hotkey is <kbd>Ctrl</kbd> <kbd>M</kbd> and you press <kbd>Ctrl</kbd> <kbd>Shift</kbd> <kbd>M</kbd> , the hotkey will still be triggered.                                   |
| Neutral modifiers | If this is turned off, the hotkey can have a specific modifier (Right or Left) instead of a neutral one (example: <kbd>RCtrl</kbd> instead of <kbd>Ctrl</kbd>, this will only be triggered by the right control key). This option should be set *before* recording the hotkey. |
<hr>

### Feedback options
#### 1. Sound feedback
Play a sound when muting/unmuting the microphones. You can also use [custom sounds](#1-custom-sounds).
#### 2. On-screen feedback
Show an OSD when muting/unmuting the microphones. 

* You can change the OSD position (default position is the bottom center of the screen, above the taskbar).
* You can exclude fullscreen apps/games from the OSD, this is needed for some games that lose focus when the OSD is shown.
* <details>
  <summary>GIF</summary>

  ![OSD](./src/resources/OSD.gif)
  </details>

#### 3. On-screen overlay
Show the microphone's state in an always-on-top overlay.

*  <details>
    <summary>GIF</summary>

    ![overlay](https://user-images.githubusercontent.com/47293197/122362722-0c4bbe80-cf61-11eb-881f-e11b0b06f025.gif)
   </details>
* <kbd>CTRL</kbd> <kbd>ALT</kbd> <kbd>F9</kbd> toggles show/hide
* <kbd>CTRL</kbd> <kbd>ALT</kbd> <kbd>F10</kbd> toggles locked/unlocked 
* You can drag the overlay to change its position when it's unlocked
* Games need to be set to `Windowed fullscreen` or `Borderless` for the overlay to show up on top
* You have the option to only show the overlay when the microphone is muted
* You can use custom icons for the overlay. 
    To do this, turn on the option in the config UI, then place the icons (`ico`/`png`/`jpeg`) in the same folder as `MicMute.exe` and rename them as:  
    -  Mute icon: `overlay_mute`
    -  Unmute icon: `overlay_unmute`
   
    <sub>**Avoid using icons that have a gray `#232323` color**</sub>
<hr>

### Linked applications
Link a profile to an app/game, when the app is launched, MicMute automatically switches to that profile, when the app closes, MicMute switches back to the default profile.
<hr>

### Global options
These options are shared between all profiles.
#### 1. Custom sounds
 To use custom feedback sounds, turn on the option in the config UI, then make sure the sound files (`mp3`,`wav`) are in the same folder as `MicMute.exe` and rename them as:

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
To do this, toggle the `Multiple` option then select another microphone from the list and setup hotkeys for it.

When using this feature, the following applies:

* The tray icon will be the static MicMute icon
* The tray icon no longer acts as a toggle button, and the tray menu option to toggle the microphone is disabled.
* The [On-screen feedback](#2-on-screen-feedback) OSD will show the microphone name when muting/unmuting
* The [On-screen overlay]() is disabled
<hr>

## Known issues
* When running AutoHotkey alongside [Microsoft Powertoys](https://github.com/microsoft/PowerToys), they might conflict with each other, which may result in the hotkeys not working at all. [microsoft/PowerToys#2132](https://github.com/microsoft/PowerToys/issues/2132)

* [Albion Online](https://albiononline.com/en/home) detects MicMute as a botting tool, the games blacklists anything written in autohotkey and marks it as a botting tool. [#23](https://github.com/SaifAqqad/AHK_MicMute/issues/23)

* Windows defender might falsely detect MicMute as a trojen/malware (`Zpevdo.B` or ML detections). I always submit new releases to microsoft to remove the false detections and they usually do in a couple of days, but sometimes when they release a new definition update the detection occurs again. [#25](https://github.com/SaifAqqad/AHK_MicMute/issues/25)
 

## Editing the config file
 Hold shift when asked to setup a profile or when clicking "Edit configuration" from the tray menu, and the config file will open in the default JSON editor

```json
//config.json example 
{
    "AllowUpdateChecker": 1,
    "DefaultProfile": "Default",
    "MuteOnStartup": 0,
    "PreferTheme": -1,
    "Profiles": [
        {
            "afkTimeout": 0,
            "ExcludeFullscreen": 0,
            "LinkedApp": "",
            "Microphone": [
                {
                    "MuteHotkey": "*RShift",
                    "Name": "Microphone (AmazonBasics Desktop Mini Mic)",
                    "PushToTalk": 0,
                    "UnmuteHotkey": "*RShift"
                }
            ],
            "OnscreenFeedback": 0,
            "OnscreenOverlay": 1,
            "OSDPos": {
                "x": -1,
                "y": -1
            },
            "OverlayOnMuteOnly": 1,
            "OverlayPos": {
                "x": 2481,
                "y": 413
            },
            "ProfileName": "Default",
            "PTTDelay": 50,
            "SoundFeedback": 1,
            "UpdateWithSystem": 1
        }
    ],
    "SwitchProfileOSD": 1,
    "UseCustomSounds": 0
}
```

## CLI arguments
| Argument                  | Description                                                                         |
|---------------------------|-------------------------------------------------------------------------------------|
| `/profile=<profile name>` | Startup with a specific profile.                                                    |
| `/noUI`                   | Disable the configuration UI completely. This decreases memory usage by almost 60%. |
| `/debug`                  | Add shortcuts to `ListVars`, `ListHotkeys` and `listKeys`  in the tray menu.        |

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
git clone --recurse-submodules https://github.com/SaifAqqad/AHK_MicMute.git;
cd .\AHK_MicMute\;
```
### 3. Run the compiler

```powershell
ahk2exe /in ".\src\MicMute.ahk" /out ".\src\MicMute.exe" /compress 2;
```

## Libraries and resources used

| Library                                                               | License                                                                        |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------|
| [G33kDude/Neutron.ahk](https://github.com/G33kDude/Neutron.ahk)       | [MIT](https://github.com/G33kDude/Neutron.ahk/blob/master/LICENSE)             |
| [G33kDude/cJson.ahk](https://github.com/G33kDude/cJson.ahk)           | [MIT](https://github.com/G33kDude/cJson.ahk/blob/main/LICENSE)                 |
| [Bulma CSS framework](https://bulma.io/)                              | [MIT](https://github.com/jgthms/bulma/blob/master/LICENSE)                     |
| [Lexikos/VA.ahk](https://github.com/ahkscript/VistaAudio)             | [License](https://github.com/ahkscript/VistaAudio/blob/master/LICENSE)         |
| [Material Design icons](https://github.com/Templarian/MaterialDesign) | [Apache 2.0](https://github.com/Templarian/MaterialDesign/blob/master/LICENSE) |
