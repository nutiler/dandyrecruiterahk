#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1

; DandyRecruiterAHK 0.1.0-beta.1 - optional Windows helper for DandyRecruiter.
; Copyright (c) 2026 Dandy. All rights reserved. Retain the author's copyright.
; Source and version history: https://github.com/nutiler/dandyrecruiterahk
;
; EASY SETUP
; 1. Install AutoHotkey v2 from https://www.autohotkey.com/ (v1 will not work).
; 2. On this file's GitHub page, use Download raw file. Save DandyRecruitUp.ahk
;    somewhere convenient, then double-click it. It starts unarmed.
; 3. Install/enable DandyRecruiter in WoW Forever. In WoW Key Bindings > AddOns
;    > DandyRecruiter, bind Recruit next to F8. If that binding is unavailable,
;    make a macro containing /dandyrecruit queued and bind its action button F8.
; 4. Focus the recruiter client, close chat/copy input, then press Ctrl+Alt+Up
;    once to arm. That shortcut toggles; the Up 1/6 tooltip confirms it is on.
; 5. Tap AND RELEASE Up once for each step: F8, Ctrl+C, Enter (finish copying),
;    Enter (open chat), Ctrl+V, then Enter (send). Check the line before step 6.
;    The next tap begins the next cycle. Holding Up does not repeat steps.
;
; REQUIREMENTS AND CONTROLS
; The addon must provide a highlighted /ginvite First Last or /who query.
; Keyboard scan fallback needs the matching newer addon build. If your version
; does not offer /who when empty, use Scan next or Wingman to get Ready first.
; Esc disarms this client. Close any open game menu before arming again.
; Alt-Tab pauses input; return to the same client to continue. Each armed
; window has its own cycle. A press released in another window is ignored.
; After ten final invite attempts, Up pauses for 30 seconds. Scans do not count.
; Taps during that pause send nothing. Expiry waits for another physical tap.
; If copying or focus is interrupted, inspect chat, press Esc to disarm and
; re-arm from a clean chat/copy state. Nothing sends to background clients.
; To stop completely, use Exit from this script's AutoHotkey tray icon.
;
; This optional external helper is not required by the addon. No executable,
; automatic startup, account settings or game data are bundled. Its separate
; taps and pacing are not a guarantee of approval by Blizzard or CurseForge.
; Keep one current script; use GitHub History for earlier committed versions.
;
; Bind this key to DandyRecruiter's native Recruit next action, or its existing queued macro.
inviteMacroKey := "{F8}"
; Leave blank to recognize active _forever_ clients on any drive. To restrict
; one installation, enter its full _forever_\Wow.exe or WowClassic.exe path.
foreverExe := ""
cycles := Map()
upOwner := 0
upHeld := false
SetKeyDelay(25, 35)

#HotIf IsForeverWindow(WinActive("A"))
^!Up::ToggleCycle()

#HotIf InArmedWindow()
~*!Tab::PauseCycle(ActiveCycle())
~Esc::Disarm(ActiveCycle())

#HotIf InArmedWindow() && !HasModifiers()
$*Up::MarkUpDown()

#HotIf HasCycles()
~$*Up::IgnoreUp()
~$*Up Up::ReleaseUp()
#HotIf

IsForeverWindow(hwnd) {
    global foreverExe
    if !hwnd
        return false
    try return IsForeverPath(WinGetProcessPath("ahk_id " hwnd), foreverExe)
    catch
        return false
}

