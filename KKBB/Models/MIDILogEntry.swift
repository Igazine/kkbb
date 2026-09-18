import Foundation
import SwiftUI

public enum MIDILogEventType: String, Codable, Sendable {
    case noteOn = "NOTE ON"
    case noteOff = "NOTE OFF"
    case controlChange = "CC"
    case pitchBend = "PITCH"
    case allNotesOff = "PANIC"
    case realTime = "REALTIME"
    case mmc = "MMC"

    public var badgeColor: Color {
        switch self {
        case .noteOn:
            return Color(red: 0.20, green: 0.83, blue: 0.60) // #34D399 Emerald
        case .noteOff:
            return Color(red: 0.60, green: 0.65, blue: 0.72) // #94A3B8 Slate
        case .controlChange:
            return Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B Amber
        case .pitchBend:
            return Color(red: 0.22, green: 0.74, blue: 0.97) // #38BDF8 Sky/Cyan
        case .allNotesOff:
            return Color(red: 0.94, green: 0.27, blue: 0.27) // #EF4444 Coral Red
        case .realTime, .mmc:
            return Color(red: 0.75, green: 0.52, blue: 0.99) // #C084FC Purple
        }
    }
}

public struct MIDILogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let type: MIDILogEventType
    public let channel: Int?
    public let detail: String
    public let hexBytes: String
    public let destination: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: MIDILogEventType,
        channel: Int?,
        detail: String,
        hexBytes: String,
        destination: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.channel = channel
        self.detail = detail
        self.hexBytes = hexBytes
        self.destination = destination
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public var formattedTime: String {
        Self.timeFormatter.string(from: timestamp)
    }

    public var channelString: String {
        if let channel {
            return String(format: "CH %02d", channel)
        }
        return "SYS"
    }
}
