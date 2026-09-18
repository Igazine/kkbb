import Foundation
import Observation
import AppKit

@Observable
public final class MIDIMonitorService {
    public static let shared = MIDIMonitorService()

    public private(set) var entries: [MIDILogEntry] = []
    public private(set) var lastEntry: MIDILogEntry? = nil

    // Real-time LED activity states
    public private(set) var isNoteOnActive: Bool = false
    public private(set) var isNoteOffActive: Bool = false
    public private(set) var isCCActive: Bool = false
    public private(set) var isPitchSysActive: Bool = false

    private var noteOnGeneration: Int = 0
    private var noteOffGeneration: Int = 0
    private var ccGeneration: Int = 0
    private var pitchSysGeneration: Int = 0

    private let maxEntries: Int = 60
    private let pulseDuration: TimeInterval = 0.13

    public init() {}

    public func log(
        type: MIDILogEventType,
        channel: Int?,
        detail: String,
        hexBytes: String,
        destination: String
    ) {
        let entry = MIDILogEntry(
            type: type,
            channel: channel,
            detail: detail,
            hexBytes: hexBytes,
            destination: destination
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.entries.insert(entry, at: 0)
            if self.entries.count > self.maxEntries {
                self.entries.removeLast(self.entries.count - self.maxEntries)
            }
            self.lastEntry = entry

            // Trigger activity LED
            switch type {
            case .noteOn:
                self.flashNoteOn()
            case .noteOff:
                self.flashNoteOff()
            case .controlChange:
                self.flashCC()
            case .pitchBend, .realTime, .mmc, .allNotesOff:
                self.flashPitchSys()
            }
        }
    }

    public func clear() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.entries.removeAll()
            self.lastEntry = nil
        }
    }

    // MARK: - LED Flash Timers

    private func flashNoteOn() {
        isNoteOnActive = true
        noteOnGeneration += 1
        let currentGen = noteOnGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration) { [weak self] in
            guard let self = self, self.noteOnGeneration == currentGen else { return }
            self.isNoteOnActive = false
        }
    }

    private func flashNoteOff() {
        isNoteOffActive = true
        noteOffGeneration += 1
        let currentGen = noteOffGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration) { [weak self] in
            guard let self = self, self.noteOffGeneration == currentGen else { return }
            self.isNoteOffActive = false
        }
    }

    private func flashCC() {
        isCCActive = true
        ccGeneration += 1
        let currentGen = ccGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration) { [weak self] in
            guard let self = self, self.ccGeneration == currentGen else { return }
            self.isCCActive = false
        }
    }

    private func flashPitchSys() {
        isPitchSysActive = true
        pitchSysGeneration += 1
        let currentGen = pitchSysGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration) { [weak self] in
            guard let self = self, self.pitchSysGeneration == currentGen else { return }
            self.isPitchSysActive = false
        }
    }
}