IsForeverPath(path, configuredPath := "") {
    if Type(path) != "String" || Type(configuredPath) != "String"
        return false
    normalized := StrLower(StrReplace(path, "/", "\"))
    if !RegExMatch(normalized, '^(?:[a-z]:\\|\\\\[^\\]+\\[^\\]+\\)(?:[^\\]+\\)*_forever_\\(?:wow|wowclassic)\.exe$')
        return false
    return configuredPath == "" || normalized == StrLower(StrReplace(configuredPath, "/", "\"))
}

InArmedWindow() {
    return IsObject(ActiveCycle())
}

HasCycles() {
    global cycles
    return cycles.Count > 0
}

ActiveCycle() {
    global cycles
    hwnd := WinActive("A")
    return cycles.Has(hwnd) ? cycles[hwnd] : 0
}

HasModifiers() {
    return GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P")
        || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
}

OwnsCycle(state) {
    global cycles
    return IsObject(state) && cycles.Has(state.window) && cycles[state.window] == state
}

IsTrackedWindow(state) {
    try return WinGetPID("ahk_id " state.window) == state.pid
    catch
        return false
}

IsCurrent(state) {
    return OwnsCycle(state) && IsTrackedWindow(state) && WinActive("ahk_id " state.window)
}

CanSend(state) => IsCurrent(state) && !state.paused

ToggleCycle() {
    global cycles, upOwner, upHeld
    hwnd := WinActive("A")
    if !IsForeverWindow(hwnd)
        return
    upOwner := 0
    upHeld := GetKeyState("Up", "P")
    if cycles.Has(hwnd) {
        previous := cycles[hwnd]
        wasTracked := IsTrackedWindow(previous)
        Disarm(previous)
        if wasTracked
            return
    }
    state := {
        window: hwnd, pid: WinGetPID("ahk_id " hwnd), step: 1,
        busy: false, copied: "", commandKind: "", paused: false,
        batchInvites: 0, holdUntil: 0
    }
    cycles[hwnd] := state
    SetTimer(WatchFocus, 75)
    ShowStep(state)
}

WatchFocus() {
    global cycles, upOwner, upHeld
    if !IsObject(upOwner) && !GetKeyState("Up", "P")
        upHeld := false
    closed := []
    for hwnd, state in cycles {
        if !IsTrackedWindow(state)
            closed.Push(state)
        else if !WinActive("ahk_id " hwnd)
            PauseCycle(state)
        else if state.paused && !state.busy && !GetKeyState("Alt", "P") {
            state.paused := false
            ShowStep(state)
        }
    }
    for _, state in closed
        Disarm(state)
    if !InArmedWindow()
        ToolTip()
}

PauseCycle(state) {
    global upOwner
    if !OwnsCycle(state)
        return
    if IsObject(upOwner) && upOwner == state
        upOwner := 0
    if !state.paused {
        state.paused := true
        if !InArmedWindow()
            ToolTip()
    }
}

IgnoreUp() {
    global upOwner, upHeld
    upOwner := 0
    upHeld := true
}

Disarm(state, reason := "") {
    global cycles, upOwner
    if !OwnsCycle(state)
        return
    if IsObject(upOwner) && upOwner == state
        upOwner := 0
    cycles.Delete(state.window)
    if !HasCycles()
        SetTimer(WatchFocus, 0)
    if !InArmedWindow() {
        ToolTip(reason)
        if reason != ""
            SetTimer(HideIdleTip, -3500)
    }
}

HideIdleTip() {
    if !InArmedWindow()
        ToolTip()
}

MarkUpDown() {
    global upOwner, upHeld
    if upHeld
        return
    upHeld := true
    state := ActiveCycle()
    if !IsObject(state) || !IsCurrent(state) || state.busy
        return
    state.paused := false
    upOwner := state
}

ReleaseUp() {
    global upOwner, upHeld
    state := upOwner
    upOwner := 0
    upHeld := false
    if !IsObject(state) || !CanSend(state) || HasModifiers() || state.busy
        return

    state.busy := true
    try Advance(state)
    catch {
        if OwnsCycle(state)
            Disarm(state, IsCurrent(state) ? "Stopped. Check WoW and re-arm with Ctrl+Alt+Up." : "")
    } finally {
        state.busy := false
    }
}

SendStepInput(state, keys) {
    if !CanSend(state)
        return false
    SendEvent(keys)
    if CanSend(state)
        return true
    if OwnsCycle(state)
        Disarm(state, "Switched windows during input. Check WoW and re-arm with Ctrl+Alt+Up.")
    return false
}

Advance(state) {
    global inviteMacroKey
    if !CanSend(state)
        return
    if state.holdUntil > 0 {
        if A_TickCount < state.holdUntil {
            ShowStep(state)
            return
        }
        state.holdUntil := 0
        state.batchInvites := 0
    }

    switch state.step {
        case 1:
            if !SendStepInput(state, inviteMacroKey)
                return
        case 2:
            beforeCopy := ClipboardSequence()
            if !CanSend(state)
                return
            SendEvent("^c")
            copyResult := ReadNewCommand(state, beforeCopy)
            if copyResult != "copied" {
                if CanSend(state) && (copyResult == "invalid" || copyResult == "timeout") {
                    state.step := 1
                    state.copied := ""
                    state.commandKind := ""
                    ShowStep(state, "No fresh command copied. Wait for scan results or cooldown, then tap Up to retry.")
                }
                return
            }
        case 3, 4, 6:
            if !SendStepInput(state, "{Enter}")
                return
            if state.step == 6 && state.commandKind == "invite" {
                state.batchInvites += 1
                if state.batchInvites >= 10
                    state.holdUntil := A_TickCount + 30000
            }
        case 5:
            if !PasteCommand(state)
                return
    }
    if !OwnsCycle(state)
        return
    state.step := state.step == 6 ? 1 : state.step + 1
    if state.step == 1 {
        state.copied := ""
        state.commandKind := ""
    }
    ShowStep(state)
}

ClipboardSequence() => DllCall("User32\GetClipboardSequenceNumber", "UInt")

CommandKind(text) {
    if StrLen(text) > 235 || RegExMatch(text, "[\x00-\x1F\x7F]")
        return ""
    if RegExMatch(text, "\A/ginvite [\p{L}][\p{L}\p{M}'’-]* [\p{L}][\p{L}\p{M}'’-]*\z")
        return "invite"
    if !RegExMatch(text, '\A/who ([1-9][0-9]{0,2})-([1-9][0-9]{0,2})(.*)\z', &scan)
        return ""
    if Integer(scan[1]) > Integer(scan[2]) || Integer(scan[2]) > 255
        return ""
    remaining := scan[3]
    seen := Map()
    while remaining != "" {
        if !RegExMatch(remaining, '\A ([\p{L}]+)-"([^"\r\n|/\\;]{1,100})"', &filter)
            return ""
        key := StrLower(filter[1])
        if seen.Has(key)
            return ""
        seen[key] := true
        remaining := SubStr(remaining, StrLen(filter[0]) + 1)
    }
    return "scan"
}

ReadNewCommand(state, beforeCopy) {
    deadline := A_TickCount + 600
    while A_TickCount < deadline {
        if !CanSend(state)
            return "interrupted"
        sequence := ClipboardSequence()
        if sequence != beforeCopy {
            text := A_Clipboard
            if sequence == ClipboardSequence() && CanSend(state) {
                kind := CommandKind(text)
                if kind == ""
                    return "invalid"
                state.copied := text
                state.commandKind := kind
                return "copied"
            }
        }
        Sleep(20)
    }
    return "timeout"
}

PasteCommand(state) {
    beforePaste := ClipboardSequence()
    if A_Clipboard == state.copied && beforePaste == ClipboardSequence()
        return SendStepInput(state, "^v")

    savedClipboard := ClipboardAll()
    if !CanSend(state) || beforePaste != ClipboardSequence()
        return false
    A_Clipboard := state.copied
    inviteSequence := ClipboardSequence()
    try {
        return inviteSequence == ClipboardSequence() && SendStepInput(state, "^v")
    } finally {
        ; Give WoW time to read the paste before restoring the user's clipboard.
        Sleep(150)
        if inviteSequence == ClipboardSequence() && A_Clipboard == state.copied
            && inviteSequence == ClipboardSequence()
            A_Clipboard := savedClipboard
    }
}

ShowStep(state, note := "") {
    if !CanSend(state)
        return
    remaining := Max(0, Ceil((state.holdUntil - A_TickCount) / 1000))
    if remaining > 0 {
        ToolTip("Recruiting paused: " remaining "s remaining.`nTen invite attempts completed. Tap Up after the pause.`nEsc disarms")
        return
    }
    static labels := [
        "Recruit next or prepare scan (F8)",
        "Copy the highlighted /ginvite or /who command",
        "Finish copying (panel stays open)",
        "Open WoW chat",
        "Paste the copied command",
        "Check the chat line, then send the invite or scan"
    ]
    if note != ""
        note .= "`n"
    ToolTip("Up " state.step "/6  " labels[state.step] "`n" note "Esc disarms")
}
