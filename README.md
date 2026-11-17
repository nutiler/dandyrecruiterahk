# DandyRecruiterAHK

A small optional Windows helper for DandyRecruiter in WoW Forever. Tap one key or the floating button to advance the normal copy-and-chat steps. The addon handles scanning, candidates, messages, contact protection and cooldowns.

GitHub hosts the source, instructions and version history. **Code** shows the script; **Releases** provides downloadable `.ahk` files. Install AutoHotkey v2 separately. The addon works without this helper.

[Download the latest helper](https://github.com/nutiler/dandyrecruiterahk/releases/latest/download/DandyRecruiterHelper.ahk) | [Latest release](https://github.com/nutiler/dandyrecruiterahk/releases/latest) | [Version history](https://github.com/nutiler/dandyrecruiterahk/commits/main)

## Version 1.1.1

**1.1.1**, build **2026-11-17 stable-1.1.1 simple-steps**, restores the simple six-tap clipboard workflow. Mouse movement does not pause it, ordinary gaps do not trigger an idle timeout, and no screen pixels or input strip are required. Use **DandyRecruiter 1.4.0 or later** from [CurseForge](https://www.curseforge.com/wow/addons/dandyrecruiter) for the matching workflow described below.

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/). AutoHotkey v1 is incompatible.
2. Install DandyRecruiter, use a character with guild invite permission and save an enabled recruitment message.
3. Exit older helper copies using their tray menu, then run **DandyRecruiterHelper.ahk**. Check for **simple-steps** in its tray tooltip. Editing the file does not update a running copy.
4. In Setup, choose a **Step key** and **WoW Recruit next key**, then Save. Defaults are Up/F8. For a one-button keypad sending Left, choose **Left/F8**. Existing saved choices are preserved.
5. The addon normally supplies F8. If choosing another action key, assign that same key under **Key Bindings > Dandy Suite > DandyRecruiter > Recruit next**. No action-bar macro is needed.
6. Focus WoW, close unfinished chat/copy input and press Ctrl+Alt+your step key once. For Left, use **Ctrl+Alt+Left**. Release the full chord, then tap the step key about once a second.

The helper detects Forever installations on different drives and sends nothing to background clients. Arm each client separately. Setup saves controls for your Windows user; changing controls disarms clients. WoW must stay foreground while using the remote button.

## Six separate taps

| Tap | Action |
| --- | --- |
| 1 | Request Recruit next, or prepare the addon's next due scan |
| 2 | Copy the highlighted command |
| 3 | Finish copying |
| 4 | Open native WoW chat |
| 5 | Paste the matching command |
| 6 | Submit after checking the chat line |

The next tap starts another cycle. Holding a key does not repeat steps. Busy taps are discarded rather than queued, and final Enter always needs its own tap. A one-button keypad should send one ordinary key press and release per physical tap.

The same cycle handles validated `/ginvite`, `/who`, and exactly `/reload` when the matching addon prepares a stuck-scan recovery. Scan and reload commands do not count as invitation attempts. Native/server waits remain in force. A freshly copied **DandyRecruiter is waiting.** status uses one separate Escape tap before requesting another action; the status is never pasted or sent.

In the addon's Inviter, check **Include scans between invites** to offer due searches between invitation cycles and during the preventive invite cooldown. Zero freshly Ready players includes scans automatically, even with Older candidates remaining. A submitted scan gives a freshly Ready recruit the following turn; pending replies and scan delays still permit eligible invitations. The addon chooses the command, while every copy/chat phase and final send still needs your separate tap.

## Mouse and interruptions

Mouse movement does not pause the helper. Step taps while a main mouse button is held are ignored. Releasing ordinary mouse input silently discards an unfinished cycle without sending any key; the next step requests a fresh command. It does not leave a mouse STOPPED state or require re-arming just because the mouse was used. Floating-button clicks keep their normal step behavior.

There is no idle timeout between taps. A clean or partially completed sequence waits for the next press. Keep the expected copy/chat input focused while advancing it. After a mouse interruption, close any unfinished native chat before starting fresh if it remains open. The addon can reselect its own current copy command on F8 without whispering another player.

An unknown copy or unverified paste still stops rather than guessing focus or spraying Escape. Close unfinished input, then click the stopped button or use Ctrl+Alt+your step key to re-arm. The attempt counter is retained. Foreground window/PID, modifier, strict command and clipboard checks remain.

**Esc** disarms an active cycle. **Alt-Tab** pauses that client. Tray **Setup** changes controls, **Show click button** toggles the floating widget, and **Exit** stops the helper. Windowed or Windowed Fullscreen may be needed for the floating widget to appear above WoW.

## Counts and cooldowns

The addon owns pacing and its countdown. The helper has no separate invite limiter. **Invite attempts** is helper telemetry, not a count of confirmed invitations or joins.

The matching addon uses a fifty-second preventive hold after ten counted native invite submissions, excludes attributed offline outcomes and can reset a partial batch after thirty seconds without a counted attempt. Native rate errors retain their separate fifty-second recovery. These are local policies; WoW continues to enforce its own limits. Waiting, scans and reloads do not count as invitations.

Previous accepted versions and their instructions remain in GitHub history and Releases. Publishing a new helper is separate from publishing the addon.
