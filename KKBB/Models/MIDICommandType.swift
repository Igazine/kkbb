import Foundation

public enum MIDICommandCategory: String, CaseIterable, Identifiable {
    case realTime = "Real-Time Transport"
    case mmc = "MMC Transport (SysEx)"
    case utility = "Utility"

    public var id: String { rawValue }
}

public enum MIDICommandType: String, CaseIterable, Codable, Identifiable, Hashable {
    // Real-Time Transport
    case rtStart = "rt_start"
    case rtStop = "rt_stop"
    case rtContinue = "rt_continue"

    // MIDI Machine Control (MMC)
    case mmcPlay = "mmc_play"
    case mmcStop = "mmc_stop"
    case mmcPause = "mmc_pause"
    case mmcRecord = "mmc_record"
    case mmcRewind = "mmc_rewind"
    case mmcFastForward = "mmc_fast_forward"

    // Utility
    case allNotesOff = "all_notes_off"

    public var id: String { rawValue }

    public var category: MIDICommandCategory {
        switch self {
        case .rtStart, .rtStop, .rtContinue:
            return .realTime
        case .mmcPlay, .mmcStop, .mmcPause, .mmcRecord, .mmcRewind, .mmcFastForward:
            return .mmc
        case .allNotesOff:
            return .utility
        }
    }

    public var displayName: String {
        switch self {
        case .rtStart: return "Start (0xFA)"
        case .rtStop: return "Stop (0xFC)"
        case .rtContinue: return "Continue / Unpause (0xFB)"
        case .mmcPlay: return "Play"
        case .mmcStop: return "Stop"
        case .mmcPause: return "Pause"
        case .mmcRecord: return "Record"
        case .mmcRewind: return "Rewind"
        case .mmcFastForward: return "Fast Forward"
        case .allNotesOff: return "All Notes Off (Panic)"
        }
    }

    /// Label displayed on the pad itself
    public var padBadge: String {
        switch self {
        case .rtStart: return "▶ START"
        case .rtStop: return "■ STOP"
        case .rtContinue: return "❚❚ CONT"
        case .mmcPlay: return "▶ PLAY"
        case .mmcStop: return "■ STOP"
        case .mmcPause: return "❚❚ PAUSE"
        case .mmcRecord: return "● REC"
        case .mmcRewind: return "◀◀ REW"
        case .mmcFastForward: return "▶▶ FF"
        case .allNotesOff: return "⚠ PANIC"
        }
    }

    /// Raw MIDI bytes to transmit (for Real-Time and SysEx)
    public var rawBytes: [UInt8] {
        switch self {
        case .rtStart:
            return [0xFA]
        case .rtStop:
            return [0xFC]
        case .rtContinue:
            return [0xFB]
        case .mmcPlay:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x02, 0xF7]
        case .mmcStop:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x01, 0xF7]
        case .mmcPause:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x09, 0xF7]
        case .mmcRecord:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x06, 0xF7]
        case .mmcRewind:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x05, 0xF7]
        case .mmcFastForward:
            return [0xF0, 0x7F, 0x7F, 0x06, 0x04, 0xF7]
        case .allNotesOff:
            return [] // Handled via allNotesOff() CC 123 & CC 120
        }
    }
}
