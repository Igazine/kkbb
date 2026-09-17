import Foundation

public enum ChordCategory: String, Codable, CaseIterable {
    case chords = "Chords"
    case scales = "Scales & Modes"
}

public struct ChordType: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let shortName: String
    public let intervals: [Int] // Semitone offsets from root (e.g. [0, 4, 7])
    public let category: ChordCategory

    public init(id: String, name: String, shortName: String, intervals: [Int], category: ChordCategory) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.intervals = intervals
        self.category = category
    }

    public static let none = ChordType(
        id: "none",
        name: "No Chord (Single Note)",
        shortName: "OFF",
        intervals: [0],
        category: .chords
    )

    public static let allTypes: [ChordType] = [
        // MARK: - Chords
        none,
        ChordType(id: "major_triad", name: "Major Triad", shortName: "Maj", intervals: [0, 4, 7], category: .chords),
        ChordType(id: "minor_triad", name: "Minor Triad", shortName: "Min", intervals: [0, 3, 7], category: .chords),
        ChordType(id: "dom7", name: "Dominant 7th", shortName: "Dom7", intervals: [0, 4, 7, 10], category: .chords),
        ChordType(id: "maj7", name: "Major 7th", shortName: "Maj7", intervals: [0, 4, 7, 11], category: .chords),
        ChordType(id: "min7", name: "Minor 7th", shortName: "Min7", intervals: [0, 3, 7, 10], category: .chords),
        ChordType(id: "min_maj7", name: "Minor Major 7th", shortName: "mMaj7", intervals: [0, 3, 7, 11], category: .chords),
        ChordType(id: "half_dim", name: "Half-Diminished (m7♭5)", shortName: "m7♭5", intervals: [0, 3, 6, 10], category: .chords),
        ChordType(id: "dim7", name: "Diminished 7th", shortName: "Dim7", intervals: [0, 3, 6, 9], category: .chords),
        ChordType(id: "dim_triad", name: "Diminished Triad", shortName: "Dim", intervals: [0, 3, 6], category: .chords),
        ChordType(id: "aug", name: "Augmented", shortName: "Aug", intervals: [0, 4, 8], category: .chords),
        ChordType(id: "sus4", name: "Suspended 4th", shortName: "Sus4", intervals: [0, 5, 7], category: .chords),
        ChordType(id: "sus2", name: "Suspended 2nd", shortName: "Sus2", intervals: [0, 2, 7], category: .chords),
        ChordType(id: "power", name: "Power Chord (5th)", shortName: "5th", intervals: [0, 7], category: .chords),
        ChordType(id: "octave", name: "Octave Double", shortName: "Oct", intervals: [0, 12], category: .chords),

        // MARK: - Scales & Modes (Bitwig Studio Spec)
        ChordType(id: "major_pentatonic", name: "Major Pentatonic", shortName: "MajPent", intervals: [0, 2, 4, 7, 9], category: .scales),
        ChordType(id: "minor_pentatonic", name: "Minor Pentatonic", shortName: "MinPent", intervals: [0, 3, 5, 7, 10], category: .scales),
        ChordType(id: "blues_major", name: "Blues Major", shortName: "BluesMaj", intervals: [0, 2, 3, 4, 7, 9], category: .scales),
        ChordType(id: "blues_minor", name: "Blues Minor", shortName: "BluesMin", intervals: [0, 3, 5, 6, 7, 10], category: .scales),
        ChordType(id: "major_scale", name: "Major (Ionian)", shortName: "Major", intervals: [0, 2, 4, 5, 7, 9, 11], category: .scales),
        ChordType(id: "minor_scale", name: "Minor (Aeolian)", shortName: "Minor", intervals: [0, 2, 3, 5, 7, 8, 10], category: .scales),
        ChordType(id: "dorian", name: "Dorian", shortName: "Dorian", intervals: [0, 2, 3, 5, 7, 9, 10], category: .scales),
        ChordType(id: "phrygian", name: "Phrygian", shortName: "Phryg", intervals: [0, 1, 3, 5, 7, 8, 10], category: .scales),
        ChordType(id: "lydian", name: "Lydian", shortName: "Lydian", intervals: [0, 2, 4, 6, 7, 9, 11], category: .scales),
        ChordType(id: "mixolydian", name: "Mixolydian", shortName: "Mixo", intervals: [0, 2, 4, 5, 7, 9, 10], category: .scales),
        ChordType(id: "locrian", name: "Locrian", shortName: "Locrian", intervals: [0, 1, 3, 5, 6, 8, 10], category: .scales),
        ChordType(id: "harmonic_major", name: "Harmonic Major", shortName: "HarmMaj", intervals: [0, 2, 4, 5, 7, 8, 11], category: .scales),
        ChordType(id: "harmonic_minor", name: "Harmonic Minor", shortName: "HarmMin", intervals: [0, 2, 3, 5, 7, 8, 11], category: .scales),
        ChordType(id: "jazz_minor", name: "Jazz Minor (Melodic)", shortName: "JazzMin", intervals: [0, 2, 3, 5, 7, 9, 11], category: .scales),
        ChordType(id: "overtone", name: "Overtone (Lydian Dom.)", shortName: "Overtone", intervals: [0, 2, 4, 6, 7, 9, 10], category: .scales),
        ChordType(id: "double_harm_maj", name: "Double Harmonic Major", shortName: "DbHarmMaj", intervals: [0, 1, 4, 5, 7, 8, 11], category: .scales),
        ChordType(id: "double_harm_min", name: "Double Harmonic Minor", shortName: "DbHarmMin", intervals: [0, 2, 3, 6, 7, 8, 11], category: .scales),
        ChordType(id: "whole_tone", name: "Whole Tone", shortName: "WholeTone", intervals: [0, 2, 4, 6, 8, 10], category: .scales),
        ChordType(id: "dim_wh", name: "Diminished (Whole-Half)", shortName: "DimWH", intervals: [0, 2, 3, 5, 6, 8, 9, 11], category: .scales),
        ChordType(id: "dim_hw", name: "Diminished (Half-Whole)", shortName: "DimHW", intervals: [0, 1, 3, 4, 6, 7, 9, 10], category: .scales)
    ]

    public static func find(by id: String) -> ChordType {
        allTypes.first(where: { $0.id == id }) ?? .none
    }
}
