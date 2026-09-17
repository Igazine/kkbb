import Foundation

/// Represents an abstract MIDI event flowing through the processing pipeline.
public enum MIDIEvent: Hashable, Sendable {
    case noteOn(note: UInt8, velocity: UInt8, channel: Int)
    case noteOff(note: UInt8, velocity: UInt8, channel: Int)
    case allNotesOff(channel: Int)
    case controlChange(controller: UInt8, value: UInt8, channel: Int)
}

/// A receiver that accepts processed MIDI events to pass down the chain or send to hardware.
public protocol MIDIEventReceiver: AnyObject {
    func receive(event: MIDIEvent, destinationUID: Int32?)
}
