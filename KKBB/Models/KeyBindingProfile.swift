import Foundation

public enum CCBindingMode: String, Codable, CaseIterable, Identifiable {
    case momentary = "Momentary (Value on press, 0 on release)"
    case trigger = "Trigger (Value on press)"
    case toggle = "Toggle (Alternate 0 / Value)"

    public var id: String { rawValue }
}

public struct CCKeyBinding: Identifiable, Codable, Hashable {
    public var id: UUID
    public var keyChar: String // Lowercase character or special key identifier (e.g. " ", "pageup")
    public var label: String
    public var controller: UInt8 // 0...127
    public var value: UInt8 // 0...127
    public var mode: CCBindingMode

    public init(
        id: UUID = UUID(),
        keyChar: String,
        label: String = "",
        controller: UInt8,
        value: UInt8,
        mode: CCBindingMode = .momentary
    ) {
        self.id = id
        self.keyChar = keyChar.lowercased()
        self.label = label
        self.controller = controller
        self.value = value
        self.mode = mode
    }
}

public struct KnobConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var label: String
    public var controller: UInt8 // 0...127
    public var value: UInt8 // 0...127
    public var defaultValue: UInt8 // 0...127

    public init(
        id: UUID = UUID(),
        label: String,
        controller: UInt8,
        value: UInt8 = 0,
        defaultValue: UInt8 = 0
    ) {
        self.id = id
        self.label = label
        self.controller = controller
        self.value = value
        self.defaultValue = defaultValue
    }

    public static let defaultKnobs: [KnobConfig] = [
        KnobConfig(label: "MOD", controller: 1, value: 0, defaultValue: 0),
        KnobConfig(label: "BREATH", controller: 2, value: 0, defaultValue: 0),
        KnobConfig(label: "VOL", controller: 7, value: 100, defaultValue: 100),
        KnobConfig(label: "PAN", controller: 10, value: 64, defaultValue: 64),
        KnobConfig(label: "EXPR", controller: 11, value: 127, defaultValue: 127),
        KnobConfig(label: "CUTOFF", controller: 74, value: 64, defaultValue: 64),
        KnobConfig(label: "RESO", controller: 71, value: 64, defaultValue: 64),
        KnobConfig(label: "REVERB", controller: 91, value: 0, defaultValue: 0)
    ]
}

import AppKit

