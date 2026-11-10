#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1

; DandyRecruiterAHK 1.1.0 - optional Windows helper for DandyRecruiter.
; Copyright (c) 2026 Dandy. All rights reserved.
; Compatible with DandyRecruiter 1.1.0 on WoW Forever.
; Source and version history: https://github.com/nutiler/dandyrecruiterahk
;
; EASY SETUP
; 1. Install AutoHotkey v2 from https://www.autohotkey.com/.
; 2. Exit old helper copies, then double-click DandyRecruiterHelper.ahk.
; 3. Setup lets you choose a Step key/button and WoW Recruit next key.
;    Defaults are Up and F8. Matching DandyRecruiter builds provide F8.
;    For a custom key, bind the SAME key to Recruit next in WoW under
;    Key Bindings > Dandy Suite > DandyRecruiter. Older builds also support
;    an action button containing /dandyrecruit queued.
; 4. Save, focus the recruiter client, close chat/copy input and press
;    Ctrl+Alt+your Step key/button to arm that client. Esc disarms it.
; 5. Tap AND RELEASE the Step key once for each separate action: Recruit next,
;    Ctrl+C, Enter (finish copying), Enter (open chat), Ctrl+V, Enter (send).
;    Inspect the line before the final tap. Holding the button never repeats.
; A copied waiting status is not an invite or command: the next tap sends
; Escape only, then another tap retries Recruit next when ready.
; A failed or unknown copy stops the workflow without sending Escape.
; Close unfinished chat/copy input yourself, then press Ctrl+Alt+your Step
; key to re-arm. The stopped client keeps its attempt counts and cooldown.
; Reopen Setup from the AutoHotkey tray icon. Saving disarms every client;
; close unfinished chat/copy input manually before arming again.
;
; Auto-detects _forever_ installations on any drive. Alt-Tab pauses and each
; armed client keeps its own step. No input is sent to background windows.
; Holding either main mouse button pauses steps so camera movement cannot
; turn copy/paste into game bindings. An interrupted sequence stops until
; you close unfinished input and explicitly re-arm; camera-only pauses at
; step one resume after both mouse buttons are released.
; Setup enables an optional preventive 50-second pause after ten invite attempts by
; default. Turn that checkbox off to measure the actual server limit; the
; addon still keeps its native rate-error recovery hold. Scans do not count.
; A partial batch resets after 30 seconds without an invite; an active
; 50-second pause always finishes. Batch and total attempts are shown per
; armed client, not confirmed invitations.
; The addon supplies the highlighted /ginvite First Last or /who command.
; Older addon builds without keyboard /who fallback need Scan next/Wingman
; to obtain Ready players first. Native server/addon cooldowns still apply.
; Exit from the tray menu to stop. Setup saves controls and pause choice for this
; Windows user; no account settings, game data or executable are bundled.
; This optional helper is not required by the addon. Its separate taps and
; pacing are not a guarantee of approval by Blizzard or CurseForge.

helperBuild := "2026-11-10 stable-1.1.0"
settings := {stepKey: "Up", actionKey: "F8", pauseAfterTen: true}
inviteMacroKey := "{F8}"
foreverExe := ""
cycles := Map()
stepOwner := 0
stepHeld := false
registeredHotkeys := []
reconfiguring := false
hotkeysReady := false
restartRequired := false
settingsPath := A_AppData "\DandyRecruiterAHK\settings.ini"
setupWindow := 0
setupStep := 0
setupAction := 0
setupPause := 0
setupNotice := 0
SetKeyDelay(25, 35)
InitializeHelper()

SupportedKeys(includeMouse := false) {
    keys := ["Up", "Down", "Left", "Right", "Home", "End", "PgUp", "PgDn", "Insert"]
    if !includeMouse
        keys.Push("Delete")
    Loop 24
        keys.Push("F" A_Index)
    Loop 10
        keys.Push("Numpad" (A_Index - 1))
    for _, key in ["NumpadAdd", "NumpadSub", "NumpadMult", "NumpadDiv"]
        keys.Push(key)
    if !includeMouse
        keys.Push("NumpadDot")
    Loop 26
        keys.Push(Chr(64 + A_Index))
    Loop 10
        keys.Push((A_Index - 1) "")
    if includeMouse {
        for _, key in ["MButton", "XButton1", "XButton2"]
            keys.Push(key)
    }
    return keys
}

