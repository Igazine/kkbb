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

    // State for custom CC sheet
    @State private var configuringCCPadIndex: Int? = nil
    @State private var showCCConfigSheet: Bool = false
    @State private var customCCController: String = "64"
    @State private var customCCValue: String = "127"
    @State private var customCCOffValue: String = "0"
    @State private var customCCMode: CCBindingMode = .momentary
    @State private var customCCLabel: String = ""

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
        .sheet(isPresented: $showCCConfigSheet) {
            customCCSheet
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
                // Top Header: Pad Number & Hot-Key & Overrides
                HStack(alignment: .center, spacing: 3) {
                    Text("\(padIndex + 1)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isActive ? Color.white.opacity(0.9) : Color.secondary.opacity(0.6))

                    if let ch = config?.channelOverride {
                        Text("CH\(ch)")
                            .font(.system(size: 7.5, weight: .black, design: .monospaced))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 2.5)
                                    .fill(isActive ? Color.white.opacity(0.3) : Color.purple.opacity(0.25))
                            )
                            .foregroundStyle(isActive ? Color.white : Color.purple)
                    }

                    if let dest = config?.destinationOverrideUID {
                        Text(dest == "virtual" ? "VIRT" : "EXT")
                            .font(.system(size: 7.0, weight: .black, design: .monospaced))
                            .padding(.horizontal, 2.5)
                            .padding(.vertical, 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 2.5)
                                    .fill(isActive ? Color.white.opacity(0.3) : Color.teal.opacity(0.25))
                            )
                            .foregroundStyle(isActive ? Color.white : Color.teal)
                    }

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

                // Center: CC Button, MIDI Command, Note & Octave, or Unassigned marker
                if let cc = config?.ccConfig {
                    Text(cc.displayLabel)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(isActive ? Color.white : Color.primary)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                } else if let cmd = config?.midiCommand {
                    Text(cmd.padBadge)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(isActive ? Color.white : Color.primary)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                } else if let label = config?.fullNoteLabel {
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

                // Bottom: CC badge, Command category badge, or Chord badge if assigned
                if let cc = config?.ccConfig {
                    Text(cc.displayBadge)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isActive ? Color.white.opacity(0.25) : Color.secondary.opacity(0.12))
                        )
                        .foregroundStyle(isActive ? Color.white.opacity(0.9) : Color.secondary.opacity(0.7))
                        .lineLimit(1)
                        .padding(.bottom, 3)
                } else if let cmd = config?.midiCommand {
                    Text(cmd.category == .realTime ? "REALTIME" : (cmd.category == .mmc ? "MMC" : "SYS"))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isActive ? Color.white.opacity(0.25) : Color.secondary.opacity(0.12))
                        )
                        .foregroundStyle(isActive ? Color.white.opacity(0.9) : Color.secondary.opacity(0.7))
                        .lineLimit(1)
                        .padding(.bottom, 3)
                } else if let chord = config?.chordType {
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
                let isCurrent = config?.semitone == UInt8(semitone) && config?.midiCommand == nil && config?.ccConfig == nil
                Button {
                    var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                    current.midiCommand = nil
                    current.ccConfig = nil
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
                let isCurrent = config?.octave == oct && config?.midiCommand == nil && config?.ccConfig == nil
                Button {
                    var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                    current.midiCommand = nil
                    current.ccConfig = nil
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
                if (activeChordID == "none" || activeChordID.isEmpty) && config?.midiCommand == nil && config?.ccConfig == nil {
                    Label("No Chord (Single Note)", systemImage: "checkmark")
                } else {
                    Text("No Chord (Single Note)")
                }
            }

            Menu("Chords") {
                ForEach(ChordType.allTypes.filter { $0.category == .chords && $0.id != "none" }) { chord in
                    let isSel = activeChordID == chord.id && config?.midiCommand == nil && config?.ccConfig == nil
                    Button {
                        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                        current.midiCommand = nil
                        current.ccConfig = nil
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
                    let isSel = activeChordID == scale.id && config?.midiCommand == nil && config?.ccConfig == nil
                    Button {
                        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                        current.midiCommand = nil
                        current.ccConfig = nil
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

        Divider()

        // MIDI Command Submenu
        Menu("MIDI Command") {
            let activeCmd = config?.midiCommand

            Button {
                if var current = config {
                    current.midiCommand = nil
                    appState.updateDrumPadConfig(current)
                }
            } label: {
                if activeCmd == nil {
                    Label("None (Note / CC Mode)", systemImage: "checkmark")
                } else {
                    Text("None (Note / CC Mode)")
                }
            }

            Divider()

            ForEach(MIDICommandCategory.allCases) { cat in
                Menu(cat.rawValue) {
                    ForEach(MIDICommandType.allCases.filter { $0.category == cat }) { cmd in
                        let isSel = activeCmd == cmd
                        Button {
                            var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                            current.midiCommand = cmd
                            current.ccConfig = nil
                            current.semitone = nil
                            current.octave = nil
                            current.chordTypeID = nil
                            appState.updateDrumPadConfig(current)
                        } label: {
                            if isSel {
                                Label(cmd.displayName, systemImage: "checkmark")
                            } else {
                                Text(cmd.displayName)
                            }
                        }
                    }
                }
            }
        }

        Divider()

        // MIDI Control Change (CC) Submenu
        Menu("MIDI Control Change (CC)") {
            let activeCC = config?.ccConfig

            Button {
                if var current = config {
                    current.ccConfig = nil
                    appState.updateDrumPadConfig(current)
                }
            } label: {
                if activeCC == nil {
                    Label("None (Note / Command Mode)", systemImage: "checkmark")
                } else {
                    Text("None (Note / Command Mode)")
                }
            }

            Divider()

            Menu("Presets") {
                Button("Sustain Pedal (CC 64 · Momentary)") {
                    assignCCPreset(.sustainMomentary, padIndex: padIndex, config: config)
                }
                Button("Sustain Toggle (CC 64 · Toggle)") {
                    assignCCPreset(.sustainToggle, padIndex: padIndex, config: config)
                }
                Button("Mod Wheel Max (CC 1 · Momentary)") {
                    assignCCPreset(.modMax, padIndex: padIndex, config: config)
                }
                Button("Expression Max (CC 11 · Momentary)") {
                    assignCCPreset(.expressionMax, padIndex: padIndex, config: config)
                }
                Button("Volume Max (CC 7 · Trigger)") {
                    assignCCPreset(.volumeFull, padIndex: padIndex, config: config)
                }
                Button("Volume Mute (CC 7 · Trigger)") {
                    assignCCPreset(.volumeMute, padIndex: padIndex, config: config)
                }
                Button("All Sound Off (CC 120 · Trigger)") {
                    assignCCPreset(.allSoundOff, padIndex: padIndex, config: config)
                }
                Button("Panic CC (CC 123 · Trigger)") {
                    assignCCPreset(.allNotesOff, padIndex: padIndex, config: config)
                }
            }

            Button("Configure Custom CC…") {
                configuringCCPadIndex = padIndex
                if let cc = config?.ccConfig {
                    customCCController = "\(cc.controller)"
                    customCCValue = "\(cc.value)"
                    customCCOffValue = "\(cc.offValue)"
                    customCCMode = cc.mode
                    customCCLabel = cc.customLabel ?? ""
                } else {
                    customCCController = "64"
                    customCCValue = "127"
                    customCCOffValue = "0"
                    customCCMode = .momentary
                    customCCLabel = ""
                }
                showCCConfigSheet = true
            }
        }

        Divider()

        // MIDI Channel Override Submenu
        Menu("MIDI Channel") {
            let activeCh = config?.channelOverride

            Button {
                var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                current.channelOverride = nil
                appState.updateDrumPadConfig(current)
            } label: {
                if activeCh == nil {
                    Label("Global (Follow Top Bar)", systemImage: "checkmark")
                } else {
                    Text("Global (Follow Top Bar)")
                }
            }

            Divider()

            ForEach(1...16, id: \.self) { ch in
                Button {
                    var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                    current.channelOverride = ch
                    appState.updateDrumPadConfig(current)
                } label: {
                    if activeCh == ch {
                        Label("Channel \(ch)", systemImage: "checkmark")
                    } else {
                        Text("Channel \(ch)")
                    }
                }
            }
        }

        // MIDI Output Override Submenu
        Menu("MIDI Output") {
            let activeDest = config?.destinationOverrideUID

            Button {
                var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                current.destinationOverrideUID = nil
                current.destinationOverrideName = nil
                appState.updateDrumPadConfig(current)
            } label: {
                if activeDest == nil {
                    Label("Global (Follow Top Bar)", systemImage: "checkmark")
                } else {
                    Text("Global (Follow Top Bar)")
                }
            }

            Divider()

            Button {
                var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                current.destinationOverrideUID = "virtual"
                current.destinationOverrideName = "KKBB Virtual Only"
                appState.updateDrumPadConfig(current)
            } label: {
                if activeDest == "virtual" {
                    Label("KKBB Virtual Only", systemImage: "checkmark")
                } else {
                    Text("KKBB Virtual Only")
                }
            }

            if !appState.availableDestinations.isEmpty {
                Divider()

                ForEach(appState.availableDestinations) { dest in
                    let isSel = activeDest == "\(dest.id)"
                    Button {
                        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
                        current.destinationOverrideUID = "\(dest.id)"
                        current.destinationOverrideName = dest.name
                        appState.updateDrumPadConfig(current)
                    } label: {
                        if isSel {
                            Label(dest.name, systemImage: "checkmark")
                        } else {
                            Text(dest.name)
                        }
                    }
                }
            }

            if let savedUID = activeDest,
               savedUID != "virtual",
               !appState.availableDestinations.contains(where: { "\($0.id)" == savedUID }) {
                Divider()
                let offlineName = config?.destinationOverrideName ?? "Saved Device"
                Button {
                    // Keep existing selection
                } label: {
                    Label("\(offlineName) (Offline)", systemImage: "checkmark")
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

    private func assignCCPreset(_ preset: DrumPadCCConfig, padIndex: Int, config: DrumPadConfig?) {
        let bank = appState.octave
        var current = config ?? DrumPadConfig(bank: bank, padIndex: padIndex)
        current.ccConfig = preset
        current.semitone = nil
        current.octave = nil
        current.chordTypeID = nil
        current.midiCommand = nil
        appState.updateDrumPadConfig(current)
    }

    // MARK: - Custom CC Sheet
    private var customCCSheet: some View {
        let padNum = (configuringCCPadIndex ?? 0) + 1
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Configure MIDI CC for Pad \(padNum)")
                    .font(.headline)
                Text("Bank \(appState.octave)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Form {
                TextField("Custom Label (optional):", text: $customCCLabel, prompt: Text("e.g. SUSTAIN, MUTE, FILTER"))
                TextField("Controller (0–127):", text: $customCCController)
                TextField("Trigger / On Value (0–127):", text: $customCCValue)

                if customCCMode != .trigger {
                    TextField("Off Value (0–127):", text: $customCCOffValue)
                }

                Picker("Mode:", selection: $customCCMode) {
                    Text("Momentary (Press/Release)").tag(CCBindingMode.momentary)
                    Text("Toggle (Alternate On/Off)").tag(CCBindingMode.toggle)
                    Text("Trigger (One-shot)").tag(CCBindingMode.trigger)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Cancel") {
                    showCCConfigSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    if let pIdx = configuringCCPadIndex {
                        let ctrl = UInt8(clamping: max(0, min(127, Int(customCCController) ?? 64)))
                        let val = UInt8(clamping: max(0, min(127, Int(customCCValue) ?? 127)))
                        let offVal = UInt8(clamping: max(0, min(127, Int(customCCOffValue) ?? 0)))
                        let label = customCCLabel.trimmingCharacters(in: .whitespaces).isEmpty ? nil : customCCLabel

                        let cc = DrumPadCCConfig(controller: ctrl, value: val, offValue: offVal, mode: customCCMode, customLabel: label)
                        assignCCPreset(cc, padIndex: pIdx, config: appState.drumPadConfig(bank: appState.octave, padIndex: pIdx))
                    }
                    showCCConfigSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
