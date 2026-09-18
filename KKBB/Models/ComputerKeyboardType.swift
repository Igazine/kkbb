import Foundation

public enum ComputerKeyboardType: String, CaseIterable, Identifiable, Codable {
    case macbook = "MacBook (75%)"
    case extended101 = "Full 101-Key"

    public var id: String { rawValue }
}
