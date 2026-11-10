# DandyRecruiterAHK

An optional Windows helper for the DandyRecruiter addon in WoW Forever. Choose your keyboard key or side mouse button, then use a separate press for each copy-and-chat step. Install the addon separately; DandyRecruiter also works without this helper.

GitHub is where this helper's source, instructions and version history are hosted. **Code** lets you read the script; **Releases** has ready-to-download `.ahk` files. You do not need Git, a GitHub account or a source-code ZIP to use it. The WoW addon, game files and player settings are separate.

**Helper version: 1.1.0 stable**

[Published downloads](https://github.com/nutiler/dandyrecruiterahk/releases) | [Source history](https://github.com/nutiler/dandyrecruiterahk/commits/main)

The setup below describes stable `DandyRecruiterHelper.ahk` 1.1.0, matched to DandyRecruiter 1.1.0. The previously published beta.1 still uses `DandyRecruitUp.ahk`; its instructions remain with that historical release. Check Releases for the versions currently available. The reviewed manual release workflow publishes 1.1.0 as a full release and marks it latest; after publication, [the latest release](https://github.com/nutiler/dandyrecruiterahk/releases/latest) and [direct script download](https://github.com/nutiler/dandyrecruiterahk/releases/latest/download/DandyRecruiterHelper.ahk) will point to it.

## Easy setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/). AutoHotkey v1 will not run this script.
2. Install and enable DandyRecruiter in WoW Forever.
3. Exit the old `DandyRecruitUp.ahk` from its AutoHotkey tray icon before launching the new helper. Renaming a script does not stop an already running older copy. Keep only one helper running.
4. Double-click **DandyRecruiterHelper.ahk** in File Explorer. The current local build shows **2026-11-10 stable-1.1.0** in its tray tooltip and Setup title. Editing or previewing the file does not update an already running copy. Setup opens on the first run. Choose a **Step key** and a **WoW Recruit next key**, then save. Defaults are Up and F8. Keyboard keys, middle mouse and side mouse buttons are offered for the step key; wheels, left/right click, modifiers, Enter, Escape, Tab, Delete and NumpadDot are excluded. The last two would conflict with Windows' Ctrl+Alt+Delete shortcut. Use NumLock for numpad digit keys.
5. Matching newer DandyRecruiter builds provide **F8** automatically when no custom Recruit next binding is present. For another action key, open **Key Bindings > Dandy Suite > DandyRecruiter** and bind **Recruit next** to the same key chosen in AHK Setup. The addon respects that custom choice. On older addon builds, assign F8 yourself under its DandyRecruiter binding category, or bind your action key to a macro containing `/dandyrecruit queued` if the native action is unavailable.
6. Focus the recruiter client, close chat and copy input, then press **Ctrl+Alt+your step key** once to arm. With defaults, that is **Ctrl+Alt+Up**. The step tooltip confirms it is armed. This shortcut toggles it on or off; it does not send a message or invite. Release all three keys before starting the next step. Holding the shortcut does not toggle it repeatedly.

Right-click the helper's tray icon and choose **Setup** to change keys or the optional ten-attempt pause later. Saving disarms all clients, so finish or close chat/copy input and arm again afterward. Cancel keeps your previous choices. Preferences are saved for your Windows user outside the downloaded script and contain only your controls and pause choice. They are not included in GitHub files or addon packages.

The helper detects active `_forever_` installations on any drive. You do not need to edit the script. Choose a step key you can reserve while recruiting; normal use of that key in an armed game window advances the helper.

In the key list, **MButton** means middle-click and **XButton1 / XButton2** are the mouse's side buttons.

## Using your step key

Press **and release** your step key separately for each step:

| Tap | Action |
| --- | --- |
| 1 | Send your chosen WoW action key to recruit next or prepare a scan command |
| 2 | Copy the highlighted command |
| 3 | Finish copying |
| 4 | Open WoW chat |
| 5 | Paste the command |
| 6 | Send it after you check the chat line |

The next press starts another cycle. Holding the step key or mouse button does not repeat steps. The final send always needs its own press. The tooltip uses your chosen key and shows the current step, **Batch attempts**, and **Invite attempts** since you armed that client. This counts final `/ginvite` submissions, not confirmed invitations or joins. Scan commands and offline whispers caught before copying do not count. An already submitted failed invite remains a pacing attempt. Ordinary disarming resets the counter; explicitly re-arming a stopped cycle retains counts and any active cooldown.

While the addon is waiting because of combat, a scan reply, cooldown or player information, it selects **DandyRecruiter is waiting.** in the Inviter. The helper reads that status and tells you to check the Inviter for the actual reason and countdown. Your next tap sends only Escape to finish the waiting step; the following tap requests Recruit next again. It never pastes or sends the status, and waiting does not count as an invite. Normal command cycles still use six taps.

If copying fails or the paste cannot be verified, the tooltip shows **STOPPED** and further step taps send nothing. Close unfinished WoW chat, copy input or menus yourself, then press **Ctrl+Alt+your step key** to re-arm. This retains that client's attempt counts and active cooldown. The helper never retries Escape for unknown focus. Only a freshly copied exact waiting status permits the separate Escape step above. A matching addon keeps owned copy focus when an offline reply replaces the command with that status; it leaves native chat untouched if you have already moved there.

The addon supplies the highlighted `/ginvite First Last` or `/who` command. Keyboard scan fallback requires a newer matching addon build. If your addon does not offer `/who` when nobody is Ready, use **Scan next** or **Wingman** to find Ready players first. Wait for scan results and cooldowns before trying again.

## Controls and pauses

- **Esc:** disarm an active cycle. While STOPPED, Escape only reaches WoW so you can close unfinished input; the stopped helper retains its counts and cooldown.
- **Ctrl+Alt+your step key:** arm or disarm the focused Forever client; explicitly re-arm a STOPPED cycle after cleaning up native input.
- **Alt-Tab:** pause input; return to the same client to continue. Arm each client separately.
- **Left/right mouse held:** pause helper input while using the camera or clicking. Native mouse actions pass through normally. Release both buttons before stepping again. An interrupted copy/chat cycle stops after release and needs manual input cleanup plus explicit re-arm. An idle first-step camera hold can resume after release. Mouse release sends nothing.
- **After ten final invite attempts:** pause for 50 seconds by default. Scan commands do not count. Extra taps send nothing during the pause, and expiry waits for another tap. The batch count resets when the cooldown ends. A partial batch also resets after 30 seconds without an invite attempt; that idle reset never shortens an active 50-second cooldown. The session attempt counter continues across both resets.
- **If STOPPED appears:** inspect the game, close unfinished native input and press Ctrl+Alt+your step key. Timers and returning focus do not restart a stopped cycle.
- **To stop completely:** choose **Exit** from the script's AutoHotkey tray icon. Exit the old copy before starting a downloaded replacement.

Use the current script for normal setup. Earlier committed versions remain available in GitHub history; downloadable versions appear on the Releases page.

## How the two pauses work

Keep the helper's optional preventive pause enabled for normal use. It waits 50 seconds after ten final invite attempts; it counts submissions rather than successful invites. The addon owns combat, scan readiness and the 50-second recovery after an actual native rate-limit error. Its Inviter shows the current reason and countdown. The helper never guesses that reason from the fixed waiting marker.

These are independent deadlines, not two queued pauses. If the addon pauses after seven attempts, the helper's partial batch resets after 30 idle seconds during the addon wait; the next invite starts a fresh batch. If an error happens around the tenth attempt, both 50-second waits run at the same time. A later native error may extend the addon's remaining recovery, which the Inviter reports. Neither expiry sends anything automatically.

## Testing the game's rate limit

To test beyond the helper's ten-attempt pause, open **Setup**, uncheck **Preventive pause: 50 seconds after 10 invite attempts**, then **Save** and arm the client again. Watch **Invite attempts** and stop when WoW shows its red rate-limit error. The addon's separate recovery pause still applies. Check the option again afterward to restore normal pacing. This measures the attempts in your current test; the game's limit can depend on timing and earlier activity.
