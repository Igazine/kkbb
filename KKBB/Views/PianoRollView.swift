import SwiftUI
import AppKit

struct KeyDescriptor: Identifiable {
    let id: UInt8 // MIDI note
    let noteNumber: UInt8
    let noteName: String
    let isBlack: Bool
    let shortcut: String?
    let whiteIndex: Int // Index among white keys (if white)
    let octaveOffset: Int
}

struct PianoRollView: View {
    @Bindable var appState: AppState
    @State private var mouseHeldNote: UInt8?

    // System highlight color, soft and non-fatiguing
    private var highlightColor: Color {
        Color(nsColor: .controlAccentColor).opacity(0.60)
    }

    private var whiteKeyFill: Color {
        Color(nsColor: .systemGray).opacity(0.30)
    }

    private var blackKeyFill: Color {
        Color(nsColor: .darkGray)
    }

    var body: some View {
        GeometryReader { geometry in
            let baseNote = UInt8((appState.octave + 1) * 12)
            let (whiteKeys, blackKeys) = generateKeys(baseNote: baseNote, mode: appState.mode)
            let whiteCount = Swift.max(1, whiteKeys.count)
            let keyWidth = geometry.size.width / CGFloat(whiteCount)
            let keyHeight = geometry.size.height
            let blackWidth = keyWidth * 0.62
            let blackHeight = keyHeight * 0.62
            let shortcutSize = Swift.max(8.0, Swift.min(16.0, keyWidth * 0.22))
            let noteLabelSize = Swift.max(7.0, Swift.min(12.0, keyWidth * 0.18))

            ZStack(alignment: .topLeading) {
                // Background
                Color(nsColor: .windowBackgroundColor)

                // White Keys
                HStack(spacing: 1) {
                    ForEach(whiteKeys) { key in
                        let isActive = appState.activeNotes.contains(key.noteNumber)
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(isActive ? highlightColor : whiteKeyFill)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.25), lineWidth: 0.5)
                                )

                            VStack(spacing: 2) {
                                if let shortcut = key.shortcut {
                                    Text(shortcut.uppercased())
                                        .font(.system(size: shortcutSize, weight: .bold, design: .monospaced))
                                        .foregroundStyle(isActive ? .primary : .secondary)
                                }
                                Text(key.noteName)
                                    .font(.system(size: noteLabelSize, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(width: Swift.max(0, keyWidth - 1), height: keyHeight)
                    }
                }

                // Black Keys Layer
                ForEach(blackKeys) { key in
                    let isActive = appState.activeNotes.contains(key.noteNumber)
                    let xOffset = calculateBlackKeyX(key: key, whiteWidth: keyWidth, blackWidth: blackWidth)

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isActive ? highlightColor : blackKeyFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 2)

                        if let shortcut = key.shortcut {
                            Text(shortcut.uppercased())
                                .font(.system(size: Swift.max(7.5, shortcutSize * 0.9), weight: .bold, design: .monospaced))
                                .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.9))
                                .padding(.bottom, 6)
                        }
                    }
                    .frame(width: blackWidth, height: blackHeight)
                    .offset(x: xOffset, y: 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(
                            at: value.location,
                            whiteKeys: whiteKeys,
                            blackKeys: blackKeys,
                            keyWidth: keyWidth,
                            keyHeight: keyHeight,
                            blackWidth: blackWidth,
                            blackHeight: blackHeight
                        )
                    }
                    .onEnded { _ in
                        if let held = mouseHeldNote {
                            triggerNoteOff(held)
                            mouseHeldNote = nil
                        }
                    }
            )
        }
    }

    private func handleDrag(
        at point: CGPoint,
        whiteKeys: [KeyDescriptor],
        blackKeys: [KeyDescriptor],
        keyWidth: CGFloat,
        keyHeight: CGFloat,
        blackWidth: CGFloat,
        blackHeight: CGFloat
    ) {
        let hitNote = resolveKeyAt(
            point: point,
            whiteKeys: whiteKeys,
            blackKeys: blackKeys,
            keyWidth: keyWidth,
            keyHeight: keyHeight,
            blackWidth: blackWidth,
            blackHeight: blackHeight
        )

        if hitNote != mouseHeldNote {
            if let old = mouseHeldNote {
                triggerNoteOff(old)
            }
            mouseHeldNote = hitNote
            if let note = hitNote {
                triggerNoteOn(note)
            }
        }
    }

    private func resolveKeyAt(
        point: CGPoint,
        whiteKeys: [KeyDescriptor],
        blackKeys: [KeyDescriptor],
        keyWidth: CGFloat,
        keyHeight: CGFloat,
        blackWidth: CGFloat,
        blackHeight: CGFloat
    ) -> UInt8? {
        guard point.y >= 0, point.y <= keyHeight else { return nil }

        // Check black keys first if within black key height
        if point.y <= blackHeight {
            for key in blackKeys {
                let xOffset = calculateBlackKeyX(key: key, whiteWidth: keyWidth, blackWidth: blackWidth)
                if point.x >= xOffset && point.x <= (xOffset + blackWidth) {
                    return key.noteNumber
                }
            }
        }

        // Check white keys
        let whiteIndex = Int(point.x / keyWidth)
        if whiteIndex >= 0 && whiteIndex < whiteKeys.count {
            return whiteKeys[whiteIndex].noteNumber
        }

        return nil
    }

    private func triggerNoteOn(_ note: UInt8) {
        guard !appState.activeNotes.contains(note) else { return }
        MIDIPipeline.shared.sendNoteOn(
            note: note,
            velocity: UInt8(appState.velocity),
            channel: appState.channel,
            destinationUID: appState.selectedDestinationUID
        )
        appState.activeNotes.insert(note)
    }

    private func triggerNoteOff(_ note: UInt8) {
        guard appState.activeNotes.contains(note) else { return }
        MIDIPipeline.shared.sendNoteOff(
            note: note,
            channel: appState.channel,
            destinationUID: appState.selectedDestinationUID
        )
        appState.activeNotes.remove(note)
    }

    private func calculateBlackKeyX(key: KeyDescriptor, whiteWidth: CGFloat, blackWidth: CGFloat) -> CGFloat {
        // Position black key centered at the boundary between white keys
        let boundaryIndex: CGFloat
        let whiteBase = CGFloat(key.octaveOffset * 7)

        switch key.whiteIndex {
        case 0: boundaryIndex = whiteBase + 1 // C# between C (0) and D (1)
        case 1: boundaryIndex = whiteBase + 2 // D# between D (1) and E (2)
        case 3: boundaryIndex = whiteBase + 4 // F# between F (3) and G (4)
        case 4: boundaryIndex = whiteBase + 5 // G# between G (4) and A (5)
        case 5: boundaryIndex = whiteBase + 6 // A# between A (5) and B (6)
        default: boundaryIndex = 0
        }

        return (boundaryIndex * whiteWidth) - (blackWidth / 2.0)
    }

    private func generateKeys(baseNote: UInt8, mode: KeyboardMode) -> (white: [KeyDescriptor], black: [KeyDescriptor]) {
        var whites: [KeyDescriptor] = []
        var blacks: [KeyDescriptor] = []

        let octaves = (mode == .oneOctave) ? 1 : 2
        let shortcuts = (mode == .oneOctave) ? oneOctaveShortcuts : twoOctaveShortcuts

        let noteNamesWhite = ["C", "D", "E", "F", "G", "A", "B"]
        let whiteOffsets = [0, 2, 4, 5, 7, 9, 11]

        let blackOffsets = [1, 3, 6, 8, 10]
        let blackNames = ["C#", "D#", "F#", "G#", "A#"]
        let blackWhiteNeighbors = [0, 1, 3, 4, 5] // Left white key index

        var globalWhiteIndex = 0

        for oct in 0..<octaves {
            let octBase = Int(baseNote) + (oct * 12)

            // Whites in this octave
            for (idx, offset) in whiteOffsets.enumerated() {
                let note = UInt8(clamped: octBase + offset)
                let name = "\(noteNamesWhite[idx])\(appState.octave + oct)"
                let shortcut = shortcuts[oct * 12 + offset]
                whites.append(
                    KeyDescriptor(
                        id: note,
                        noteNumber: note,
                        noteName: name,
                        isBlack: false,
                        shortcut: shortcut,
                        whiteIndex: globalWhiteIndex,
                        octaveOffset: oct
                    )
                )
                globalWhiteIndex += 1
            }

            // Blacks in this octave
            for (idx, offset) in blackOffsets.enumerated() {
                let note = UInt8(clamped: octBase + offset)
                let name = "\(blackNames[idx])\(appState.octave + oct)"
                let shortcut = shortcuts[oct * 12 + offset]
                blacks.append(
                    KeyDescriptor(
                        id: note,
                        noteNumber: note,
                        noteName: name,
                        isBlack: true,
                        shortcut: shortcut,
                        whiteIndex: blackWhiteNeighbors[idx],
                        octaveOffset: oct
                    )
                )
            }
        }

        // Add top C
        let topNote = UInt8(clamped: Int(baseNote) + (octaves * 12))
        let topName = "C\(appState.octave + octaves)"
        let topShortcut = shortcuts[octaves * 12]
        whites.append(
            KeyDescriptor(
                id: topNote,
                noteNumber: topNote,
                noteName: topName,
                isBlack: false,
                shortcut: topShortcut,
                whiteIndex: globalWhiteIndex,
                octaveOffset: octaves
            )
        )

        return (whites, blacks)
    }

    private let oneOctaveShortcuts: [Int: String] = [
        0: "a", 1: "w", 2: "s", 3: "e", 4: "d", 5: "f",
        6: "t", 7: "g", 8: "y", 9: "h", 10: "u", 11: "j", 12: "k"
    ]

    private let twoOctaveShortcuts: [Int: String] = [
        0: "z", 1: "s", 2: "x", 3: "d", 4: "c", 5: "v",
        6: "g", 7: "b", 8: "h", 9: "n", 10: "j", 11: "m",
        12: "q", 13: "2", 14: "w", 15: "3", 16: "e", 17: "r",
        18: "4", 19: "t", 20: "5", 21: "y", 22: "6", 23: "u", 24: "i"
    ]
}

private extension UInt8 {
    init(clamped value: Int) {
        self = UInt8(Swift.max(0, Swift.min(127, value)))
    }
}
