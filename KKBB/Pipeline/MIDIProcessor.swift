import Foundation

/// Abstract MIDI Processor protocol for intermediate note manipulation
/// (e.g. arpeggiator, chord generator, scale quantizer, echo/delay, etc.).
public protocol MIDIProcessor: AnyObject, MIDIEventReceiver {
    var id: String { get }
    var name: String { get }
    var isEnabled: Bool { get set }
    var nextReceiver: MIDIEventReceiver? { get set }

    /// Intercepts and transforms or generates MIDI events before sending downstream.
    func process(event: MIDIEvent, destinationUID: Int32?)
}

public extension MIDIProcessor {
    /// Forwards an event to the next stage in the pipeline.
    func forward(event: MIDIEvent, destinationUID: Int32?) {
        nextReceiver?.receive(event: event, destinationUID: destinationUID)
    }

    /// Default MIDIEventReceiver implementation: passes through when disabled, or calls process().
    func receive(event: MIDIEvent, destinationUID: Int32?) {
        if isEnabled {
            process(event: event, destinationUID: destinationUID)
        } else {
            forward(event: event, destinationUID: destinationUID)
        }
    }
}

/// A default passthrough processor representing an inactive / bypassed stage.
public final class PassthroughProcessor: MIDIProcessor {
    public let id: String
    public let name: String
    public var isEnabled: Bool = true
    public weak var nextReceiver: MIDIEventReceiver?

    public init(id: String = "passthrough", name: String = "Passthrough") {
        self.id = id
        self.name = name
    }

    public func process(event: MIDIEvent, destinationUID: Int32?) {
        // Abstract layer hook: passes events downstream without modification.
        forward(event: event, destinationUID: destinationUID)
    }
}