public struct ChordPadConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var keyTrigger: String // Display representation, e.g. "F1", "⇧1", "⌥A"
    public var chordTypeID: String // references ChordType.id
    public var keyCode: UInt16?
    public var modifierFlags: UInt?

    public init(
        id: UUID = UUID(),
        keyTrigger: String,
        chordTypeID: String,
        keyCode: UInt16? = nil,
        modifierFlags: UInt? = nil
    ) {
        self.id = id
        self.keyTrigger = keyTrigger
        self.chordTypeID = chordTypeID
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    public static let defaultPads: [ChordPadConfig] = [
        ChordPadConfig(keyTrigger: "F1", chordTypeID: "none", keyCode: 122, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F2", chordTypeID: "major_triad", keyCode: 120, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F3", chordTypeID: "minor_triad", keyCode: 99, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F4", chordTypeID: "dom7", keyCode: 118, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F5", chordTypeID: "maj7", keyCode: 96, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F6", chordTypeID: "min7", keyCode: 97, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F7", chordTypeID: "half_dim", keyCode: 98, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F8", chordTypeID: "sus4", keyCode: 100, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F9", chordTypeID: "major_pentatonic", keyCode: 101, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F10", chordTypeID: "minor_pentatonic", keyCode: 109, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F11", chordTypeID: "blues_minor", keyCode: 103, modifierFlags: 0),
        ChordPadConfig(keyTrigger: "F12", chordTypeID: "dorian", keyCode: 111, modifierFlags: 0)
    ]

    public static func parseEvent(_ event: NSEvent) -> (display: String, keyCode: UInt16, modifierFlags: UInt)? {
        let rawFlags = event.modifierFlags.intersection([.shift, .control, .option, .command])
        var prefix = ""
        if rawFlags.contains(.control) { prefix += "⌃" }
        if rawFlags.contains(.option) { prefix += "⌥" }
        if rawFlags.contains(.shift) { prefix += "⇧" }
        if rawFlags.contains(.command) { prefix += "⌘" }

        let keyName: String
        switch event.keyCode {
        case 122: keyName = "F1"
        case 120: keyName = "F2"
        case 99: keyName = "F3"
        case 118: keyName = "F4"
        case 96: keyName = "F5"
        case 97: keyName = "F6"
        case 98: keyName = "F7"
        case 100: keyName = "F8"
        case 101: keyName = "F9"
        case 109: keyName = "F10"
        case 103: keyName = "F11"
        case 111: keyName = "F12"
        case 105: keyName = "F13"
        case 107: keyName = "F14"
        case 113: keyName = "F15"
        case 106: keyName = "F16"
        case 49: keyName = "Space"
        case 36: keyName = "Return"
        case 48: keyName = "Tab"
        case 53: keyName = "Esc"
        case 51: keyName = "Delete"
        case 117: keyName = "ForwardDelete"
        case 123: keyName = "←"
        case 124: keyName = "→"
        case 125: keyName = "↓"
        case 126: keyName = "↑"
        case 18: keyName = "1"
        case 19: keyName = "2"
        case 20: keyName = "3"
        case 21: keyName = "4"
        case 23: keyName = "5"
        case 22: keyName = "6"
        case 26: keyName = "7"
        case 28: keyName = "8"
        case 25: keyName = "9"
        case 29: keyName = "0"
        case 27: keyName = "-"
        case 24: keyName = "="
        case 42: keyName = "\\"
        case 33: keyName = "["
        case 30: keyName = "]"
        case 41: keyName = ";"
        case 39: keyName = "'"
        case 43: keyName = ","
        case 47: keyName = "."
        case 44: keyName = "/"
        case 50: keyName = "`"
        default:
            if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
                keyName = chars
            } else {
                keyName = "Key\(event.keyCode)"
            }
        }

        let display = prefix + keyName
        return (display, event.keyCode, rawFlags.rawValue)
    }

    public func matches(event: NSEvent) -> Bool {
        if let code = self.keyCode {
            let activeMods = event.modifierFlags.intersection([.shift, .control, .option, .command]).rawValue
            let expectedMods = self.modifierFlags ?? 0
            return event.keyCode == code && activeMods == expectedMods
        }
        return matchesLegacy(keyChar: self.keyTrigger, event: event)
    }

    private func matchesLegacy(keyChar: String, event: NSEvent) -> Bool {
        let norm = keyChar.trimmingCharacters(in: .whitespaces).lowercased()
        switch norm {
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

public struct KeyBindingProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var isReadOnly: Bool
    public var oneOctaveNoteMap: [String: Int]
    public var twoOctaveNoteMap: [String: Int]
    public var ccBindings: [CCKeyBinding]
    public var mouseVerticalVelocityEnabled: Bool
    public var knobs: [KnobConfig]
    public var chordPads: [ChordPadConfig]

    public var isDefault: Bool {
        return isReadOnly
    }

    public init(
        id: UUID = UUID(),
        name: String,
        isReadOnly: Bool = false,
        oneOctaveNoteMap: [String: Int],
        twoOctaveNoteMap: [String: Int],
        ccBindings: [CCKeyBinding] = [],
        mouseVerticalVelocityEnabled: Bool = true,
        knobs: [KnobConfig] = KnobConfig.defaultKnobs,
        chordPads: [ChordPadConfig] = ChordPadConfig.defaultPads
    ) {
        self.id = id
        self.name = name
        self.isReadOnly = isReadOnly
        self.oneOctaveNoteMap = oneOctaveNoteMap
        self.twoOctaveNoteMap = twoOctaveNoteMap
        self.ccBindings = ccBindings
        self.mouseVerticalVelocityEnabled = mouseVerticalVelocityEnabled
        self.knobs = knobs
        self.chordPads = chordPads
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isReadOnly, oneOctaveNoteMap, twoOctaveNoteMap, ccBindings, mouseVerticalVelocityEnabled, knobs, chordPads
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.isReadOnly = try container.decodeIfPresent(Bool.self, forKey: .isReadOnly) ?? false
        self.oneOctaveNoteMap = try container.decode([String: Int].self, forKey: .oneOctaveNoteMap)
        self.twoOctaveNoteMap = try container.decode([String: Int].self, forKey: .twoOctaveNoteMap)
        self.ccBindings = try container.decodeIfPresent([CCKeyBinding].self, forKey: .ccBindings) ?? []
        self.mouseVerticalVelocityEnabled = try container.decodeIfPresent(Bool.self, forKey: .mouseVerticalVelocityEnabled) ?? true
        self.knobs = try container.decodeIfPresent([KnobConfig].self, forKey: .knobs) ?? KnobConfig.defaultKnobs
        self.chordPads = try container.decodeIfPresent([ChordPadConfig].self, forKey: .chordPads) ?? ChordPadConfig.defaultPads
    }

    public static let defaultProfile: KeyBindingProfile = {
        let oneOctave: [String: Int] = [
            "a": 0, "w": 1, "s": 2, "e": 3, "d": 4, "f": 5,
            "t": 6, "g": 7, "y": 8, "h": 9, "u": 10, "j": 11,
            "k": 12, "o": 13, "l": 14, "p": 15
        ]

        let twoOctave: [String: Int] = [
            "z": 0, "s": 1, "x": 2, "d": 3, "c": 4, "v": 5,
            "g": 6, "b": 7, "h": 8, "n": 9, "j": 10, "m": 11,
            ",": 12, "q": 12, "2": 13, "w": 14, "3": 15, "e": 16,
            "r": 17, "5": 18, "t": 19, "6": 20, "y": 21, "7": 22,
            "u": 23, "i": 24, "9": 25, "o": 26, "0": 27, "p": 28
        ]

        let defaultCCs: [CCKeyBinding] = [
            CCKeyBinding(
                keyChar: " ",
                label: "Sustain Pedal",
                controller: 64,
                value: 127,
                mode: .momentary
            )
        ]

        return KeyBindingProfile(
            name: "Default",
            isReadOnly: true,
            oneOctaveNoteMap: oneOctave,
            twoOctaveNoteMap: twoOctave,
            ccBindings: defaultCCs,
            mouseVerticalVelocityEnabled: true,
            knobs: KnobConfig.defaultKnobs,
            chordPads: ChordPadConfig.defaultPads
        )
    }()
}
