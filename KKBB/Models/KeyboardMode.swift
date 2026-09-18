import Foundation

public enum KeyboardMode: String, CaseIterable, Identifiable, Codable {
    case oneOctave = "1-Octave"
    case twoOctaves = "2-Octave"
    case drumGrid = "4x4 Grid"
    case computerKeyboard = "Computer Keyboard"

    public var id: String { rawValue }
}
