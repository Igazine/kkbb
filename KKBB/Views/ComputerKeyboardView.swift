import SwiftUI
import AppKit

struct ComputerKeyInfo: Identifiable {
    let id: String
    let keyCode: UInt16?
    let label: String
    let secondaryLabel: String?
    let widthUnits: CGFloat
    let isConfigurable: Bool
    var gapAfter: CGFloat = 0.0
    var isNumpadEnter: Bool = false
    var isSpacer: Bool = false
    var isSplitArrows: Bool = false
}

struct ComputerKeyboardView: View {
    @Bindable var appState: AppState

    @State private var configuringKey: UInt16?
    @State private var configuringKeyLabel: String = ""
    @State private var customCCController: String = "64"
    @State private var customCCValue: String = "127"
    @State private var customCCOffValue: String = "0"
    @State private var customCCMode: CCBindingMode = .momentary
    @State private var customCCLabel: String = ""
    @State private var showCCSheet: Bool = false
    @State private var showClearConfirm: Bool = false

    private let keyCornerRadius: CGFloat = 4.0

    var body: some View {
        VStack(spacing: 4) {
            // Scalable Keyboard Surface
            GeometryReader { geometry in
                let isExtended = appState.computerKeyboardType == .extended101

                // Unit System:
                // MacBook: exactly 14.50 units across all rows 0..5
                // Extended: 14.50 (main) + 0.50 (gap) + 3.00 (nav) + 0.50 (gap) + 4.00 (numpad) = 22.50 units across all rows 0..5
                let totalKeyUnits: CGFloat = isExtended ? 22.50 : 14.50
                let keySpacing: CGFloat = isExtended ? 2.0 : 3.0

                let horizontalMargin: CGFloat = 8.0
                let availableWidth = max(100.0, geometry.size.width - (horizontalMargin * 2))

                // Unit width that exactly fits available width:
                // Total row width with n items = totalUnits * unitWidth - spacing <= availableWidth
                let maxUnitWidth = (availableWidth + keySpacing) / totalKeyUnits

                let availableHeight = max(80.0, geometry.size.height - 8.0)
                let rowSpacing: CGFloat = keySpacing
                let totalRowGaps = 5.0 * rowSpacing
                let maxUnitHeight = max(16.0, (availableHeight - totalRowGaps) / 6.0)

                // Maintain proportional key shape (near-square key caps):
                let targetUnitWidth = min(maxUnitWidth, (maxUnitHeight + rowSpacing) / 0.88)
                let unitWidth = max(10.0, targetUnitWidth)
                let unitHeight = min(maxUnitHeight, min(50.0, unitWidth * 0.90))

                VStack(spacing: rowSpacing) {
                    ForEach(0..<6, id: \.self) { rowIndex in
                        renderRow(
                            rowIndex: rowIndex,
                            unitWidth: unitWidth,
                            unitHeight: unitHeight,
                            keySpacing: keySpacing,
                            isExtended: isExtended
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, horizontalMargin)
                .padding(.top, 6)
                .padding(.bottom, 2)
            }

            // Centered helper strip below the keyboard
            HStack(spacing: 12) {
                Spacer()

                Text("Right-click key to configure note, chord, command, or CC · Click to trigger")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)

                Text("·")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary.opacity(0.5))

                Button("Clear All Keys") {
                    showClearConfirm = true
                }
                .buttonStyle(.borderless)
                .font(.system(size: 10.5))
                .foregroundStyle(.red.opacity(0.85))

                Spacer()
            }
            .frame(height: 16)
            .padding(.bottom, 6)
        }
        .confirmationDialog(
            "Clear Computer Keyboard?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All Key Assignments", role: .destructive) {
                appState.clearAllComputerKeys()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all custom note, chord, command, and CC triggers assigned to the computer keyboard.")
        }
        .sheet(isPresented: $showCCSheet) {
            customCCSheet
        }
    }

    // MARK: - Mathematical Item Width
    private func itemWidth(units: CGFloat, unitWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        max(0.0, units * unitWidth - spacing)
    }

