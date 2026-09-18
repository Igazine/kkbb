import Foundation

public struct KKBBLayoutBundle: Codable {
    public var version: Int
    public var name: String?
    public var createdAt: Date?
    public var mode: KeyboardMode?
    public var drumPads: [String: DrumPadConfig]?
    public var computerKeyboardKeys: [String: DrumPadConfig]?
    public var computerKeyboardType: ComputerKeyboardType?
    public var computerKeyboardLayer: ComputerKeyboardLayer?

    public init(
        version: Int = 1,
        name: String? = nil,
        createdAt: Date? = Date(),
        mode: KeyboardMode? = nil,
        drumPads: [String: DrumPadConfig]? = nil,
        computerKeyboardKeys: [String: DrumPadConfig]? = nil,
        computerKeyboardType: ComputerKeyboardType? = nil,
        computerKeyboardLayer: ComputerKeyboardLayer? = nil
    ) {
        self.version = version
        self.name = name
        self.createdAt = createdAt
        self.mode = mode
        self.drumPads = drumPads
        self.computerKeyboardKeys = computerKeyboardKeys
        self.computerKeyboardType = computerKeyboardType
        self.computerKeyboardLayer = computerKeyboardLayer
    }

    public static func decode(from data: Data) throws -> KKBBLayoutBundle {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(KKBBLayoutBundle.self, from: data)
    }

    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
