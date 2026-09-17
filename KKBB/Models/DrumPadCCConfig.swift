import Foundation

public struct DrumPadCCConfig: Codable, Hashable {
    public var controller: UInt8 // 0...127
    public var value: UInt8 // 0...127
    public var offValue: UInt8 // 0...127, default 0
    public var mode: CCBindingMode
    public var customLabel: String?

    public init(
        controller: UInt8,
        value: UInt8 = 127,
        offValue: UInt8 = 0,
        mode: CCBindingMode = .momentary,
        customLabel: String? = nil
    ) {
        self.controller = controller
        self.value = value
        self.offValue = offValue
        self.mode = mode
        self.customLabel = customLabel
    }

    public var displayBadge: String {
        switch mode {
        case .momentary: return "CC·MOM"
        case .toggle: return "CC·TOG"
        case .trigger: return "CC·TRG"
        }
    }

    public var displayLabel: String {
        if let custom = customLabel, !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom.uppercased()
        }
        return "CC \(controller)"
    }
}

extension DrumPadCCConfig {
    public static let sustainMomentary = DrumPadCCConfig(controller: 64, value: 127, offValue: 0, mode: .momentary, customLabel: "Sustain")
    public static let sustainToggle = DrumPadCCConfig(controller: 64, value: 127, offValue: 0, mode: .toggle, customLabel: "Sustain")
    public static let modMax = DrumPadCCConfig(controller: 1, value: 127, offValue: 0, mode: .momentary, customLabel: "Mod Full")
    public static let expressionMax = DrumPadCCConfig(controller: 11, value: 127, offValue: 0, mode: .momentary, customLabel: "Expr Full")
    public static let volumeFull = DrumPadCCConfig(controller: 7, value: 127, offValue: 0, mode: .trigger, customLabel: "Vol Max")
    public static let volumeMute = DrumPadCCConfig(controller: 7, value: 0, offValue: 0, mode: .trigger, customLabel: "Mute")
    public static let allSoundOff = DrumPadCCConfig(controller: 120, value: 0, offValue: 0, mode: .trigger, customLabel: "Sound Off")
    public static let allNotesOff = DrumPadCCConfig(controller: 123, value: 0, offValue: 0, mode: .trigger, customLabel: "Panic CC")
}