    // MARK: - Row Rendering
    @ViewBuilder
    private func renderRow(
        rowIndex: Int,
        unitWidth: CGFloat,
        unitHeight: CGFloat,
        keySpacing: CGFloat,
        isExtended: Bool
    ) -> some View {
        HStack(spacing: keySpacing) {
            // Main Block
            let mainKeys = getMainBlockKeys(for: rowIndex)
            ForEach(mainKeys) { key in
                if key.isSplitArrows {
                    renderSplitArrows(
                        key: key,
                        unitWidth: unitWidth,
                        unitHeight: unitHeight,
                        keySpacing: keySpacing
                    )
                } else if key.isSpacer {
                    Color.clear.frame(
                        width: itemWidth(units: key.widthUnits, unitWidth: unitWidth, spacing: keySpacing),
                        height: unitHeight
                    )
                } else {
                    renderKeyCap(
                        key: key,
                        unitWidth: unitWidth,
                        unitHeight: unitHeight,
                        keySpacing: keySpacing
                    )
                }
                if key.gapAfter > 0 {
                    Color.clear.frame(
                        width: itemWidth(units: key.gapAfter, unitWidth: unitWidth, spacing: keySpacing),
                        height: 1
                    )
                }
            }

            // Extended Block (Nav + Numpad)
            if isExtended {
                // Inter-block gap: Main to Nav (0.50 units)
                Color.clear.frame(
                    width: itemWidth(units: 0.50, unitWidth: unitWidth, spacing: keySpacing),
                    height: 1
                )

                // Navigation Block
                let navKeys = getNavBlockKeys(for: rowIndex)
                ForEach(navKeys) { key in
                    if key.isSpacer {
                        Color.clear.frame(
                            width: itemWidth(units: key.widthUnits, unitWidth: unitWidth, spacing: keySpacing),
                            height: unitHeight
                        )
                    } else {
                        renderKeyCap(
                            key: key,
                            unitWidth: unitWidth,
                            unitHeight: unitHeight,
                            keySpacing: keySpacing
                        )
                    }
                    if key.gapAfter > 0 {
                        Color.clear.frame(
                            width: itemWidth(units: key.gapAfter, unitWidth: unitWidth, spacing: keySpacing),
                            height: 1
                        )
                    }
                }

                // Inter-block gap: Nav to Numpad (0.50 units)
                Color.clear.frame(
                    width: itemWidth(units: 0.50, unitWidth: unitWidth, spacing: keySpacing),
                    height: 1
                )

                // Numpad Block
                let numKeys = getNumpadBlockKeys(for: rowIndex)
                ForEach(numKeys) { key in
                    if key.isSpacer {
                        Color.clear.frame(
                            width: itemWidth(units: key.widthUnits, unitWidth: unitWidth, spacing: keySpacing),
                            height: unitHeight
                        )
                    } else {
                        renderKeyCap(
                            key: key,
                            unitWidth: unitWidth,
                            unitHeight: unitHeight,
                            keySpacing: keySpacing
                        )
                    }
                    if key.gapAfter > 0 {
                        Color.clear.frame(
                            width: itemWidth(units: key.gapAfter, unitWidth: unitWidth, spacing: keySpacing),
                            height: 1
                        )
                    }
                }
            }
        }
    }

    // MARK: - Key Cap Rendering
    @ViewBuilder
    private func renderKeyCap(
        key: ComputerKeyInfo,
        unitWidth: CGFloat,
        unitHeight: CGFloat,
        keySpacing: CGFloat
    ) -> some View {
        let width = itemWidth(units: key.widthUnits, unitWidth: unitWidth, spacing: keySpacing)
        let visualHeight = key.isNumpadEnter ? (unitHeight * 2 + keySpacing) : unitHeight

        if key.isNumpadEnter {
            // Anchor to Row 3 without expanding Row 3's HStack height
            Color.clear
                .frame(width: width, height: unitHeight)
                .overlay(alignment: .top) {
                    keyCapContent(key: key, width: width, height: visualHeight, unitWidth: unitWidth)
                }
                .zIndex(10)
        } else {
            keyCapContent(key: key, width: width, height: visualHeight, unitWidth: unitWidth)
        }
    }

