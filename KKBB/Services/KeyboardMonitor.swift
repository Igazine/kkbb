import AppKit
import Foundation
import Carbon

public final class KeyboardMonitor {
    public static let shared = KeyboardMonitor()

    private var localMonitor: Any?
    private var hotKeyModeToken: UnsafeMutableRawPointer?
    private var pressedKeyToNotes: [UInt16: [UInt8]] = [:]
    private var pressedKeyToCC: [UInt16: CCKeyBinding] = [:]
    private var activeCCToggleStates: [UUID: Bool] = [:]
    public var keyCaptureHandler: ((NSEvent) -> Bool)?
    private weak var appState: AppState?
    private let pipeline = MIDIPipeline.shared

    private init() {}

    public var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func start(with appState: AppState) {
        self.appState = appState
        guard localMonitor == nil else { return }

        enableSystemHotKeySuppression()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enableSystemHotKeySuppression()
        }

        // Release hanging notes when window or app loses focus
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.disableSystemHotKeySuppression()
            self?.allNotesOff()
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self else { return event }
            if self.handleEvent(event) {
                return nil // Handled, suppress system default behavior
            }
            return event
        }
    }

    public func stop() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        disableSystemHotKeySuppression()
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        allNotesOff()
    }

    private func enableSystemHotKeySuppression() {
        guard hotKeyModeToken == nil else { return }
        // 1 = kHIHotKeyModeAllDisabled (suppresses Mission Control, Show Desktop F11, etc. when focused)
        hotKeyModeToken = PushSymbolicHotKeyMode(1)
    }

    private func disableSystemHotKeySuppression() {
        if let token = hotKeyModeToken {
            PopSymbolicHotKeyMode(token)
            hotKeyModeToken = nil
        }
    }

    private func handleEvent(_ event: NSEvent) -> Bool {
        // 1. If key capture handler is active (e.g. recording a hotkey), give it exclusive priority!
        if let capture = keyCaptureHandler {
            if capture(event) {
                return true
            }
            return false
        }

        // 2. If any modal sheet is open on any window, let the sheet handle keystrokes
        for window in NSApp.windows {
            if window.isSheet || window.attachedSheet != nil {
                return false
            }
        }

        // 3. If an editable text field/view is the first responder, do not steal keys
        if let responder = event.window?.firstResponder ?? NSApp.keyWindow?.firstResponder {
            if responder is NSText || responder is NSTextView || responder is NSTextField {
                return false
            }
        }

        guard let appState = appState else { return false }

        // 4. Let critical system menu shortcuts pass through (Cmd+Q, Cmd+W, Cmd+H, Cmd+M, Cmd+,)
        if event.modifierFlags.contains(.command) {
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                if chars == "q" || chars == "w" || chars == "h" || chars == "m" || chars == "," {
                    return false
                }
            }
        }

        if event.type == .keyDown {
            // In Computer Keyboard mode: route all physical keys directly to computer keyboard engine
            if appState.mode == .computerKeyboard {
                if event.isARepeat { return true }
                DispatchQueue.main.async {
                    appState.triggerComputerKeyOn(keyCode: event.keyCode)
                }
                return true
            }

            // Check for Arrow keys (Octave: Up/Down, Velocity: Left/Right)
            switch event.keyCode {
            case 126: // Up Arrow -> Octave +1
                DispatchQueue.main.async {
                    if appState.octave < 6 {
                        appState.octave += 1
                    }
                }
                return true
            case 125: // Down Arrow -> Octave -1
                DispatchQueue.main.async {
                    if appState.octave > 0 {
                        appState.octave -= 1
                    }
                }
                return true
            case 123: // Left Arrow -> Velocity -1 (or -10 with Shift)
                let step = event.modifierFlags.contains(.shift) ? 10 : 1
                DispatchQueue.main.async {
                    appState.velocity = Swift.max(1, appState.velocity - step)
                }
                return true
            case 124: // Right Arrow -> Velocity +1 (or +10 with Shift)
                let step = event.modifierFlags.contains(.shift) ? 10 : 1
                DispatchQueue.main.async {
                    appState.velocity = Swift.min(127, appState.velocity + step)
                }
                return true
            default:
                break
            }

            // Check for octave shifts (* and /)
            let directChar = event.characters
            let rawChar = event.charactersIgnoringModifiers
            if directChar == "*" || rawChar == "*" {
                DispatchQueue.main.async {
                    if appState.octave < 6 {
                        appState.octave += 1
                    }
                }
                return true
            } else if directChar == "/" || rawChar == "/" {
                DispatchQueue.main.async {
                    if appState.octave > 0 {
                        appState.octave -= 1
                    }
                }
                return true
            }

            // Suppress OS key repeat
            if event.isARepeat {
                return true
            }

            // Check if this key matches any Chord Pad hot-key (only in piano modes)
            if appState.mode != .drumGrid,
               let padIndex = appState.activeProfile.chordPads.firstIndex(where: { $0.matches(event: event) }) {
                DispatchQueue.main.async {
                    appState.toggleChordPad(index: padIndex)
                }
                return true
            }

            // In Drum Grid mode: check all banks, giving priority to the visible bank
            if appState.mode == .drumGrid {
                let currentBank = appState.octave
                var matchedPad: DrumPadConfig? = nil

                // 1. Check visible bank first
                for pIdx in 0..<16 {
                    if let cfg = appState.drumPadConfig(bank: currentBank, padIndex: pIdx),
                       cfg.matches(event: event) && cfg.isAssigned {
                        matchedPad = cfg
                        break
                    }
                }

                // 2. If not matched in visible bank, check all other banks across the active profile
                if matchedPad == nil {
                    for (_, cfg) in appState.activeProfile.drumPads {
                        if cfg.bank != currentBank && cfg.matches(event: event) && cfg.isAssigned {
                            matchedPad = cfg
                            break
                        }
                    }
                }

                if let pad = matchedPad {
                    // Check if this pad is assigned to a MIDI Command (Transport / Panic) or CC Button
                    if pad.midiCommand != nil || pad.ccConfig != nil {
                        DispatchQueue.main.async {
                            appState.triggerDrumPadOn(bank: pad.bank, padIndex: pad.padIndex)
                        }
                        return true
                    }

                    let notesToPlay = pad.notesToSend
                    if !notesToPlay.isEmpty {
                        pressedKeyToNotes[event.keyCode] = notesToPlay
                        let velocity = UInt8(appState.velocity)
                        let channel = appState.channel
                        let destUID = appState.selectedDestinationUID

                        for n in notesToPlay {
                            pipeline.sendNoteOn(note: n, velocity: velocity, channel: channel, destinationUID: destUID)
                        }

                        let padKey = "\(pad.bank)_\(pad.padIndex)"
                        DispatchQueue.main.async {
                            appState.activeDrumPadKeys.insert(padKey)
                            for n in notesToPlay {
                                appState.activeNotes.insert(n)
                            }
                        }

                        if appState.isOneShotMode {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak appState] in
                                guard let self = self, let appState = appState else { return }
                                for n in notesToPlay {
                                    self.pipeline.sendNoteOff(note: n, channel: channel, destinationUID: destUID)
                                    appState.activeNotes.remove(n)
                                }
                                appState.activeDrumPadKeys.remove(padKey)
                            }
                        }
                        return true
                    }
                }
            }

            // Check if this key matches a configured MIDI CC Key Trigger
            if let ccBinding = appState.activeProfile.ccBindings.first(where: { matchesKey(keyChar: $0.keyChar, event: event) }) {
                let channel = appState.channel
                let destUID = appState.selectedDestinationUID

                switch ccBinding.mode {
                case .momentary:
                    pressedKeyToCC[event.keyCode] = ccBinding
                    pipeline.sendCC(controller: ccBinding.controller, value: ccBinding.value, channel: channel, destinationUID: destUID)
                case .trigger:
                    pipeline.sendCC(controller: ccBinding.controller, value: ccBinding.value, channel: channel, destinationUID: destUID)
                case .toggle:
                    let currentlyOn = activeCCToggleStates[ccBinding.id] ?? false
                    let newState = !currentlyOn
                    activeCCToggleStates[ccBinding.id] = newState
                    let val: UInt8 = newState ? ccBinding.value : 0
                    pipeline.sendCC(controller: ccBinding.controller, value: val, channel: channel, destinationUID: destUID)
                }
                return true
            }

            // Check if this key is already pressed for note
            if pressedKeyToNotes[event.keyCode] != nil {
                return true
            }

            guard let rootNote = resolveNote(for: event, mode: appState.mode, octave: appState.octave, profile: appState.activeProfile) else {
                return false
            }

            let notesToPlay = appState.notesForRoot(rootNote)

            pressedKeyToNotes[event.keyCode] = notesToPlay
            let velocity = UInt8(appState.velocity)
            let channel = appState.channel
            let destUID = appState.selectedDestinationUID

            for n in notesToPlay {
                pipeline.sendNoteOn(note: n, velocity: velocity, channel: channel, destinationUID: destUID)
            }

            DispatchQueue.main.async {
                appState.pressedRootNotes.insert(rootNote)
                for n in notesToPlay {
                    appState.activeNotes.insert(n)
                }
            }

            if appState.isOneShotMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak appState] in
                    guard let self = self, let appState = appState else { return }
                    for n in notesToPlay {
                        self.pipeline.sendNoteOff(note: n, channel: channel, destinationUID: destUID)
                        appState.activeNotes.remove(n)
                    }
                    appState.pressedRootNotes.remove(rootNote)
                }
            }
            return true

        } else if event.type == .keyUp {
            if appState.mode == .computerKeyboard {
                DispatchQueue.main.async {
                    appState.triggerComputerKeyOff(keyCode: event.keyCode)
                }
                return true
            }

            if appState.mode == .drumGrid {
                var handledDrumPad = false
                for (_, cfg) in appState.activeProfile.drumPads {
                    if cfg.matches(event: event) {
                        DispatchQueue.main.async {
                            appState.triggerDrumPadOff(bank: cfg.bank, padIndex: cfg.padIndex)
                        }
                        handledDrumPad = true
                    }
                }

                if let notes = pressedKeyToNotes.removeValue(forKey: event.keyCode) {
                    if !appState.isOneShotMode {
                        let channel = appState.channel
                        let destUID = appState.selectedDestinationUID
                        for n in notes {
                            pipeline.sendNoteOff(note: n, channel: channel, destinationUID: destUID)
                        }

                        DispatchQueue.main.async {
                            for n in notes {
                                appState.activeNotes.remove(n)
                            }
                        }
                    }
                    return true
                }

                if handledDrumPad {
                    return true
                }
            }

            // Check if this key was triggering a momentary CC
            if let ccBinding = pressedKeyToCC.removeValue(forKey: event.keyCode) {
                if ccBinding.mode == .momentary {
                    let channel = appState.channel
                    let destUID = appState.selectedDestinationUID
                    pipeline.sendCC(controller: ccBinding.controller, value: 0, channel: channel, destinationUID: destUID)
                    return true
                }
            }

            // Check if this key was playing notes
            guard let notes = pressedKeyToNotes.removeValue(forKey: event.keyCode) else {
                return false
            }

            if !appState.isOneShotMode {
                let channel = appState.channel
                let destUID = appState.selectedDestinationUID
                for n in notes {
                    pipeline.sendNoteOff(note: n, channel: channel, destinationUID: destUID)
                }

                let releasedRoot = resolveNote(for: event, mode: appState.mode, octave: appState.octave, profile: appState.activeProfile)
                DispatchQueue.main.async {
                    for n in notes {
                        appState.activeNotes.remove(n)
                    }
                    if let root = releasedRoot {
                        appState.pressedRootNotes.remove(root)
                    }
                }
            }
            return true
        }

        return false
    }

    public func allNotesOff() {
        guard let appState = appState else { return }
        for notes in pressedKeyToNotes.values {
            for note in notes {
                pipeline.sendNoteOff(note: note, channel: appState.channel, destinationUID: appState.selectedDestinationUID)
            }
        }
        pressedKeyToNotes.removeAll()
        pressedKeyToCC.removeAll()
        activeCCToggleStates.removeAll()
        pipeline.allNotesOff(channel: appState.channel, destinationUID: appState.selectedDestinationUID)
        DispatchQueue.main.async {
            appState.activeNotes.removeAll()
            appState.pressedRootNotes.removeAll()
            appState.activeDrumPadKeys.removeAll()
            appState.activeComputerKeys.removeAll()
            appState.activeComputerCCToggles.removeAll()
        }
    }

    private func resolveNote(for event: NSEvent, mode: KeyboardMode, octave: Int, profile: KeyBindingProfile) -> UInt8? {
        guard let charStr = event.charactersIgnoringModifiers?.lowercased(),
              let char = charStr.first else {
            return nil
        }
        let keyString = String(char)

        let baseNote = UInt8((octave + 1) * 12) // Octave 3 -> Note 48 (C3)

        switch mode {
        case .oneOctave:
            if let semitone = profile.oneOctaveNoteMap[keyString] {
                let finalNote = Int(baseNote) + semitone
                return (0...127).contains(finalNote) ? UInt8(finalNote) : nil
            }
        case .twoOctaves:
            if let semitone = profile.twoOctaveNoteMap[keyString] {
                let finalNote = Int(baseNote) + semitone
                return (0...127).contains(finalNote) ? UInt8(finalNote) : nil
            }
        case .drumGrid, .computerKeyboard:
            return nil
        }
        return nil
    }

    private func matchesKey(keyChar: String, event: NSEvent) -> Bool {
        if keyChar == " " || keyChar.lowercased() == "space" {
            return event.keyCode == 49
        }

        let normalized = keyChar.trimmingCharacters(in: .whitespaces).lowercased()
        if normalized.count == 1 {
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                return chars == normalized
            }
        }

        switch normalized {
        case "pageup", "page up":
            return event.keyCode == 116
        case "pagedown", "page down":
            return event.keyCode == 121
        case "home":
            return event.keyCode == 115
        case "end":
            return event.keyCode == 119
        case "space":
            return event.keyCode == 49
        case "tab":
            return event.keyCode == 48
        case "return", "enter":
            return event.keyCode == 36
        case "f1": return event.keyCode == 122
        case "f2": return event.keyCode == 120
        case "f3": return event.keyCode == 99
        case "f4": return event.keyCode == 118
        case "f5": return event.keyCode == 96
        case "f6": return event.keyCode == 97
        case "f7": return event.keyCode == 98
        case "f8": return event.keyCode == 100
        case "f9": return event.keyCode == 101
        case "f10": return event.keyCode == 109
        case "f11": return event.keyCode == 103
        case "f12": return event.keyCode == 111
        default:
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                return chars == normalized
            }
            return false
        }
    }
}
