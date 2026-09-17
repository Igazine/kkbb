import Foundation

public struct PianoKey: Identifiable, Hashable {
    public let midiNote: UInt8
    public let name: String
    public let isBlack: Bool
    public let octave: Int
    public let keyBinding: String?

    public var id: UInt8 { midiNote }

    public init(midiNote: UInt8, name: String, isBlack: Bool, octave: Int, keyBinding: String? = nil) {
        self.midiNote = midiNote
        self.name = name
        self.isBlack = isBlack
        self.octave = octave
        self.keyBinding = keyBinding
    }
}