    @ViewBuilder
    private func keyCapContent(
        key: ComputerKeyInfo,
        width: CGFloat,
        height: CGFloat,
        unitWidth: CGFloat
    ) -> some View {
        let keyCode = key.keyCode
        let config = keyCode.flatMap { appState.computerKeyConfig(keyCode: $0) }
        let isConfigured = config?.isAssigned ?? false
        let isActive = keyCode.map { appState.isComputerKeyActive(keyCode: $0) } ?? false

        ZStack {
            // Key Cap Background
            RoundedRectangle(cornerRadius: keyCornerRadius)
                .fill(keyBackground(isConfigurable: key.isConfigurable, isConfigured: isConfigured, isActive: isActive))
                .overlay(
                    RoundedRectangle(cornerRadius: keyCornerRadius)
                        .stroke(keyBorder(isConfigurable: key.isConfigurable, isConfigured: isConfigured, isActive: isActive), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(isActive ? 0.35 : 0.15), radius: 1, x: 0, y: 1)

            // Content
            VStack(spacing: 1) {
                if let sec = key.secondaryLabel {
                    Text(sec)
                        .font(.system(size: Swift.max(6.0, Swift.min(10.0, unitWidth * 0.22)), weight: .regular))
                        .foregroundStyle(Color.secondary.opacity(key.isConfigurable ? 0.8 : 0.4))
                }

                Text(key.label)
                    .font(.system(size: Swift.max(7.0, Swift.min(13.0, unitWidth * 0.30)), weight: key.isConfigurable ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(keyTextColor(isConfigurable: key.isConfigurable, isActive: isActive))
                    .lineLimit(1)

                // Assignment Badges
                if let cfg = config, cfg.isAssigned {
                    if let cmd = cfg.midiCommand {
                        Text(cmd.padBadge)
                            .font(.system(size: Swift.max(5.5, Swift.min(9.0, unitWidth * 0.20)), weight: .bold))
                            .foregroundStyle(isActive ? .white : Color.accentColor)
                            .lineLimit(1)
                    } else if let cc = cfg.ccConfig {
                        Text(cc.displayBadge)
                            .font(.system(size: Swift.max(5.5, Swift.min(9.0, unitWidth * 0.20)), weight: .bold))
                            .foregroundStyle(isActive ? .white : Color.orange)
                            .lineLimit(1)
                    } else if let note = cfg.fullNoteLabel {
                        HStack(spacing: 1) {
                            Text(note)
                                .font(.system(size: Swift.max(6.0, Swift.min(9.5, unitWidth * 0.22)), weight: .bold, design: .monospaced))
                                .foregroundStyle(isActive ? .white : Color.cyan)
                            if let chord = cfg.chordType {
                                Text(chord.shortName)
                                    .font(.system(size: Swift.max(5.0, Swift.min(8.0, unitWidth * 0.18)), weight: .medium))
                                    .foregroundStyle(isActive ? .white.opacity(0.9) : .secondary)
                            }
                        }
                        .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            if let code = key.keyCode, key.isConfigurable {
                NSApp.keyWindow?.makeFirstResponder(nil)
                appState.triggerComputerKeyOn(keyCode: code)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    appState.triggerComputerKeyOff(keyCode: code)
                }
            }
        }
        .contextMenu {
            if key.isConfigurable, let code = key.keyCode {
                keyContextMenu(keyCode: code, label: key.label)
            }
        }
    }

    // MARK: - Split Up/Down Arrows Rendering (MacBook style)
    @ViewBuilder
    private func renderSplitArrows(
        key: ComputerKeyInfo,
        unitWidth: CGFloat,
        unitHeight: CGFloat,
        keySpacing: CGFloat
    ) -> some View {
        let width = itemWidth(units: key.widthUnits, unitWidth: unitWidth, spacing: keySpacing)
        let halfHeight = max(8.0, (unitHeight - keySpacing) / 2)

        VStack(spacing: keySpacing) {
            singleMiniButton(
                keyCode: 126,
                label: "▲",
                width: width,
                height: halfHeight,
                unitWidth: unitWidth
            )
            singleMiniButton(
                keyCode: 125,
                label: "▼",
                width: width,
                height: halfHeight,
                unitWidth: unitWidth
            )
        }
        .frame(width: width, height: unitHeight)
    }

    @ViewBuilder
    private func singleMiniButton(
        keyCode: UInt16,
        label: String,
        width: CGFloat,
        height: CGFloat,
        unitWidth: CGFloat
    ) -> some View {
        let config = appState.computerKeyConfig(keyCode: keyCode)
        let isConfigured = config?.isAssigned ?? false
        let isActive = appState.isComputerKeyActive(keyCode: keyCode)

        ZStack {
            RoundedRectangle(cornerRadius: keyCornerRadius)
                .fill(keyBackground(isConfigurable: true, isConfigured: isConfigured, isActive: isActive))
                .overlay(
                    RoundedRectangle(cornerRadius: keyCornerRadius)
                        .stroke(keyBorder(isConfigurable: true, isConfigured: isConfigured, isActive: isActive), lineWidth: 0.5)
                )

            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: Swift.max(6.5, Swift.min(10.0, unitWidth * 0.24)), weight: .semibold))
                    .foregroundStyle(keyTextColor(isConfigurable: true, isActive: isActive))

                if let cfg = config, cfg.isAssigned {
                    if let note = cfg.fullNoteLabel {
                        Text(note)
                            .font(.system(size: Swift.max(5.5, Swift.min(8.0, unitWidth * 0.18)), weight: .bold, design: .monospaced))
                            .foregroundStyle(isActive ? .white : Color.cyan)
                    } else if let cmd = cfg.midiCommand {
                        Text(cmd.padBadge)
                            .font(.system(size: Swift.max(5.0, Swift.min(7.5, unitWidth * 0.16)), weight: .bold))
                            .foregroundStyle(isActive ? .white : Color.accentColor)
                    } else if let cc = cfg.ccConfig {
                        Text(cc.displayBadge)
                            .font(.system(size: Swift.max(5.0, Swift.min(7.5, unitWidth * 0.16)), weight: .bold))
                            .foregroundStyle(isActive ? .white : Color.orange)
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            NSApp.keyWindow?.makeFirstResponder(nil)
            appState.triggerComputerKeyOn(keyCode: keyCode)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                appState.triggerComputerKeyOff(keyCode: keyCode)
            }
        }
        .contextMenu {
            keyContextMenu(keyCode: keyCode, label: label)
        }
    }

    private func keyBackground(isConfigurable: Bool, isConfigured: Bool, isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(0.85)
        }
        if !isConfigurable {
            return Color(nsColor: .controlBackgroundColor).opacity(0.18)
        }
        if isConfigured {
            return Color(nsColor: .controlBackgroundColor).opacity(0.70)
        }
        return Color(nsColor: .controlBackgroundColor).opacity(0.40)
    }

    private func keyBorder(isConfigurable: Bool, isConfigured: Bool, isActive: Bool) -> Color {
        if isActive {
            return Color.white.opacity(0.8)
        }
        if isConfigured {
            return Color.accentColor.opacity(0.65)
        }
        if isConfigurable {
            return Color.black.opacity(0.35)
        }
        return Color.black.opacity(0.15)
    }

    private func keyTextColor(isConfigurable: Bool, isActive: Bool) -> Color {
        if isActive {
            return .white
        }
        if isConfigurable {
            return .primary
        }
        return .secondary.opacity(0.45)
    }

    private struct MenuCheckButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                if isSelected {
                    Label(title, systemImage: "checkmark")
                } else {
                    Text(title)
                }
            }
        }
    }

