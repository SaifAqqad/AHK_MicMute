<h1 align="center">
  AHK_MicMute
</h1>
<p align="center">
  Control your microphone through keyboard/mouse shortcuts.
</p>

# Usage
On the first run of the application, a config file will open in notepad that will look like this:
        
    [settings]
    Device_Name=""
    Mute_Hotkey=""
    Unmute_Hotkey=""
    Sound_Feedback=""
    OnScreen_Feedback=""
`Device_Name=""` : Enter any substring of your microphone's name or the controller's name as shown here:
<details><summary>image</summary>

![](resources\Controlpaneldialog.png)

</details>

`Mute_Hotkey=""` and `Unmute_Hotkey=""` both can be any hotkey supported by AHK, use this [List of keys](https://www.autohotkey.com/docs/KeyList.htm) as reference. 

Examples: `"<^M"`, `"RShift"`, `"^!T"`

Note: If both are set to the same hotkey, it will act as a toggle

`Sound_Feedback=""` and `OnScreen_Feedback=""` can be set to either `"0"` or `"1"`

<details><summary>Example of a correct config</summary>

    [settings]
    Device_Name="AmazonBasics"
    Mute_Hotkey="RShift"
    Unmute_Hotkey="RShift"
    Sound_Feedback="1"
    OnScreen_Feedback="0"            

</details>

### You can always edit the config file by clicking on *Edit config* from the tray menu.