NormalizeKey(key, includeMouse := false) {
    if Type(key) != "String"
        throw ValueError("Choose a key from the list.")
    for _, allowed in SupportedKeys(includeMouse) {
        if StrLower(key) == StrLower(allowed)
            return allowed
    }
    throw ValueError("That key is not supported. Choose a key from the list.")
}

NormalizeConfig(stepKey, actionKey, pauseAfterTen := true) {
    if Type(pauseAfterTen) != "Integer" || (pauseAfterTen != 0 && pauseAfterTen != 1)
        throw ValueError("Choose whether to pause after ten invite attempts.")
    result := {stepKey: NormalizeKey(stepKey, true), actionKey: NormalizeKey(actionKey), pauseAfterTen: pauseAfterTen == 1}
    if result.stepKey == result.actionKey
        throw ValueError("Choose different Step and Recruit next keys.")
    return result
}

HotkeyPlan(config) {
    checked := NormalizeConfig(config.stepKey, config.actionKey)
    key := checked.stepKey
    return [
        {context: "forever", predicate: IsForeverActive, key: "^!" key, callback: ToggleCycle},
        {context: "armed", predicate: InArmedWindow, key: "~*!Tab", callback: PauseActive},
        {context: "armed", predicate: InArmedWindow, key: "~$Esc", callback: DisarmActive},
        {context: "step", predicate: CanMarkStep, key: "$*" key, callback: MarkStepDown},
        {context: "tracked", predicate: HasCycles, key: "~$*" key, callback: IgnoreStep},
        {context: "tracked", predicate: HasCycles, key: "~$*" key " Up", callback: ReleaseStep},
        {context: "armed", predicate: InArmedWindow, key: "~$*LButton", callback: InterruptForMouse},
        {context: "armed", predicate: InArmedWindow, key: "~$*RButton", callback: InterruptForMouse}
    ]
}

SetHotkeyPlan(plan, enabled) {
    failures := []
    try {
        for _, item in plan {
            if enabled {
                HotIf(item.predicate)
                Hotkey(item.key, item.callback, "On")
            } else {
                ; Rollback must visit the entire plan: later entries may exist
                ; even when an earlier registration failed partway through.
                try {
                    HotIf(item.predicate)
                    Hotkey(item.key, "Off")
                } catch TargetError {
                    ; A not-yet-created variant is already inactive.
                    continue
                } catch as problem {
                    failures.Push(problem)
                }
            }
        }
    } finally {
        HotIf()
    }
    if failures.Length
        throw failures[1]
}

ReplaceHotkeys(config) {
    global registeredHotkeys, hotkeysReady, restartRequired
    if restartRequired
        throw Error("Controls require a restart. Exit and restart the helper before using it.")
    next := HotkeyPlan(config)
    previous := registeredHotkeys
    hotkeysReady := false
    try {
        SetHotkeyPlan(previous, false)
        SetHotkeyPlan(next, true)
    } catch as problem {
        ; Every variant stays ineligible unless cleanup and restoration finish.
        cleanupFailed := false
        for _, plan in [next, previous] {
            try SetHotkeyPlan(plan, false)
            catch
                cleanupFailed := true
        }
        if cleanupFailed {
            restartRequired := true
            registeredHotkeys := []
            throw Error("Controls stopped because a hotkey could not be disabled. Exit and restart the helper before using it.")
        }
        try {
            SetHotkeyPlan(previous, true)
            registeredHotkeys := previous
            hotkeysReady := previous.Length > 0
        } catch {
            restartRequired := true
            registeredHotkeys := []
            hotkeysReady := false
            throw Error("Hotkeys could not be restored. Exit and restart the helper before using it.")
        }
        throw problem
    }
    registeredHotkeys := next
    hotkeysReady := true
}

