#Requires AutoHotkey v1.1.36+

global template_link:= "<link rel='stylesheet' id='css_{1:}' href='{2:}'>"
, template_default_profile:= "<option value='{1:}' {2:} >{1:}</option>"
, template_mic:= "<option value='{1:}' id='mic_{1:}' {2:} >{3:}</option>"
, template_output:= "<option value='{1:}' id='output_{1:}' {2:}>{1:}</option>"
, template_app:= "<option value='{1:}' {3:} >{2:}</option>"
, template_profile_tag:= "
(
    <span class=""tag is-medium has-tooltip"" tabindex=0 role=""button"" aria-label=""{1:}"" aria-pressed=""false""  onkeydown=""switch(event.keyCode){case 32:case 69: event.preventDefault(); this.oncontextmenu.call() ;break; case 13:this.click()}""
        id=""tag_profile_{1:}"" oncontextmenu=""ahk.UI_displayProfileRename('{1:}')"" onClick=""ahk.UI_setProfile('{1:}');this.blur()"">
        <label class=""radio"">
            <input type=""radio"" name=""profiles_radio"" value=""{1:}"" id=""profile_{1:}"" disabled>
            <span data-title=""Right click to edit profile name"" >{1:}</span>
        </label>
    </span>
)"
, template_action_tag:= "
(
    <span class='tag is-medium has-tooltip' style='height: max-content;padding:30px 15px;'
        onclick='ahk.UI_onEditMicAction({1:i});this.blur()' onkeydown='switch(event.keyCode){case 13:this.click()}'
        tabindex=0 role='button' aria-label='{2:}' aria-pressed='false'>
        {3:}
    </span>
)"
, template_aura_action:= "
(
    <div class='is-flex is-align-items-center'>
        <div class='is-flex is-align-items-baseline is-size-7 mr-1'>Mute <div class='mx-1' style='width: 0.7em; height: 0.7em; border-radius: 50%;background-color: {:1}'></div></div>
        <div class='is-flex is-align-items-baseline is-size-7'>Unmute <div class='mx-1' style='width: 0.7em; height: 0.7em; border-radius: 50%;background-color: {:2}'></div></div>
    </div>
)"
, template_action_label:= 
( Join LTrim ; ahk
    {
        "Powershell" : "<label class='radio'>
                            <div class='mb-1'>
                                <svg style='width:14px;height:14px' focusable='false' viewBox='0 -3 24 24'>
                                    <path fill='currentColor' d='M21.83,4C22.32,4 22.63,4.4 22.5,4.89L19.34,19.11C19.23,19.6 18.75,20 18.26,20H2.17C1.68,20 1.37,19.6 1.5,19.11L4.66,4.89C4.77,4.4 5.25,4 5.74,4H21.83M15.83,16H11.83C11.37,16 11,16.38 11,16.84C11,17.31 11.37,17.69 11.83,17.69H15.83C16.3,17.69 16.68,17.31 16.68,16.84C16.68,16.38 16.3,16 15.83,16M5.78,16.28C5.38,16.56 5.29,17.11 5.57,17.5C5.85,17.92 6.41,18 6.81,17.73C14.16,12.56 14.21,12.5 14.26,12.47C14.44,12.31 14.53,12.09 14.54,11.87C14.55,11.67 14.5,11.5 14.38,11.31L9.46,6.03C9.13,5.67 8.57,5.65 8.21,6C7.85,6.32 7.83,6.88 8.16,7.24L12.31,11.68L5.78,16.28Z' />
                                </svg> Powershell
                            </div>
                            <code style='font-size: smaller;'>{1:}</code>
                        </label>",
        "Program" : "<label class='radio'>
                        <div class='mb-1'>
                            <svg style='width:14px;height:14px' focusable='false' viewBox='0 -3 24 24'>
                            <path fill='currentColor' d='M21.7 18.6V17.6L22.8 16.8C22.9 16.7 23 16.6 22.9 16.5L21.9 14.8C21.9 14.7 21.7 14.7 21.6 14.7L20.4 15.2C20.1 15 19.8 14.8 19.5 14.7L19.3 13.4C19.3 13.3 19.2 13.2 19.1 13.2H17.1C16.9 13.2 16.8 13.3 16.8 13.4L16.6 14.7C16.3 14.9 16.1 15 15.8 15.2L14.6 14.7C14.5 14.7 14.4 14.7 14.3 14.8L13.3 16.5C13.3 16.6 13.3 16.7 13.4 16.8L14.5 17.6V18.6L13.4 19.4C13.3 19.5 13.2 19.6 13.3 19.7L14.3 21.4C14.4 21.5 14.5 21.5 14.6 21.5L15.8 21C16 21.2 16.3 21.4 16.6 21.5L16.8 22.8C16.9 22.9 17 23 17.1 23H19.1C19.2 23 19.3 22.9 19.3 22.8L19.5 21.5C19.8 21.3 20 21.2 20.3 21L21.5 21.4C21.6 21.4 21.7 21.4 21.8 21.3L22.8 19.6C22.9 19.5 22.9 19.4 22.8 19.4L21.7 18.6M18 19.5C17.2 19.5 16.5 18.8 16.5 18S17.2 16.5 18 16.5 19.5 17.2 19.5 18 18.8 19.5 18 19.5M12.3 22H3C1.9 22 1 21.1 1 20V4C1 2.9 1.9 2 3 2H21C22.1 2 23 2.9 23 4V13.1C22.4 12.5 21.7 12 21 11.7V6H3V20H11.3C11.5 20.7 11.8 21.4 12.3 22Z'/>
                            </svg> Program
                        </div>
                        <span class='text-orange' style='font-size: smaller;'>{1:}</span>
                    </label>",
        "AuraSync": "<label class='radio'>
                        <div class='mb-2'>
                            <svg style='width:14px;height:14px' focusable='false' viewBox='0 0 24 24'>
                                <path fill='currentColor' d='M20,11H23V13H20V11M1,11H4V13H1V11M13,1V4H11V1H13M4.92,3.5L7.05,5.64L5.63,7.05L3.5,4.93L4.92,3.5M16.95,5.63L19.07,3.5L20.5,4.93L18.37,7.05L16.95,5.63M12,6A6,6 0 0,1 18,12C18,14.22 16.79,16.16 15,17.2V19A1,1 0 0,1 14,20H10A1,1 0 0,1 9,19V17.2C7.21,16.16 6,14.22 6,12A6,6 0 0,1 12,6M14,21V22A1,1 0 0,1 13,23H11A1,1 0 0,1 10,22V21H14M11,18H13V15.87C14.73,15.43 16,13.86 16,12A4,4 0 0,0 12,8A4,4 0 0,0 8,12C8,13.86 9.27,15.43 11,15.87V18Z' />
                            </svg> Aura Sync
                        </div>
                        {1:}
                    </label>"
    }
)
, UI_helpText:= { "Custom Sounds" : "
                (LTrim
                <ol>
                    <li>Turn on the option in the config UI</li>
                    <li>Place the sound files (<code>mp3</code>,<code>wav</code>) in the same folder as <code>MicMute.exe</code></li>
                    <li>
                        Rename them as:
                        <ul>
                            <li>
                                <p><strong>Mute sound</strong>: <code>mute</code> </p>
                            </li>
                            <li>
                                <p><strong>Unmute sound</strong>: <code>unmute</code> </p>
                            </li>
                            <li>
                                <p><strong>PTT on</strong>: <code>ptt_on</code> </p>
                            </li>
                            <li>
                                <p><strong>PTT off</strong>: <code>ptt_off</code></p>
                            </li>
                        </ul>
                    </li>
                </ol>
                )"
                , "Custom Icons" : "
                (LTrim
                <ol>
                    <li>Turn on the option in the config UI</li>
                    <li>Place the icons (<code>ico</code>/<code>png</code>/<code>jpeg</code>) in the same folder as <code>MicMute.exe</code></li>
                    <li>
                        Rename them as:
                        <ul>
                            <li>
                                <p><strong>Mute icon</strong>: <code>overlay_mute</code> </p>
                            </li>
                            <li>
                                <p><strong>Unmute icon</strong>: <code>overlay_unmute</code> </p>
                            </li>
                        </ul>
                    </li>
                </ol>
                )"
                , "Multiple Microphones" : "
                (LTrim
                <p>You can have active hotkeys for multiple microphones simultaneously, to do this:</p>
                <ol>
                    <li>Toggle the <div class='tag tag-empty'>Multiple</div> option </li>
                    <li>Select another microphone from the list </li>
                    <li>Setup the hotkeys</li>
                </ol>
                )"}
, UI_tooltips:= [ { selector: ".passthrough-label"
                , string: "The hotkey's keystrokes won't be hidden from the OS"}
             ,{ selector: ".wildcard-label"
                , string: "Fire the hotkey even if extra modifiers are held down"}
             ,{ selector: ".nt-label"
                , string: "Use neutral modifiers (i.e. Alt instead of Left Alt / Right Alt)"}
             ,{ selector: ".ptt-delay-label"
                , string: "Delay between releasing the key and the audio cutting off"}
             ,{ selector: ".afk-label"
                , string: "Mute the microphone when idling for a length of time"}
             ,{ selector: ".ExcludeFullscreen-label"
                , string: "Don't show the OSD if the active app/game is fullscreen"}
             ,{ selector: ".SwitchProfileOSD-label"
                , string: "Show an OSD when switching between profiles"}
             ,{ selector: ".SoundFeedback-label"
                , string: "Play a sound when muting or unmuting the microphone"}
             ,{ selector: ".OnscreenFeedback-label"
                , string: "Show an OSD when muting or unmuting the microphone"}
             ,{ selector: ".OnscreenOverlay-label"
                , string: "Show the microphone's state in an always-on-top overlay"}
             ,{ selector: ".multiple-mics-label"
                , string: "Right click to view instructions"}
             ,{ selector: ".ForceMicrophoneState-label"
                , string: "Prevent other apps from changing the mic's state"}
             ,{ selector: ".UseCustomSounds-label"
                , string: "Right click to view instructions"}
             ,{ selector: ".OverlayUseCustomIcons-label"
                , string: "Right click to view instructions"}
             ,{ selector: ".hybrid_ptt-label"
                , string: "Short press will toggle the microphone"}
             ,{ selector: ".mic-actions-label"
                , string: "Run programs/scripts when muting/unmuting the microphone"}
             ,{ selector: ".volume-lock-label"
                , string: "Lock the microphone's volume to a specific value"}
             ,{ selector: ".ForegroundAppsOnly-label"
                , string: "Require apps to be in the foreground to trigger a profile change"}
             ,{ selector: ".NotifyForAdminApps-label"
                , string: "Show a notification when an admin app is detected"}]