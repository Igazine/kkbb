import AppKit
import Foundation

public final class KeyboardMonitor {
    public static let shared = KeyboardMonitor()

    private var localMonitor: Any?
    private var pressedKeyToNote: [UInt16: UInt8] = [:]
    private weak var appState: AppState?
    private let midiManager = MIDIManager.shared

    private init() {}

    public func start(with appState: AppState) {
        self.appState = appState
        guard localMonitor == nil else { return }

        // Release hanging notes when window or app loses focus
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
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
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        allNotesOff()
    }

    private func handleEvent(_ event: NSEvent) -> Bool {
        guard let appState = appState else { return false }

        // Let system commands (Cmd+Q, Cmd+W, Cmd+H, etc.) pass through normally
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
            return false
        }

        if event.type == .keyDown {
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

            // Check if this key is already pressed
            if pressedKeyToNote[event.keyCode] != nil {
                return true
            }

            guard let note = resolveNote(for: event, mode: appState.mode, octave: appState.octave) else {
                return false
            }

            pressedKeyToNote[event.keyCode] = note
            let velocity = UInt8(appState.velocity)
            let channel = appState.channel
            let destUID = appState.selectedDestinationUID

            midiManager.sendNoteOn(note: note, velocity: velocity, channel: channel, destinationUID: destUID)

            DispatchQueue.main.async {
                appState.activeNotes.insert(note)
            }
            return true

        } else if event.type == .keyUp {
            guard let note = pressedKeyToNote.removeValue(forKey: event.keyCode) else {
                return false
            }

            let channel = appState.channel
            let destUID = appState.selectedDestinationUID
            midiManager.sendNoteOff(note: note, channel: channel, destinationUID: destUID)

            DispatchQueue.main.async {
                appState.activeNotes.remove(note)
            }
            return true
        }

        return false
    }

    public func allNotesOff() {
        guard let appState = appState else { return }
        for note in pressedKeyToNote.values {
            midiManager.sendNoteOff(note: note, channel: appState.channel, destinationUID: appState.selectedDestinationUID)
        }
        pressedKeyToNote.removeAll()
        midiManager.allNotesOff(channel: appState.channel, destinationUID: appState.selectedDestinationUID)
        DispatchQueue.main.async {
            appState.activeNotes.removeAll()
        }
    }

    private func resolveNote(for event: NSEvent, mode: KeyboardMode, octave: Int) -> UInt8? {
        guard let char = event.charactersIgnoringModifiers?.lowercased().first else {
            return nil
        }

        let baseNote = UInt8((octave + 1) * 12) // Octave 3 -> Note 48 (C3)

        switch mode {
        case .oneOctave:
            guard let semitone = oneOctaveMapping[char] else { return nil }
            let finalNote = Int(baseNote) + semitone
            return (0...127).contains(finalNote) ? UInt8(finalNote) : nil

        case .twoOctaves:
            guard let semitone = twoOctaveMapping[char] else { return nil }
            let finalNote = Int(baseNote) + semitone
            return (0...127).contains(finalNote) ? UInt8(finalNote) : nil
        }
    }

    // Semi-tone offsets for 1-octave mode
    private let oneOctaveMapping: [Character: Int] = [
        "a": 0,   // C
        "w": 1,   // C#
        "s": 2,   // D
        "e": 3,   // D#
        "d": 4,   // E
        "f": 5,   // F
        "t": 6,   // F#
        "g": 7,   // G
        "y": 8,   // G#
        "h": 9,   // A
        "u": 10,  // A#
        "j": 11,  // B
        "k": 12   // C (next octave)
    ]

    // Semi-tone offsets for 2-octave mode
    private let twoOctaveMapping: [Character: Int] = [
        "z": 0,   // C
        "s": 1,   // C#
        "x": 2,   // D
        "d": 3,   // D#
        "c": 4,   // E
        "v": 5,   // F
        "g": 6,   // F#
        "b": 7,   // G
        "h": 8,   // G#
        "n": 9,   // A
        "j": 10,  // A#
        "m": 11,  // B
        ",": 12,  // C (octave 2)
        "q": 12,  // C (octave 2)
        "2": 13,  // C# (octave 2)
        "w": 14,  // D (octave 2)
        "3": 15,  // D# (octave 2)
        "e": 16,  // E (octave 2)
        "r": 17,  // F (octave 2)
        "4": 18,  // F# (octave 2)
        "t": 19,  // G (octave 2)
        "5": 20,  // G# (octave 2)
        "y": 21,  // A (octave 2)
        "6": 22,  // A# (octave 2)
        "u": 23,  // B (octave 2)
        "i": 24   // C (octave 3)
    ]
}
