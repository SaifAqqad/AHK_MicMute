<h1 align="center">
    <img src="./src/resources/icons/1000.ico" width="32" height="32"></img>
    MicMute
</h1>
<p align="center">
    Control your microphone using keyboard and mouse hotkeys.
</p>

<p align="center">
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img src="https://img.shields.io/github/v/release/SaifAqqad/AHK_MicMute?color=FF5B20&label=latest&logo=github&style=for-the-badge"></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/releases/latest"><img src="https://img.shields.io/github/downloads/SaifAqqad/AHK_MicMute/total?color=FF6920&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAclBMVEUAAAD%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F9eWEHEAAAAJXRSTlMAAQIGHCQlJicyMzc5Pj9SVYGChIaJi42QlJWWl5vi7vDx8vT%2BbH3BRAAAAJBJREFUeNrdzwOSBEEUhOFs2zbz%2FkfcHdszof7D9b4Sfp3s%2B%2FJD4JP%2BwoF0BNKtudE6e2C27vVc6TnYW2D1HPUrIBTk5KyB2ZGNiGtRkUNGZgNZCriRkHNXLdz5WrydZ8f1C4CIJFPcBwjIBI8AwgCPAfAB8MjMv1FGehugzbzTrO4edkfMhwdrnn8jT8Vi%2Bgc1TxxjuzGKYQAAAABJRU5ErkJggg%3D%3D&style=for-the-badge"></img></a>
    <a href="https://github.com/SaifAqqad/AHK_MicMute/actions?query=workflow%3Acompile_prerelease"><img src="http://img.shields.io/github/actions/workflow/status/SaifAqqad/AHK_MicMute/compile_prerelease.yaml?branch=master&color=FF7720&logo=githubactions&logoColor=FFFFFF&style=for-the-badge"></img></a>
</p>

## Features

   * Set up multiple profiles and link them to apps/games
   * Control multiple microphones simultaneously 
   * Use separate hotkeys for Mute/Unmute or a single toggle/push-to-talk/push-to-mute hotkey
   * AFK timeout - Automatically mutes the microphone when you're AFK
   * Customizable sound and on-screen feedback
   * Always-on-top overlay to show the microphone's state
   * Run custom scripts/programs when muting/unmuting the microphone
   * ASUS Aura Sync integration
   * Voicemeeter integration

## Installation
### A. Install using [Scoop](https://scoop.sh)

```powershell
# 1. Add the extras bucket
scoop bucket add extras

# 2. Install MicMute
scoop install micmute
```
<small> MicMute can be updated using the built-in updater or by directly running the command `scoop update micmute`.        
The config file will be saved between updates.</small>

### B. Use standalone executable
MicMute can also be used as a standalone (portable) executable. You can download the latest release from the [releases page](https://github.com/SaifAqqad/AHK_MicMute/releases/latest/).           
> [!IMPORTANT]
> The configuration file will be saved in the same directory as the executable.          
> To avoid conflicts caused by its generic name `config.json`, store the executable in its own folder.

## Basic Usage
![MicMute's Configuration window](./screenshots/configwindow_1.png)      
<small>The first time you launch MicMute, a configuration window will open</small>

1. Select your microphone from the dropdown.
2. Choose the hotkey type (**Toggle**, **Push-to-talk** or **Seperate hotkeys**).
3. Click **Record** and press the key(s) combination for the hotkey, then click on **Stop** to save it.
4. (Optional) Open the **Feedback** tab and configure the [feedback options](#feedback-options) as needed.
5. (Optional) Open the **Misc** tab and configure the hotkey's options ([**AFK timeout**](#afk-timeout), [**Linked applications**](#linked-applications), [**PTT Delay**](#ptt-delay), etc...).
6. Click on the **Save** button.

**Check the [wiki](https://github.com/SaifAqqad/AHK_MicMute/wiki) for more info.**


## Known issues
*  [Valorant](https://playvalorant.com) might detect MicMute as a cheat [#59](https://github.com/SaifAqqad/AHK_MicMute/issues/59)          

   **Note**: While I've been using MicMute with Valorant without any issues since July 2022, I cannot guarantee that you won't get banned for using it. Use at your own risk.

* When running AutoHotkey alongside [Microsoft Powertoys](https://github.com/microsoft/PowerToys), they might conflict with each other, which may result in the hotkeys not working at all. [microsoft/PowerToys#2132](https://github.com/microsoft/PowerToys/issues/2132)

* [Albion Online](https://albiononline.com/en/home) detects MicMute as a botting tool, the games blacklists anything written in autohotkey and marks it as a botting tool. [#23](https://github.com/SaifAqqad/AHK_MicMute/issues/23)

* Windows defender might falsely detect MicMute as a trojen/malware (`Zpevdo.B` or `Wacatac.B!ml`). I always submit new releases to microsoft to remove the false detections and they usually do in a couple of days, but sometimes when they release a new definition update the detection occurs again. [#25](https://github.com/SaifAqqad/AHK_MicMute/issues/25)
 

## Libraries and resources used

| Library                                                               | License                                                                        |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [Material Design icons](https://github.com/Templarian/MaterialDesign) | [Apache 2.0](https://github.com/Templarian/MaterialDesign/blob/master/LICENSE) |
| [BASS audio library](https://www.un4seen.com)                         | [License](https://www.un4seen.com/#license)                                    |
| [VA.ahk](https://github.com/SaifAqqad/VA.ahk)                         | [License](https://github.com/SaifAqqad/VA.ahk/blob/master/LICENSE)             |
| [VMR.ahk](https://github.com/SaifAqqad/VMR.ahk)                       | [License](https://github.com/SaifAqqad/VMR.ahk/blob/master/LICENSE)            |
| [mmikeww/AHKv2-Gdip](https://github.com/mmikeww/AHKv2-Gdip)           | [License](https://www.autohotkey.com/boards/viewtopic.php?t=6517)              |
| [Bulma CSS framework](https://bulma.io/)                              | [MIT](https://github.com/jgthms/bulma/blob/master/LICENSE)                     |
| [CodeMirror 5](https://codemirror.net/5)                              | [MIT](https://codemirror.net/5/LICENSE)                                        |
| [G33kDude/cJson.ahk](https://github.com/G33kDude/cJson.ahk)           | [MIT](https://github.com/G33kDude/cJson.ahk/blob/main/LICENSE)                 |
| [G33kDude/Neutron.ahk](https://github.com/G33kDude/Neutron.ahk)       | [MIT](https://github.com/G33kDude/Neutron.ahk/blob/master/LICENSE)             |
| [jscolor Color Picker](https://jscolor.com)                           | [GPL v3](https://jscolor.com/download/#open-source-license)                    |

## Credits
This project would not exist without these people:
* [mistificat0r](https://sourceforge.net/u/mistificat0r/profile/) (The original MicMute)
* [G33kDude](https://github.com/G33kDude) (cJson, Neutron, etc)
* [Lexikos](https://github.com/Lexikos) (Autohotkey, VA.ahk)
* [SKAN](https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=54) (ResRead, VerCmp, etc)
* [jNizM](https://github.com/jNizM)
* probably more...