    private func isNoteSelected(config: DrumPadConfig?, semi: Int, oct: Int) -> Bool {
        guard let config = config, config.midiCommand == nil, config.ccConfig == nil else { return false }
        return config.semitone == UInt8(semi) && config.octave == oct
    }

    private func assignNote(semi: Int, octave: Int, keyCode: UInt16, label: String, current: DrumPadConfig?) {
        var cfg = current ?? DrumPadConfig(bank: 0, padIndex: Int(keyCode), keyCode: keyCode, keyTrigger: label)
        cfg.keyCode = keyCode
        cfg.keyTrigger = label
        cfg.semitone = UInt8(semi)
        cfg.octave = octave
        cfg.midiCommand = nil
        cfg.ccConfig = nil
        appState.updateComputerKeyConfig(cfg)
    }

    private func assignChord(chordID: String, keyCode: UInt16, label: String, current: DrumPadConfig?) {
        var cfg = current ?? DrumPadConfig(bank: 0, padIndex: Int(keyCode), keyCode: keyCode, keyTrigger: label, semitone: 0, octave: 3)
        cfg.chordTypeID = chordID
        appState.updateComputerKeyConfig(cfg)
    }

    private func assignMIDICommand(_ cmd: MIDICommandType, keyCode: UInt16, label: String, current: DrumPadConfig?) {
        var cfg = current ?? DrumPadConfig(bank: 0, padIndex: Int(keyCode), keyCode: keyCode, keyTrigger: label)
        cfg.midiCommand = cmd
        cfg.ccConfig = nil
        cfg.semitone = nil
        cfg.octave = nil
        appState.updateComputerKeyConfig(cfg)
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func keyContextMenu(keyCode: UInt16, label: String) -> some View {
        let currentConfig = appState.computerKeyConfig(keyCode: keyCode)

        // 1. Root Note & Octave
        Menu("Root Note & Octave") {
            ForEach(0..<7) { oct in
                Menu("Octave \(oct)") {
                    ForEach(0..<12) { semi in
                        let name = DrumPadConfig.noteNames[semi]
                        let isSelected = isNoteSelected(config: currentConfig, semi: semi, oct: oct)
                        MenuCheckButton(title: "\(name)\(oct)", isSelected: isSelected) {
                            assignNote(semi: semi, octave: oct, keyCode: keyCode, label: label, current: currentConfig)
                        }
                    }
                }
            }
        }

        // 2. Chord Voicings
        Menu("Chord Voicing") {
            MenuCheckButton(title: "No Chord (Single Note)", isSelected: currentConfig?.chordTypeID == nil || currentConfig?.chordTypeID == "none") {
                assignChord(chordID: "none", keyCode: keyCode, label: label, current: currentConfig)
            }

            Divider()

            Menu("Standard Chords") {
                ForEach(ChordType.allTypes.filter { $0.category == .chords && $0.id != "none" }) { chord in
                    MenuCheckButton(title: chord.name, isSelected: currentConfig?.chordTypeID == chord.id) {
                        assignChord(chordID: chord.id, keyCode: keyCode, label: label, current: currentConfig)
                    }
                }
            }

            Menu("Bitwig Scales & Modes") {
                ForEach(ChordType.allTypes.filter { $0.category == .scales }) { scale in
                    MenuCheckButton(title: scale.name, isSelected: currentConfig?.chordTypeID == scale.id) {
                        assignChord(chordID: scale.id, keyCode: keyCode, label: label, current: currentConfig)
                    }
                }
            }
        }

        Divider()

        // 3. MIDI Command (Transport & Utilities)
        Menu("MIDI Command") {
            Menu("Real-Time Transport") {
                ForEach(MIDICommandType.allCases.filter { $0.category == .realTime }) { cmd in
                    MenuCheckButton(title: cmd.displayName, isSelected: currentConfig?.midiCommand == cmd) {
                        assignMIDICommand(cmd, keyCode: keyCode, label: label, current: currentConfig)
                    }
                }
            }

            Menu("MMC Transport (SysEx)") {
                ForEach(MIDICommandType.allCases.filter { $0.category == .mmc }) { cmd in
                    MenuCheckButton(title: cmd.displayName, isSelected: currentConfig?.midiCommand == cmd) {
                        assignMIDICommand(cmd, keyCode: keyCode, label: label, current: currentConfig)
                    }
                }
            }

            Divider()

            MenuCheckButton(title: "All Notes Off (Panic)", isSelected: currentConfig?.midiCommand == .allNotesOff) {
                assignMIDICommand(.allNotesOff, keyCode: keyCode, label: label, current: currentConfig)
            }
        }

        // 4. MIDI Control Change (CC)
        Menu("MIDI Control Change (CC)") {
            Menu("CC Presets") {
                Button("Sustain Pedal (CC 64 · Momentary)") {
                    assignCCPreset(.sustainMomentary, keyCode: keyCode, label: label, current: currentConfig)
                }
                Button("Sustain Toggle (CC 64 · Toggle)") {
                    assignCCPreset(.sustainToggle, keyCode: keyCode, label: label, current: currentConfig)
                }
                Divider()
                Button("Mod Wheel Max (CC 1 · Momentary)") {
                    assignCCPreset(.modMax, keyCode: keyCode, label: label, current: currentConfig)
                }
                Button("Expression Max (CC 11 · Momentary)") {
                    assignCCPreset(.expressionMax, keyCode: keyCode, label: label, current: currentConfig)
                }
                Button("Volume Max (CC 7 · Trigger)") {
                    assignCCPreset(.volumeFull, keyCode: keyCode, label: label, current: currentConfig)
                }
                Button("Volume Mute (CC 7 · Trigger)") {
                    assignCCPreset(.volumeMute, keyCode: keyCode, label: label, current: currentConfig)
                }
            }

            Divider()

            Button("Configure Custom CC…") {
                configuringKey = keyCode
                configuringKeyLabel = label
                if let cc = currentConfig?.ccConfig {
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
                showCCSheet = true
            }
        }

        Divider()

        // 5. Clear
        Button("Clear Assignment", role: .destructive) {
            appState.clearComputerKey(keyCode: keyCode)
        }
        .disabled(currentConfig?.isAssigned != true)
    }

    private func assignCCPreset(_ preset: DrumPadCCConfig, keyCode: UInt16, label: String, current: DrumPadConfig?) {
        var cfg = current ?? DrumPadConfig(bank: 0, padIndex: Int(keyCode), keyCode: keyCode, keyTrigger: label)
        cfg.ccConfig = preset
        cfg.midiCommand = nil
        cfg.semitone = nil
        cfg.octave = nil
        appState.updateComputerKeyConfig(cfg)
    }

    // MARK: - Custom CC Sheet
    private var customCCSheet: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Configure MIDI CC for Key '\(configuringKeyLabel)'")
                    .font(.headline)
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
                    showCCSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    if let code = configuringKey {
                        let ctrl = UInt8(clamping: max(0, min(127, Int(customCCController) ?? 64)))
                        let val = UInt8(clamping: max(0, min(127, Int(customCCValue) ?? 127)))
                        let offVal = UInt8(clamping: max(0, min(127, Int(customCCOffValue) ?? 0)))
                        let label = customCCLabel.trimmingCharacters(in: .whitespaces).isEmpty ? nil : customCCLabel

                        let cc = DrumPadCCConfig(controller: ctrl, value: val, offValue: offVal, mode: customCCMode, customLabel: label)
                        assignCCPreset(cc, keyCode: code, label: configuringKeyLabel, current: appState.computerKeyConfig(keyCode: code))
                    }
                    showCCSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    // MARK: - Key Layout Definitions

    private func getMainBlockKeys(for row: Int) -> [ComputerKeyInfo] {
        switch row {
        case 0: // Function row: 1.0 + 0.45 + (4 * 0.9 = 3.6) + 0.40 + 3.6 + 0.40 + 3.6 + 0.45 + 1.0 = 14.50
            return [
                ComputerKeyInfo(id: "esc", keyCode: 53, label: "esc", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true, gapAfter: 0.45),
                ComputerKeyInfo(id: "f1", keyCode: 122, label: "F1", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f2", keyCode: 120, label: "F2", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f3", keyCode: 99, label: "F3", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f4", keyCode: 118, label: "F4", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true, gapAfter: 0.40),
                ComputerKeyInfo(id: "f5", keyCode: 96, label: "F5", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f6", keyCode: 97, label: "F6", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f7", keyCode: 98, label: "F7", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f8", keyCode: 100, label: "F8", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true, gapAfter: 0.40),
                ComputerKeyInfo(id: "f9", keyCode: 101, label: "F9", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f10", keyCode: 109, label: "F10", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f11", keyCode: 103, label: "F11", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true),
                ComputerKeyInfo(id: "f12", keyCode: 111, label: "F12", secondaryLabel: nil, widthUnits: 0.9, isConfigurable: true, gapAfter: 0.45),
                ComputerKeyInfo(id: "pwr", keyCode: nil, label: "⏻", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: false)
            ]
        case 1: // Number row: 13 * 1.0 + 1.50 = 14.50
            return [
                ComputerKeyInfo(id: "grave", keyCode: 50, label: "`", secondaryLabel: "~", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "1", keyCode: 18, label: "1", secondaryLabel: "!", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "2", keyCode: 19, label: "2", secondaryLabel: "@", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "3", keyCode: 20, label: "3", secondaryLabel: "#", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "4", keyCode: 21, label: "4", secondaryLabel: "$", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "5", keyCode: 23, label: "5", secondaryLabel: "%", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "6", keyCode: 22, label: "6", secondaryLabel: "^", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "7", keyCode: 26, label: "7", secondaryLabel: "&", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "8", keyCode: 28, label: "8", secondaryLabel: "*", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "9", keyCode: 25, label: "9", secondaryLabel: "(", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "0", keyCode: 29, label: "0", secondaryLabel: ")", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "minus", keyCode: 27, label: "-", secondaryLabel: "_", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "equal", keyCode: 24, label: "=", secondaryLabel: "+", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "delete", keyCode: 51, label: "delete", secondaryLabel: nil, widthUnits: 1.50, isConfigurable: true)
            ]
        case 2: // QWERTY row: 1.50 + 10 * 1.0 + 1.0 + 1.0 + 1.0 = 14.50
            return [
                ComputerKeyInfo(id: "tab", keyCode: 48, label: "tab", secondaryLabel: nil, widthUnits: 1.50, isConfigurable: true),
                ComputerKeyInfo(id: "q", keyCode: 12, label: "Q", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "w", keyCode: 13, label: "W", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "e", keyCode: 14, label: "E", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "r", keyCode: 15, label: "R", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "t", keyCode: 17, label: "T", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "y", keyCode: 16, label: "Y", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "u", keyCode: 32, label: "U", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "i", keyCode: 34, label: "I", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "o", keyCode: 31, label: "O", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "p", keyCode: 35, label: "P", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "lbracket", keyCode: 33, label: "[", secondaryLabel: "{", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "rbracket", keyCode: 30, label: "]", secondaryLabel: "}", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "backslash", keyCode: 42, label: "\\", secondaryLabel: "|", widthUnits: 1.00, isConfigurable: true)
            ]
        case 3: // Home row: 1.75 + 11 * 1.0 + 1.75 = 14.50
            return [
                ComputerKeyInfo(id: "caps", keyCode: 57, label: "caps lock", secondaryLabel: nil, widthUnits: 1.75, isConfigurable: false),
                ComputerKeyInfo(id: "a", keyCode: 0, label: "A", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "s", keyCode: 1, label: "S", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "d", keyCode: 2, label: "D", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "f", keyCode: 3, label: "F", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "g", keyCode: 5, label: "G", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "h", keyCode: 4, label: "H", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "j", keyCode: 38, label: "J", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "k", keyCode: 40, label: "K", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "l", keyCode: 37, label: "L", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "semicolon", keyCode: 41, label: ";", secondaryLabel: ":", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "quote", keyCode: 39, label: "'", secondaryLabel: "\"", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "return", keyCode: 36, label: "return", secondaryLabel: nil, widthUnits: 1.75, isConfigurable: true)
            ]
        case 4: // ZXCV row: 2.25 + 10 * 1.0 + 2.25 = 14.50
            return [
                ComputerKeyInfo(id: "shift_l", keyCode: 56, label: "shift", secondaryLabel: nil, widthUnits: 2.25, isConfigurable: false),
                ComputerKeyInfo(id: "z", keyCode: 6, label: "Z", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "x", keyCode: 7, label: "X", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "c", keyCode: 8, label: "C", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "v", keyCode: 9, label: "V", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "b", keyCode: 11, label: "B", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "n", keyCode: 45, label: "N", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "m", keyCode: 46, label: "M", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "comma", keyCode: 43, label: ",", secondaryLabel: "<", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "period", keyCode: 47, label: ".", secondaryLabel: ">", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "slash", keyCode: 44, label: "/", secondaryLabel: "?", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "shift_r", keyCode: 60, label: "shift", secondaryLabel: nil, widthUnits: 2.25, isConfigurable: false)
            ]
        case 5: // Space bar row: 1.0 + 1.0 + 1.0 + 1.25 + 5.50 + 1.25 + 1.0 + 0.83 + 0.84 + 0.83 = 14.50
            return [
                ComputerKeyInfo(id: "fn", keyCode: 63, label: "fn", secondaryLabel: "🌐", widthUnits: 1.0, isConfigurable: false),
                ComputerKeyInfo(id: "ctrl", keyCode: 59, label: "control", secondaryLabel: "^", widthUnits: 1.0, isConfigurable: false),
                ComputerKeyInfo(id: "opt_l", keyCode: 58, label: "option", secondaryLabel: "⌥", widthUnits: 1.0, isConfigurable: false),
                ComputerKeyInfo(id: "cmd_l", keyCode: 55, label: "command", secondaryLabel: "⌘", widthUnits: 1.25, isConfigurable: false),
                ComputerKeyInfo(id: "space", keyCode: 49, label: "SPACE", secondaryLabel: nil, widthUnits: 5.50, isConfigurable: true),
                ComputerKeyInfo(id: "cmd_r", keyCode: 54, label: "command", secondaryLabel: "⌘", widthUnits: 1.25, isConfigurable: false),
                ComputerKeyInfo(id: "opt_r", keyCode: 61, label: "option", secondaryLabel: "⌥", widthUnits: 1.0, isConfigurable: false),
                ComputerKeyInfo(id: "arrow_l", keyCode: 123, label: "◀", secondaryLabel: nil, widthUnits: 0.83, isConfigurable: true),
                ComputerKeyInfo(id: "arrow_u_d", keyCode: nil, label: "▲▼", secondaryLabel: nil, widthUnits: 0.84, isConfigurable: true, isSplitArrows: true),
                ComputerKeyInfo(id: "arrow_r", keyCode: 124, label: "▶", secondaryLabel: nil, widthUnits: 0.83, isConfigurable: true)
            ]
        default:
            return []
        }
    }

    private func getNavBlockKeys(for row: Int) -> [ComputerKeyInfo] {
        switch row {
        case 0: // 3 * 1.0 = 3.00
            return [
                ComputerKeyInfo(id: "f13", keyCode: 105, label: "F13", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "f14", keyCode: 107, label: "F14", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "f15", keyCode: 113, label: "F15", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true)
            ]
        case 1: // 3 * 1.0 = 3.00
            return [
                ComputerKeyInfo(id: "fwd_del", keyCode: 117, label: "⌦", secondaryLabel: "del", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "home", keyCode: 115, label: "home", secondaryLabel: "↖", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "pageup", keyCode: 116, label: "pg up", secondaryLabel: "⇞", widthUnits: 1.0, isConfigurable: true)
            ]
        case 2: // 3 * 1.0 = 3.00
            return [
                ComputerKeyInfo(id: "nav_empty", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: false, isSpacer: true),
                ComputerKeyInfo(id: "end", keyCode: 119, label: "end", secondaryLabel: "↘", widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "pagedown", keyCode: 121, label: "pg dn", secondaryLabel: "⇟", widthUnits: 1.0, isConfigurable: true)
            ]
        case 3: // 1 * 3.0 = 3.00
            return [
                ComputerKeyInfo(id: "nav_s3_1", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 3.0, isConfigurable: false, isSpacer: true)
            ]
        case 4: // 1.0 + 1.0 + 1.0 = 3.00
            return [
                ComputerKeyInfo(id: "nav_s4_1", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: false, isSpacer: true),
                ComputerKeyInfo(id: "ext_arrow_u", keyCode: 126, label: "▲", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "nav_s4_2", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: false, isSpacer: true)
            ]
        case 5: // 3 * 1.0 = 3.00
            return [
                ComputerKeyInfo(id: "ext_arrow_l", keyCode: 123, label: "◀", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "ext_arrow_d", keyCode: 125, label: "▼", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "ext_arrow_r", keyCode: 124, label: "▶", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true)
            ]
        default:
            return []
        }
    }

    private func getNumpadBlockKeys(for row: Int) -> [ComputerKeyInfo] {
        switch row {
        case 0: // 4 * 1.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_clear", keyCode: 71, label: "clear", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_eq", keyCode: 81, label: "=", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_div", keyCode: 75, label: "/", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_mul", keyCode: 67, label: "*", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true)
            ]
        case 1: // 4 * 1.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_7", keyCode: 89, label: "7", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_8", keyCode: 91, label: "8", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_9", keyCode: 92, label: "9", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_sub", keyCode: 78, label: "-", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true)
            ]
        case 2: // 4 * 1.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_4", keyCode: 86, label: "4", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_5", keyCode: 87, label: "5", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_6", keyCode: 88, label: "6", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_add", keyCode: 69, label: "+", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true)
            ]
        case 3: // 3 * 1.0 + 1.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_1", keyCode: 83, label: "1", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_2", keyCode: 84, label: "2", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_3", keyCode: 85, label: "3", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_enter", keyCode: 76, label: "enter", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true, isNumpadEnter: true)
            ]
        case 4: // 2.0 + 1.0 + 1.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_0", keyCode: 82, label: "0", secondaryLabel: nil, widthUnits: 2.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_dec", keyCode: 65, label: ".", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: true),
                ComputerKeyInfo(id: "num_enter_space", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 1.0, isConfigurable: false, isSpacer: true)
            ]
        case 5: // 1 * 4.0 = 4.00
            return [
                ComputerKeyInfo(id: "num_s5", keyCode: nil, label: "", secondaryLabel: nil, widthUnits: 4.0, isConfigurable: false, isSpacer: true)
            ]
        default:
            return []
        }
    }
}
