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

public struct KeyBindingProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var isReadOnly: Bool
    public var oneOctaveNoteMap: [String: Int]
    public var twoOctaveNoteMap: [String: Int]
    public var ccBindings: [CCKeyBinding]
    public var mouseVerticalVelocityEnabled: Bool

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
        mouseVerticalVelocityEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.isReadOnly = isReadOnly
        self.oneOctaveNoteMap = oneOctaveNoteMap
        self.twoOctaveNoteMap = twoOctaveNoteMap
        self.ccBindings = ccBindings
        self.mouseVerticalVelocityEnabled = mouseVerticalVelocityEnabled
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
            mouseVerticalVelocityEnabled: true
        )
    }()
}
