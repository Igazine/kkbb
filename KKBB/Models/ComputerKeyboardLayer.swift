import Foundation

public enum ComputerKeyboardLayer: String, CaseIterable, Identifiable, Codable {
    case base = "Base"
    case shift = "Shift (⇧)"
    case option = "Option (⌥)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .base: return "Base"
        case .shift: return "⇧ Shift"
        case .option: return "⌥ Option"
        }
    }

    public static func storageKey(for keyCode: UInt16, layer: ComputerKeyboardLayer) -> String {
        switch layer {
        case .base:
            return "key_\(keyCode)"
        case .shift:
            return "shift_key_\(keyCode)"
        case .option:
            return "option_key_\(keyCode)"
        }
    }
}