ReadSettings() {
    global settingsPath
    defaults := NormalizeConfig("Up", "F8")
    if !FileExist(settingsPath)
        return {config: defaults, setup: true, notice: "Choose your controls, then bind the same Recruit next key in WoW."}
    try {
        if IniRead(settingsPath, "Helper", "schema", "") != "1"
            throw ValueError("Unknown settings format")
        pauseValue := IniRead(settingsPath, "Helper", "pauseAfterTen", "1")
        if Type(pauseValue) != "String" || !RegExMatch(pauseValue, "\A[01]\z")
            throw ValueError("Invalid saved pause choice")
        checked := NormalizeConfig(IniRead(settingsPath, "Helper", "stepKey", ""), IniRead(settingsPath, "Helper", "actionKey", ""), pauseValue == "1")
        return {config: checked, setup: false, notice: ""}
    } catch {
        return {config: defaults, setup: true, notice: "Saved controls could not be read. Defaults are active until you Save valid choices."}
    }
}

WriteSettings(config) {
    global settingsPath
    config := NormalizeConfig(config.stepKey, config.actionKey, config.HasOwnProp("pauseAfterTen") ? config.pauseAfterTen : true)
    SplitPath(settingsPath, , &folder)
    DirCreate(folder)
    temporary := settingsPath "." DllCall("GetCurrentProcessId", "UInt") "." A_TickCount ".tmp"
    try {
        ; Preserve unknown local fields instead of rebuilding the user's INI.
        if FileExist(settingsPath)
            FileCopy(settingsPath, temporary, false)
        IniWrite("1", temporary, "Helper", "schema")
        IniWrite(config.stepKey, temporary, "Helper", "stepKey")
        IniWrite(config.actionKey, temporary, "Helper", "actionKey")
        IniWrite(config.pauseAfterTen ? "1" : "0", temporary, "Helper", "pauseAfterTen")
        FileMove(temporary, settingsPath, true)
    } catch as problem {
        try FileDelete(temporary)
        throw problem
    }
}

ApplySettings(stepKey, actionKey, pauseAfterTen := true) {
    global settings, inviteMacroKey, reconfiguring, hotkeysReady, restartRequired
    if restartRequired
        throw Error("Controls require a restart. Exit and restart the helper before using it.")
    checked := NormalizeConfig(stepKey, actionKey, pauseAfterTen)
    previous := settings
    reconfiguring := true
    try {
        DisarmAll()
        ReplaceHotkeys(checked)
        try WriteSettings(checked)
        catch as problem {
            try ReplaceHotkeys(previous)
            catch {
                ; Even a clean inner rollback can restore the NEW plan. It
                ; cannot be used with the still-OLD settings/action key.
                restartRequired := true
                hotkeysReady := false
                throw Error("Settings could not be restored. Exit and restart the helper before using it.")
            }
            throw problem
        }
        settings := checked
        inviteMacroKey := "{" checked.actionKey "}"
    } finally {
        reconfiguring := false
    }
}

InitializeHelper() {
    global settings, inviteMacroKey, helperBuild
    loaded := ReadSettings()
    settings := loaded.config
    inviteMacroKey := "{" settings.actionKey "}"
    try ReplaceHotkeys(settings)
    catch as problem {
        MsgBox("Controls could not start. No helper input is enabled.`n" problem.Message, "DandyRecruiter Helper", "Icon!")
        ExitApp()
    }
    A_IconTip := "DandyRecruiter Helper - " helperBuild " - Setup in tray menu"
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Setup...", ShowSetup)
    A_TrayMenu.Default := "Setup..."
    A_TrayMenu.Add("Disarm all clients", DisarmAllNotice)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", ExitHelper)
    if loaded.setup
        ShowSetup(loaded.notice)
}

