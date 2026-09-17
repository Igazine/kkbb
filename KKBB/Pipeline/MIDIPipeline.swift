import Foundation

/// Central pipeline coordinating intermediate MIDI processors between note generation and output.
public final class MIDIPipeline: MIDIEventReceiver {
    public static let shared = MIDIPipeline()

    public private(set) var processors: [MIDIProcessor] = []
    public var outputSink: MIDIEventReceiver?

    public init(outputSink: MIDIEventReceiver? = MIDIManager.shared) {
        self.outputSink = outputSink
        setupChain()
    }

    public func addProcessor(_ processor: MIDIProcessor) {
        processors.append(processor)
        setupChain()
    }

    public func removeProcessor(_ processor: MIDIProcessor) {
        processors.removeAll { $0 === processor }
        setupChain()
    }

    public func clearProcessors() {
        processors.removeAll()
        setupChain()
    }

    public func setupChain() {
        guard !processors.isEmpty else { return }

        for i in 0..<(processors.count - 1) {
            processors[i].nextReceiver = processors[i + 1]
        }
        processors.last?.nextReceiver = outputSink
    }

    // MARK: - MIDIEventReceiver

    public func receive(event: MIDIEvent, destinationUID: Int32?) {
        if let first = processors.first(where: { $0.isEnabled }) {
            first.receive(event: event, destinationUID: destinationUID)
        } else {
            outputSink?.receive(event: event, destinationUID: destinationUID)
        }
    }

    // MARK: - Convenience Dispatchers

    public func sendNoteOn(note: UInt8, velocity: UInt8, channel: Int, destinationUID: Int32?) {
        receive(event: .noteOn(note: note, velocity: velocity, channel: channel), destinationUID: destinationUID)
    }

    public func sendNoteOff(note: UInt8, velocity: UInt8 = 0, channel: Int, destinationUID: Int32?) {
        receive(event: .noteOff(note: note, velocity: velocity, channel: channel), destinationUID: destinationUID)
    }

    public func allNotesOff(channel: Int, destinationUID: Int32?) {
        receive(event: .allNotesOff(channel: channel), destinationUID: destinationUID)
    }
}
