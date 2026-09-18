import Foundation

public struct PadGridLayout: Codable {
    public var version: Int
    public var name: String?
    public var createdAt: Date?
    public var drumPads: [String: DrumPadConfig]

    public init(
        version: Int = 1,
        name: String? = nil,
        createdAt: Date? = Date(),
        drumPads: [String: DrumPadConfig]
    ) {
        self.version = version
        self.name = name
        self.createdAt = createdAt
        self.drumPads = drumPads
    }

    public static func decode(from data: Data) throws -> PadGridLayout {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let layout = try? decoder.decode(PadGridLayout.self, from: data) {
            return layout
        }

        // Fallback: direct [String: DrumPadConfig] dictionary
        let pads = try decoder.decode([String: DrumPadConfig].self, from: data)
        return PadGridLayout(version: 1, name: nil, createdAt: nil, drumPads: pads)
    }

    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