ShowSetup(notice := "", *) {
    global setupWindow, setupStep, setupAction, setupPause, setupNotice, settings, helperBuild
    if !IsObject(setupWindow) {
        setupWindow := Gui("", "DandyRecruiter Helper - Setup - " helperBuild)
        setupWindow.SetFont("s10", "Segoe UI")
        setupWindow.AddText("w480", "Choose one key or side mouse button to advance each separate step.")
        setupWindow.AddText("xm y+16", "Step key / button")
        setupStep := setupWindow.AddDropDownList("xm y+5 w230", SupportedKeys(true))
        setupWindow.AddText("xm y+16", "WoW Recruit next key")
        setupAction := setupWindow.AddDropDownList("xm y+5 w230", SupportedKeys())
        setupWindow.AddText("xm y+16 w480", "Matching DandyRecruiter builds provide F8 automatically. For another key, bind that same key in WoW: Key Bindings > Dandy Suite > DandyRecruiter. Older builds also support /dandyrecruit queued.")
        setupWindow.AddText("xm y+12 w480", "Ctrl+Alt+your Step key/button arms or resets a stopped recruiter. Close unfinished input first. Esc disarms active cycles; stopped cycles retain counts. Tap and release once per step.")
        setupPause := setupWindow.AddCheckbox("xm y+14 w480", "Preventive pause: 50 seconds after 10 invite attempts")
        setupWindow.AddText("xm y+5 w480", "Optional helper pacing. WoW and addon recovery cooldowns still apply when this is off.")
        setupNotice := setupWindow.AddText("xm y+12 w480", "")
        setupWindow.AddButton("xm y+16 w110 Default", "Save").OnEvent("Click", SaveSetup)
        setupWindow.AddButton("x+10 w110", "Cancel").OnEvent("Click", HideSetup)
        setupWindow.OnEvent("Close", HideSetup)
        setupWindow.OnEvent("Escape", HideSetup)
    }
    SelectChoice(setupStep, SupportedKeys(true), settings.stepKey)
    SelectChoice(setupAction, SupportedKeys(), settings.actionKey)
    setupPause.Value := settings.pauseAfterTen
    ; Tray callbacks pass their menu item name; only startup supplies a notice.
    setupNotice.Text := Type(notice) == "String" && notice != "Setup..." ? notice : "Saving disarms all clients. Close unfinished chat/copy input manually before re-arming."
    setupWindow.Show("AutoSize")
}

SelectChoice(control, choices, value) {
    for index, key in choices {
        if key == value {
            control.Choose(index)
            return
        }
    }
}

SaveSetup(*) {
    global setupWindow, setupStep, setupAction, setupPause, setupNotice
    try ApplySettings(setupStep.Text, setupAction.Text, setupPause.Value)
    catch as problem {
        setupNotice.Text := "Not saved: " problem.Message
        return
    }
    setupWindow.Hide()
    ToolTip("Controls saved. Focus WoW and arm with " ArmLabel() ".`nThe helper is unarmed.")
    SetTimer(HideIdleTip, -3500)
}

HideSetup(*) {
    global setupWindow
    if IsObject(setupWindow)
        setupWindow.Hide()
}

DisarmAll(*) {
    global cycles, stepOwner, stepHeld
    states := []
    for _, state in cycles
        states.Push(state)
    for _, state in states
        Disarm(state)
    stepOwner := 0
    stepHeld := false
    SetTimer(WatchFocus, 0)
    ToolTip()
}

DisarmAllNotice(*) {
    DisarmAll()
    ToolTip("All recruiter clients are disarmed. Close unfinished chat/copy input manually.")
    SetTimer(HideIdleTip, -3500)
}

ExitHelper(*) {
    DisarmAll()
    ExitApp()
}

ArmLabel() {
    global settings
    return "Ctrl+Alt+" settings.stepKey
}

IsForeverActive(*) {
    global reconfiguring, hotkeysReady
    return !reconfiguring && hotkeysReady && IsForeverWindow(WinActive("A"))
}

CanMarkStep(*) {
    return InArmedWindow() && !HasModifiers()
}

PauseActive(*) {
    PauseCycle(ActiveCycle())
}

DisarmActive(*) {
    state := ActiveCycle()
    ; Physical Escape still reaches WoW, but must not erase a stopped
    ; client's pacing before its explicit reset/re-arm chord.
    if IsObject(state) && state.halted
        return
    Disarm(state)
}

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

InArmedWindow(*) {
    global reconfiguring, hotkeysReady
    return !reconfiguring && hotkeysReady && IsObject(ActiveCycle())
}

