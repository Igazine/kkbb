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

public struct KeyBindingProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var isReadOnly: Bool
    public var oneOctaveNoteMap: [String: Int]
    public var twoOctaveNoteMap: [String: Int]
    public var ccBindings: [CCKeyBinding]
    public var mouseVerticalVelocityEnabled: Bool
    public var knobs: [KnobConfig]

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
        knobs: [KnobConfig] = KnobConfig.defaultKnobs
    ) {
        self.id = id
        self.name = name
        self.isReadOnly = isReadOnly
        self.oneOctaveNoteMap = oneOctaveNoteMap
        self.twoOctaveNoteMap = twoOctaveNoteMap
        self.ccBindings = ccBindings
        self.mouseVerticalVelocityEnabled = mouseVerticalVelocityEnabled
        self.knobs = knobs
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isReadOnly, oneOctaveNoteMap, twoOctaveNoteMap, ccBindings, mouseVerticalVelocityEnabled, knobs
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
            knobs: KnobConfig.defaultKnobs
        )
    }()
}
