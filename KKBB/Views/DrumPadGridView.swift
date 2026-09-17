import SwiftUI
import AppKit

public struct DrumPadGridView: View {
    @Bindable var appState: AppState

    @State private var recordingPadIndex: Int? = nil
    @State private var showKeyRecorder: Bool = false

    // State for interactive key recorder sheet
    @State private var isListening: Bool = true
    @State private var recordedDisplay: String = ""
    @State private var recordedKeyCode: UInt16? = nil
    @State private var recordedModifiers: UInt? = nil

    public init(appState: AppState) {
        self.appState = appState
    }

    // MPC style layout (bottom to top: Pad 1-4 at bottom, Pad 13-16 at top)
    private let padRows: [[Int]] = [
        [12, 13, 14, 15],
        [8, 9, 10, 11],
        [4, 5, 6, 7],
        [0, 1, 2, 3]
    ]

    public var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<padRows.count, id: \.self) { rowIdx in
                HStack(spacing: 5) {
                    ForEach(padRows[rowIdx], id: \.self) { padIndex in
                        drumPadCell(padIndex: padIndex)
                    }
                }
            }
        }
        .padding(6)
        .background(Color.black.opacity(0.12))
        .clipped()
        .sheet(isPresented: $showKeyRecorder) {
            keyRecorderSheet
        }
    }

    // MARK: - Pad Cell
    @ViewBuilder
    private func drumPadCell(padIndex: Int) -> some View {
        let bank = appState.octave
        let config = appState.drumPadConfig(bank: bank, padIndex: padIndex)
        let isActive = appState.isDrumPadActive(bank: bank, padIndex: padIndex)
        let isAssigned = config?.isAssigned == true

        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    isActive
                        ? Color.accentColor
                        : (isAssigned ? Color(nsColor: .controlBackgroundColor).opacity(0.85) : Color(nsColor: .controlBackgroundColor).opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(
                            isActive
                                ? Color.white.opacity(0.6)
                                : (isAssigned ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.15)),
                            lineWidth: isActive ? 1.5 : 1.0
                        )
                )

            VStack(spacing: 1) {
                // Top Header: Pad Number & Hot-Key
                HStack(alignment: .center) {
                    Text("\(padIndex + 1)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isActive ? Color.white.opacity(0.9) : Color.secondary.opacity(0.6))

                    Spacer()

                    if let keyTrigger = config?.keyTrigger, !keyTrigger.isEmpty {
                        Text(keyTrigger.uppercased())
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isActive ? Color.white.opacity(0.25) : Color.accentColor.opacity(0.2))
                            )
                            .foregroundStyle(isActive ? Color.white : Color.accentColor)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 4)

                Spacer(minLength: 1)

                // Center: Note & Octave or Unassigned marker
                if let label = config?.fullNoteLabel {
                    Text(label)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(isActive ? Color.white : Color.primary)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                } else {
                    Text("—")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                }

                Spacer(minLength: 1)

                // Bottom: Chord badge if assigned
                if let chord = config?.chordType {
                    Text(chord.shortName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isActive ? Color.white.opacity(0.2) : Color.secondary.opacity(0.15))
                        )
                        .foregroundStyle(isActive ? Color.white : Color.secondary)
                        .lineLimit(1)
                        .padding(.bottom, 3)
                } else {
                    Spacer(minLength: 0)
                        .frame(height: 4)
                }
            }
        }
        .frame(minWidth: 40, minHeight: 38, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Only trigger if left mouse button is pressed
                    guard (NSEvent.pressedMouseButtons & 1) != 0 else { return }
                    if !appState.isDrumPadActive(bank: bank, padIndex: padIndex) {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                        appState.triggerDrumPadOn(bank: bank, padIndex: padIndex)
                    }
                }
                .onEnded { _ in
                    appState.triggerDrumPadOff(bank: bank, padIndex: padIndex)
                }
        )
        .contextMenu {
            padContextMenu(padIndex: padIndex, config: config)
        }
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func padContextMenu(padIndex: Int, config: DrumPadConfig?) -> some View {
        let bank = appState.octave

        Button("Clear Pad Assignment") {
            appState.clearDrumPad(bank: bank, padIndex: padIndex)
        }

        Divider()

        Button("Assign Hot-Key…") {
            recordingPadIndex = padIndex
            recordedDisplay = config?.keyTrigger ?? ""
            recordedKeyCode = config?.keyCode
            recordedModifiers = config?.modifierFlags
            isListening = true
            showKeyRecorder = true
        }

        if config?.keyTrigger != nil {
            Button("Clear Hot-Key") {
                if var existing = config {
                    existing.keyCode = nil
                    existing.modifierFlags = nil
                    existing.keyTrigger = nil
                    appState.updateDrumPadConfig(existing)
                }
            }
        }

        Divider()

        // Note Submenu (C to B)
        Menu("Root Note") {
            ForEach(0..<DrumPadConfig.noteNames.count, id: \.self) { semitone in
                let noteName = DrumPadConfig.noteNames[semitone]
                let isCurrent = config?.semitone == UInt8(semitone)
                Button {
                    var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                    current.semitone = UInt8(semitone)
                    if current.octave == nil { current.octave = 3 }
                    appState.updateDrumPadConfig(current)
                } label: {
                    if isCurrent {
                        Label(noteName, systemImage: "checkmark")
                    } else {
                        Text(noteName)
                    }
                }
            }
        }

        // Octave Submenu (0 to 6)
        Menu("Octave") {
            ForEach(0...6, id: \.self) { oct in
                let isCurrent = config?.octave == oct
                Button {
                    var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                    current.octave = oct
                    if current.semitone == nil { current.semitone = 0 }
                    appState.updateDrumPadConfig(current)
                } label: {
                    if isCurrent {
                        Label("Octave \(oct)", systemImage: "checkmark")
                    } else {
                        Text("Octave \(oct)")
                    }
                }
            }
        }

        Divider()

        // Chord Voicing Submenu
        Menu("Chord Voicing") {
            let activeChordID = config?.chordTypeID ?? "none"

            Button {
                if var current = config {
                    current.chordTypeID = nil
                    appState.updateDrumPadConfig(current)
                }
            } label: {
                if activeChordID == "none" || activeChordID.isEmpty {
                    Label("No Chord (Single Note)", systemImage: "checkmark")
                } else {
                    Text("No Chord (Single Note)")
                }
            }

            Menu("Chords") {
                ForEach(ChordType.allTypes.filter { $0.category == .chords && $0.id != "none" }) { chord in
                    let isSel = activeChordID == chord.id
                    Button {
                        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                        if current.semitone == nil { current.semitone = 0 }
                        if current.octave == nil { current.octave = 3 }
                        current.chordTypeID = chord.id
                        appState.updateDrumPadConfig(current)
                    } label: {
                        if isSel {
                            Label(chord.name, systemImage: "checkmark")
                        } else {
                            Text(chord.name)
                        }
                    }
                }
            }

            Menu("Bitwig Scales & Modes") {
                ForEach(ChordType.allTypes.filter { $0.category == .scales }) { scale in
                    let isSel = activeChordID == scale.id
                    Button {
                        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                        if current.semitone == nil { current.semitone = 0 }
                        if current.octave == nil { current.octave = 3 }
                        current.chordTypeID = scale.id
                        appState.updateDrumPadConfig(current)
                    } label: {
                        if isSel {
                            Label(scale.name, systemImage: "checkmark")
                        } else {
                            Text(scale.name)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Key Recorder Sheet
    private var keyRecorderSheet: some View {
        let padNum = (recordingPadIndex ?? 0) + 1
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Assign Hot-Key for Pad \(padNum)")
                    .font(.headline)
                Text("Bank \(appState.octave)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                if isListening {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("Listening for keystroke…")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.accentColor)
                    }

                    Text("Press any key or combination on your keyboard\n(e.g. 1–9, Q–P, A–L, Z–M, Space, ⇧A, etc.)")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 6) {
                        Text(recordedDisplay.isEmpty ? "None (Unassigned)" : recordedDisplay)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                            )

                        Text("Key combination captured!")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            HStack(spacing: 12) {
                if !isListening {
                    Button("Re-record Key") {
                        startListening()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Clear Key") {
                    recordedDisplay = ""
                    recordedKeyCode = nil
                    recordedModifiers = nil
                    isListening = false
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)

                Spacer()

                Button("Cancel") {
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                    showKeyRecorder = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                    if let pIdx = recordingPadIndex {
                        let bank = appState.octave
                        var current = appState.drumPadConfig(bank: bank, padIndex: pIdx) ?? DrumPadConfig(bank: bank, padIndex: pIdx)
                        current.keyTrigger = recordedDisplay.isEmpty ? nil : recordedDisplay
                        current.keyCode = recordedKeyCode
                        current.modifierFlags = recordedModifiers
                        appState.updateDrumPadConfig(current)
                    }
                    showKeyRecorder = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            startListening()
        }
        .onDisappear {
            KeyboardMonitor.shared.keyCaptureHandler = nil
        }
    }

    private func startListening() {
        isListening = true
        KeyboardMonitor.shared.keyCaptureHandler = { event in
            guard let parsed = ChordPadConfig.parseEvent(event) else { return false }
            DispatchQueue.main.async {
                self.recordedDisplay = parsed.display
                self.recordedKeyCode = parsed.keyCode
                self.recordedModifiers = parsed.modifierFlags
                self.isListening = false
                KeyboardMonitor.shared.keyCaptureHandler = nil
            }
            return true
        }
    }
}
