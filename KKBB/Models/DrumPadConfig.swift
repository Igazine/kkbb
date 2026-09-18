import Foundation
import AppKit

public struct DrumPadConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var bank: Int // 0...6
    public var padIndex: Int // 0...15
    public var keyCode: UInt16?
    public var modifierFlags: UInt?
    public var keyTrigger: String? // Display label, e.g. "Q", "Space", "⇧A"
    public var semitone: UInt8? // 0...11 (C...B)
    public var octave: Int? // 0...6
    public var chordTypeID: String? // nil or "none" or ChordType.id
    public var midiCommand: MIDICommandType? // Optional transport or panic command
    public var ccConfig: DrumPadCCConfig? // Optional MIDI Control Change (CC) button/trigger
    public var channelOverride: Int? // 1...16, nil = follow global
    public var destinationOverrideUID: String? // nil = follow global, "virtual" = Virtual Only, "\(id)" = specific device
    public var destinationOverrideName: String? // display name for context menu / offline device
    public var colorAccent: PadColorAccent? // nil = default neutral

    public static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    public init(
        id: UUID = UUID(),
        bank: Int,
        padIndex: Int,
        keyCode: UInt16? = nil,
        modifierFlags: UInt? = nil,
        keyTrigger: String? = nil,
        semitone: UInt8? = nil,
        octave: Int? = nil,
        chordTypeID: String? = nil,
        midiCommand: MIDICommandType? = nil,
        ccConfig: DrumPadCCConfig? = nil,
        channelOverride: Int? = nil,
        destinationOverrideUID: String? = nil,
        destinationOverrideName: String? = nil,
        colorAccent: PadColorAccent? = nil
    ) {
        self.id = id
        self.bank = bank
        self.padIndex = padIndex
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.keyTrigger = keyTrigger
        self.semitone = semitone
        self.octave = octave
        self.chordTypeID = chordTypeID
        self.midiCommand = midiCommand
        self.ccConfig = ccConfig
        self.channelOverride = channelOverride
        self.destinationOverrideUID = destinationOverrideUID
        self.destinationOverrideName = destinationOverrideName
        self.colorAccent = colorAccent
    }

    public var isAssigned: Bool {
        return (semitone != nil && octave != nil) || midiCommand != nil || ccConfig != nil
    }

    public var midiNote: UInt8? {
        guard let s = semitone, let o = octave else { return nil }
        let calculated = (o + 1) * 12 + Int(s)
        return UInt8(clamping: max(0, min(127, calculated)))
    }

    public var noteName: String? {
        guard let s = semitone, Int(s) < DrumPadConfig.noteNames.count else { return nil }
        return DrumPadConfig.noteNames[Int(s)]
    }

    public var fullNoteLabel: String? {
        guard let nn = noteName, let o = octave else { return nil }
        return "\(nn)\(o)"
    }

    public var chordType: ChordType? {
        guard let id = chordTypeID, id != "none", !id.isEmpty else { return nil }
        let chord = ChordType.find(by: id)
        return chord.id == "none" ? nil : chord
    }

    /// Computes all MIDI notes to send (root + chord intervals)
    public var notesToSend: [UInt8] {
        guard let root = midiNote else { return [] }
        if let chord = chordType {
            return chord.intervals.compactMap { interval in
                let note = Int(root) + interval
                return (0...127).contains(note) ? UInt8(note) : nil
            }
        } else {
            return [root]
        }
    }

    public func matches(event: NSEvent) -> Bool {
        if let code = self.keyCode {
            let activeMods = event.modifierFlags.intersection([.shift, .control, .option, .command]).rawValue
            let expectedMods = self.modifierFlags ?? 0
            return event.keyCode == code && activeMods == expectedMods
        }
        if let trig = self.keyTrigger, !trig.isEmpty {
            return matchesLegacy(keyChar: trig, event: event)
        }
        return false
    }

    private func matchesLegacy(keyChar: String, event: NSEvent) -> Bool {
        let norm = keyChar.trimmingCharacters(in: .whitespaces).lowercased()
        switch norm {
        case "space", " ": return event.keyCode == 49
        case "tab": return event.keyCode == 48
        case "return", "enter": return event.keyCode == 36
        default:
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                return chars == norm
            }
            return false
        }
    }
}