HasCycles(*) {
    global cycles, reconfiguring, hotkeysReady
    return !reconfiguring && hotkeysReady && cycles.Count > 0
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

CanSend(state) => IsCurrent(state) && !state.halted && !state.paused && !state.mousePaused && !MouseButtonsDown()

ClearHaltedPhase(state) {
    if !OwnsCycle(state) || !state.halted || state.busy
        return false
    changed := state.step != 1 || state.copied != "" || state.commandKind != ""
        || state.recoverFocus || state.waitingStatus || state.mousePaused || state.mouseReset
    state.step := 1
    state.copied := ""
    state.commandKind := ""
    state.recoverFocus := false
    state.waitingStatus := false
    state.mousePaused := false
    state.mouseReset := false
    return changed
}

HaltCycle(state, reason) {
    global stepOwner
    if !OwnsCycle(state)
        return
    if IsObject(stepOwner) && stepOwner == state
        stepOwner := 0
    state.halted := true
    state.haltReason := reason
    state.paused := true
    ClearHaltedPhase(state)
    ShowStep(state)
}

MouseButtonsDown() {
    return GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
}

PauseForMouse(state) {
    global stepOwner
    if !OwnsCycle(state)
        return
    if IsObject(stepOwner) && stepOwner == state
        stepOwner := 0
    state.mousePaused := true
    state.paused := true
    ; An input callback may still need its original step/kind to count a
    ; final Enter already injected. Reconcile only after that callback ends.
    if state.busy || state.step > 1 || state.copied != "" || state.recoverFocus
        state.mouseReset := true
}

InterruptForMouse(*) {
    state := ActiveCycle()
    if !IsObject(state) || !IsCurrent(state)
        return
    PauseForMouse(state)
    ShowStep(state)
}

ReconcileMouse(state) {
    if !OwnsCycle(state)
        return false
    if state.halted
        return ClearHaltedPhase(state)
    if MouseButtonsDown() {
        if IsCurrent(state)
            PauseForMouse(state)
        return false
    }
    if state.busy || !state.mousePaused
        return false
    if state.mouseReset {
        HaltCycle(state, "Mouse movement interrupted an input step.")
        return true
    }
    state.mousePaused := false
    state.mouseReset := false
    return true
}

ToggleCycle(*) {
    global cycles, stepOwner, stepHeld, settings
    static arming := false
    if arming
        return
    hwnd := WinActive("A")
    if !IsForeverWindow(hwnd)
        return
    armKey := settings.stepKey
    arming := true
    try {
        stepOwner := 0
        stepHeld := GetKeyState(armKey, "P")
        if cycles.Has(hwnd) {
            previous := cycles[hwnd]
            wasTracked := IsTrackedWindow(previous)
            if wasTracked && previous.halted {
                if !previous.busy {
                    ClearHaltedPhase(previous)
                    previous.halted := false
                    previous.haltReason := ""
                    previous.paused := false
                }
                ShowStep(previous)
                return
            }
            Disarm(previous)
            if wasTracked
                return
        }
        state := {
            window: hwnd, pid: WinGetPID("ahk_id " hwnd), step: 1,
            busy: false, copied: "", commandKind: "", paused: false, recoverFocus: false, waitingStatus: false,
            mousePaused: false, mouseReset: false,
            halted: false, haltReason: "",
            batchInvites: 0, inviteAttempts: 0, holdUntil: 0, lastInviteAt: -1
        }
        cycles[hwnd] := state
        SetTimer(WatchFocus, 75)
        ShowStep(state)
    } catch as problem {
        if cycles.Has(hwnd)
            Disarm(cycles[hwnd])
        throw problem
    } finally {
        try {
            ; Keep this callback alive until the full physical chord is up.
            ; MaxThreadsPerHotkey and the guard reject held-key repeats and
            ; fast next-step taps while Control or Alt is still held, including
            ; after a Setup change creates a new hotkey variant.
            KeyWait(armKey)
            KeyWait("Control")
            KeyWait("Alt")
        } catch as problem {
            if cycles.Has(hwnd)
                Disarm(cycles[hwnd])
            throw problem
        } finally {
            arming := false
        }
    }
}

WatchFocus() {
    global cycles, stepOwner, stepHeld, settings
    if !IsObject(stepOwner) && !GetKeyState(settings.stepKey, "P")
        stepHeld := false
    closed := []
    for hwnd, state in cycles {
        if !IsTrackedWindow(state) {
            closed.Push(state)
        } else {
            mouseChanged := ReconcileMouse(state)
            ; The key callback owns counter writes until its step completes.
            pacingChanged := !state.busy && RefreshInvitePacing(state)
            if !WinActive("ahk_id " hwnd)
                PauseCycle(state)
            else if state.halted {
                if !state.busy && (pacingChanged || mouseChanged)
                    ShowStep(state)
            } else if state.paused && !state.busy && !state.mousePaused && !MouseButtonsDown() && !GetKeyState("Alt", "P") {
                state.paused := false
                ShowStep(state)
            } else if (pacingChanged || mouseChanged) && !state.busy && !state.paused {
                ShowStep(state)
            }
        }
    }
    for _, state in closed
        Disarm(state)
    if !InArmedWindow()
        ToolTip()
}

PauseCycle(state) {
    global stepOwner
    if !OwnsCycle(state)
        return
    if IsObject(stepOwner) && stepOwner == state
        stepOwner := 0
    if !state.paused {
        state.paused := true
        if !InArmedWindow()
            ToolTip()
    }
}

IgnoreStep(*) {
    global stepOwner, stepHeld
    stepOwner := 0
    stepHeld := true
}

Disarm(state, reason := "") {
    global cycles, stepOwner
    if !OwnsCycle(state)
        return
    if IsObject(stepOwner) && stepOwner == state
        stepOwner := 0
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

MarkStepDown(*) {
    global stepOwner, stepHeld
    if stepHeld
        return
    stepHeld := true
    state := ActiveCycle()
    if !IsObject(state) || !IsCurrent(state) || state.busy
        return
    ReconcileMouse(state)
    if state.halted {
        ShowStep(state)
        return
    }
    if state.mousePaused || MouseButtonsDown() {
        ShowStep(state)
        return
    }
    state.paused := false
    stepOwner := state
}

ReleaseStep(*) {
    global stepOwner, stepHeld
    state := stepOwner
    stepOwner := 0
    stepHeld := false
    if !IsObject(state) || !CanSend(state) || HasModifiers() || state.busy
        return

    state.busy := true
    try Advance(state)
    catch {
        if OwnsCycle(state)
            Disarm(state, IsCurrent(state) ? "Stopped. Check WoW and re-arm with " ArmLabel() "." : "")
    } finally {
        state.busy := false
        ClearHaltedPhase(state)
    }
}

SendStepInput(state, keys) {
    if !CanSend(state)
        return false
    SendEvent(keys)
    if CanSend(state)
        return true
    if IsCurrent(state) && (state.mousePaused || MouseButtonsDown()) {
        PauseForMouse(state)
        ; The input was injected before the mouse interruption. Preserve
        ; its final-attempt accounting, then stop before advancing stages.
        return true
    }
    if OwnsCycle(state)
        Disarm(state, "Switched windows during input. Check WoW and re-arm with " ArmLabel() ".")
    return false
}

RefreshInvitePacing(state) {
    now := A_TickCount
    ; A full batch's 50-second hold outranks the partial-batch idle reset.
    if state.holdUntil > now
        return false
    if state.holdUntil > 0 {
        state.holdUntil := 0
        state.batchInvites := 0
        state.lastInviteAt := -1
        return true
    }
    if state.batchInvites > 0 && state.lastInviteAt >= 0 && now - state.lastInviteAt >= 30000 {
        state.batchInvites := 0
        state.lastInviteAt := -1
        return true
    }
    return false
}

Advance(state) {
    global inviteMacroKey, settings
    if !CanSend(state)
        return
    if state.recoverFocus && !state.waitingStatus {
        HaltCycle(state, "The current input focus could not be confirmed.")
        return
    }
    RefreshInvitePacing(state)
    if state.holdUntil > 0 {
        ShowStep(state)
        return
    }
    if state.recoverFocus {
        ; Only a fresh owned waiting marker authorizes this separate Escape.
        ; Unknown focus never uses Escape as an automatic recovery attempt.
        if !SendStepInput(state, "{Esc}")
            return
        state.recoverFocus := false
        state.waitingStatus := false
        state.step := 1
        ShowStep(state, "Escape sent. The next tap requests a fresh command.")
        return
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
                if CanSend(state) && (copyResult == "invalid" || copyResult == "timeout" || copyResult == "waiting") {
                    if copyResult != "waiting" {
                        HaltCycle(state, "No fresh command or owned waiting status was copied.")
                        return
                    }
                    state.step := 1
                    state.copied := ""
                    state.commandKind := ""
                    state.recoverFocus := true
                    state.waitingStatus := true
                    ShowStep(state, "The addon is waiting. Finish this input step with Escape, then retry when ready.")
                }
                return
            }
        case 3, 4, 6:
            if !SendStepInput(state, "{Enter}")
                return
            if state.step == 6 && state.commandKind == "invite" {
                state.batchInvites += 1
                state.inviteAttempts += 1
                state.lastInviteAt := A_TickCount
                if settings.pauseAfterTen && state.batchInvites >= 10
                    state.holdUntil := A_TickCount + 50000
            }
        case 5:
            if !PasteCommand(state) {
                if CanSend(state)
                    HaltCycle(state, "The paste step could not be verified.")
                return
            }
    }
    if !CanSend(state)
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
                if text == "DandyRecruiter is waiting."
                    return "waiting"
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
    kind := CommandKind(state.copied)
    if kind == "" || !(kind == state.commandKind)
        return false
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
    global settings
    if !IsCurrent(state)
        return
    if state.halted {
        ToolTip("STOPPED: " state.haltReason "`nClose unfinished WoW chat/copy input yourself.`nThen press " ArmLabel() " to re-arm this client.`nBatch attempts: " state.batchInvites "/10`nInvite attempts: " state.inviteAttempts "`nCounts and cooldown are retained. Escape only closes WoW input.")
        return
    }
    if state.mousePaused || MouseButtonsDown() {
        ToolTip("Recruiting paused for mouse movement.`nRelease both left and right mouse buttons before tapping " settings.stepKey ".`nBatch attempts: " state.batchInvites "/10`nInvite attempts: " state.inviteAttempts "`nEsc disarms")
        return
    }
    if !CanSend(state)
        return
    remaining := Max(0, Ceil((state.holdUntil - A_TickCount) / 1000))
    if remaining > 0 {
        ToolTip("Helper pacing pause: " remaining "s remaining.`nBatch attempts: " state.batchInvites "/10`nInvite attempts: " state.inviteAttempts "`nTen invite attempts in this batch. Tap " settings.stepKey " after the pause.`nEsc disarms")
        return
    }
    if state.recoverFocus {
        heading := state.waitingStatus ? "DandyRecruiter is waiting. Check the Inviter for the reason and countdown." : "No fresh command copied."
        action := state.waitingStatus
            ? "Tap " settings.stepKey " to finish the waiting step (Escape)."
            : "Recovery: tap " settings.stepKey " for Escape."
        ToolTip(heading "`n" action "`nThen tap again for Recruit next (" settings.actionKey ").`nBatch attempts: " state.batchInvites "/10`nInvite attempts: " state.inviteAttempts "`nEsc disarms")
        return
    }
    labels := [
        "Recruit next or prepare scan (" settings.actionKey ")",
        "Copy the highlighted /ginvite or /who command",
        "Finish copying (panel stays open)",
        "Open WoW chat",
        "Paste the copied command",
        "Check the chat line, then send the invite or scan"
    ]
    if note != ""
        note .= "`n"
    ToolTip(settings.stepKey " " state.step "/6  " labels[state.step] "`nBatch attempts: " state.batchInvites "/10`nInvite attempts: " state.inviteAttempts "`n" note "Esc disarms")
}
