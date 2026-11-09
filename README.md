# DandyRecruiterAHK

An optional Windows helper for the DandyRecruiter addon in WoW Forever. Each separate Up-arrow tap advances one copy-and-chat step. Install the addon separately; DandyRecruiter also works without this helper.

GitHub is where this helper's source, instructions and version history are hosted. **Code** lets you read the script; **Releases** has ready-to-download `.ahk` files. You do not need Git, a GitHub account or a source-code ZIP to use it. The WoW addon, game files and player settings are separate.

**Helper version: 0.1.0-beta.1 (prerelease)**

[Download DandyRecruitUp.ahk](https://github.com/nutiler/dandyrecruiterahk/releases/download/v0.1.0-beta.1/DandyRecruitUp.ahk) · [All releases](https://github.com/nutiler/dandyrecruiterahk/releases) · [Source history](https://github.com/nutiler/dandyrecruiterahk/commits/main)

## Easy setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/). AutoHotkey v1 will not run this script.
2. Install and enable DandyRecruiter in WoW Forever.
3. Use the download link above, or open **Releases**, choose the newest prerelease and click **DandyRecruitUp.ahk** under **Assets**. Save it somewhere convenient and double-click it. It starts unarmed. Keep only one copy running. The automatically listed **Source code** ZIP/TAR files are not needed.
4. In WoW, open **Key Bindings > AddOns > DandyRecruiter** and bind **Recruit next** to **F8**. If that binding is unavailable, create a macro containing `/dandyrecruit queued`, place it on an action button and bind that button to F8.
5. Focus the recruiter client, close chat and copy input, then press **Ctrl+Alt+Up** once. The **Up 1/6** tooltip confirms the helper is armed. This shortcut toggles it on or off.

The helper detects active `_forever_` installations on any drive. You usually do not need to edit the script.

## Using Up

Tap **and release** Up separately for each step:

| Tap | Action |
| --- | --- |
| 1 | Press F8 to recruit next or prepare a scan command |
| 2 | Copy the highlighted command |
| 3 | Finish copying |
| 4 | Open WoW chat |
| 5 | Paste the command |
| 6 | Send it after you check the chat line |

The next tap starts another cycle. Holding Up does not repeat steps. The final send always needs its own tap.

The addon supplies the highlighted `/ginvite First Last` or `/who` command. Keyboard scan fallback requires a newer matching addon build. If your addon does not offer `/who` when nobody is Ready, use **Scan next** or **Wingman** to find Ready players first. Wait for scan results and cooldowns before trying again.

## Controls and pauses

- **Esc:** disarm this client. Close any game menu before arming again.
- **Alt-Tab:** pause input; return to the same client to continue. Arm each client separately.
- **After ten final invite attempts:** pause for 30 seconds. Scan commands do not count. Extra taps send nothing during the pause, and expiry waits for another tap.
- **If focus or copying gets interrupted:** press Esc, inspect chat, close unfinished input and re-arm from a clean state.
- **To stop completely:** choose **Exit** from the script's AutoHotkey tray icon. Exit the old copy before starting a downloaded replacement.

Use the current script for normal setup. Earlier committed versions remain available in GitHub history; downloadable versions appear on the Releases page.
