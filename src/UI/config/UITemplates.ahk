#Requires AutoHotkey v1.1.35+

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
                                <path fill='currentColor' d='M1 12H10.8L8.3 9.5L9.7 8.1L14.6 13L9.7 17.9L8.3 16.5L10.8 14H1V12M21 2H3C1.9 2 1 2.9 1 4V10.1H3V6H21V20H3V16H1V20C1 21.1 1.9 22 3 22H21C22.1 22 23 21.1 23 20V4C23 2.9 22.1 2 21 2' />                                                        
                            </svg> Program
                        </div>
                        <span class='text-orange' style='font-size: smaller;'>{1:}</span>
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