import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: SettingsTab = .profiles
    @State private var newProfileName: String = ""
    @State private var showingNewProfileAlert: Bool = false
    @State private var recordingPadIndex: Int? = nil

    enum SettingsTab: String, CaseIterable, Identifiable {
        case profiles = "Profiles"
        case keyboard = "Keyboard Notes"
        case chordPads = "Chord Pads"
        case midiCC = "MIDI CC Triggers"
        case mouse = "Mouse & Input"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .profiles: return "person.crop.circle"
            case .keyboard: return "pianokeys"
            case .chordPads: return "square.grid.3x3.square"
            case .midiCC: return "slider.vertical.3"
            case .mouse: return "cursorarrow.rays"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("KKBB Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Segmented Picker for Tabs
            Picker("Settings Tab", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case .profiles:
                    profilesTab
                case .keyboard:
                    keyboardTab
                case .chordPads:
                    chordPadsTab
                case .midiCC:
                    midiCCTab
                case .mouse:
                    mouseTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
        .frame(width: 740, height: 520)
    }

    // MARK: - Profiles Tab
    private var profilesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration Profiles")
                        .font(.title3.bold())
                    Text("Switch, create, and manage custom keyboard and CC mappings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    newProfileName = "\(appState.activeProfile.name) Copy"
                    showingNewProfileAlert = true
                } label: {
                    Label("Duplicate Active", systemImage: "plus.square.on.square")
                }
            }

            HStack(spacing: 16) {
                // Profile List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved Profiles")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    List(selection: Binding<UUID?>(
                        get: { appState.activeProfile.id },
                        set: { newID in
                            if let id = newID {
                                appState.selectProfile(id: id)
                            }
                        }
                    )) {
                        Section("Built-in") {
                            Text(KeyBindingProfile.defaultProfile.name)
                                .tag(KeyBindingProfile.defaultProfile.id)
                        }

                        if !appState.userProfiles.isEmpty {
                            Section("User Profiles") {
                                ForEach(appState.userProfiles) { profile in
                                    Text(profile.name)
                                        .tag(profile.id)
                                }
                            }
                        }
                    }
                    .listStyle(.bordered(alternatesRowBackgrounds: true))
                    .frame(width: 220)
                }

                // Profile Details / Actions
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active: \(appState.activeProfile.name)")
                            .font(.headline)
                        if appState.activeProfile.isDefault {
                            Text("Built-in Default Profile is protected and cannot be deleted.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Custom user profile. Changes are auto-saved.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !appState.activeProfile.isDefault {
                        HStack {
                            Text("Profile Name:")
                                .font(.subheadline)
                            TextField("Name", text: Binding(
                                get: { appState.activeProfile.name },
                                set: { newName in
                                    appState.activeProfile.name = newName
                                    appState.updateActiveProfile()
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                        }

                        Button(role: .destructive) {
                            appState.deleteProfile(id: appState.activeProfile.id)
                        } label: {
                            Label("Delete Profile", systemImage: "trash")
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            }
        }
        .sheet(isPresented: $showingNewProfileAlert) {
            VStack(spacing: 16) {
                Text("Create New Profile")
                    .font(.headline)
                TextField("Profile Name", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                HStack(spacing: 12) {
                    Button("Cancel") {
                        showingNewProfileAlert = false
                    }
                    Button("Create") {
                        let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = trimmed.isEmpty ? "Custom Profile" : trimmed
                        appState.createProfile(name: finalName)
                        showingNewProfileAlert = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(width: 320)
        }
    }

    // MARK: - Keyboard Notes Tab
    @State private var keyboardModeTab: KeyboardMode = .oneOctave

    private var keyboardTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key-to-Note Bindings")
                        .font(.title3.bold())
                    Text("Configure physical computer keyboard keys for 1-octave and 2-octaves modes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Layout", selection: $keyboardModeTab) {
                    Text("1-Octave").tag(KeyboardMode.oneOctave)
                    Text("2-Octaves").tag(KeyboardMode.twoOctaves)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if appState.activeProfile.isDefault {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text("The Default profile note layout is read-only. Duplicate this profile in the Profiles tab to customize key mappings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }

            // Mappings Table
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 140, maximum: 200)),
                    GridItem(.flexible(minimum: 140, maximum: 200)),
                    GridItem(.flexible(minimum: 140, maximum: 200))
                ], spacing: 10) {
                    if keyboardModeTab == .oneOctave {
                        ForEach(oneOctaveNoteNames, id: \.semitone) { item in
                            noteBindingCell(
                                noteName: item.name,
                                semitone: item.semitone,
                                currentKey: keyForSemitone(item.semitone, in: appState.activeProfile.oneOctaveNoteMap),
                                isEditable: !appState.activeProfile.isDefault,
                                onUpdate: { newKey in
                                    setKey(newKey, for: item.semitone, in: &appState.activeProfile.oneOctaveNoteMap)
                                    appState.updateActiveProfile()
                                }
                            )
                        }
                    } else {
                        ForEach(twoOctaveNoteNames, id: \.semitone) { item in
                            noteBindingCell(
                                noteName: item.name,
                                semitone: item.semitone,
                                currentKey: keyForSemitone(item.semitone, in: appState.activeProfile.twoOctaveNoteMap),
                                isEditable: !appState.activeProfile.isDefault,
                                onUpdate: { newKey in
                                    setKey(newKey, for: item.semitone, in: &appState.activeProfile.twoOctaveNoteMap)
                                    appState.updateActiveProfile()
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func noteBindingCell(
        noteName: String,
        semitone: Int,
        currentKey: String,
        isEditable: Bool,
        onUpdate: @escaping (String) -> Void
    ) -> some View {
        HStack {
            Text(noteName)
                .font(.subheadline.bold())
                .frame(width: 44, alignment: .leading)

            if isEditable {
                TextField("Key", text: Binding(
                    get: { currentKey },
                    set: { val in
                        if let first = val.trimmingCharacters(in: .whitespaces).first {
                            onUpdate(String(first))
                        } else {
                            onUpdate("")
                        }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 45)
            } else {
                Text(currentKey.isEmpty ? "-" : currentKey.uppercased())
                    .font(.system(.body, design: .monospaced).bold())
                    .frame(width: 36, height: 24)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(6)
    }

    private func keyForSemitone(_ semitone: Int, in map: [String: Int]) -> String {
        map.first(where: { $0.value == semitone })?.key ?? ""
    }

    private func setKey(_ newKey: String, for semitone: Int, in map: inout [String: Int]) {
        let oldKeys = map.filter { $0.value == semitone }.map { $0.key }
        for k in oldKeys {
            map.removeValue(forKey: k)
        }
        let trimmed = newKey.trimmingCharacters(in: .whitespaces).lowercased()
        if !trimmed.isEmpty {
            map[trimmed] = semitone
        }
    }

    // Note Names helpers
    private var oneOctaveNoteNames: [(name: String, semitone: Int)] {
        [
            ("C", 0), ("C#", 1), ("D", 2), ("D#", 3),
            ("E", 4), ("F", 5), ("F#", 6), ("G", 7),
            ("G#", 8), ("A", 9), ("A#", 10), ("B", 11),
            ("C (+1)", 12), ("C# (+1)", 13), ("D (+1)", 14), ("D# (+1)", 15),
            ("E (+1)", 16)
        ]
    }

    private var twoOctaveNoteNames: [(name: String, semitone: Int)] {
        [
            ("C1", 0), ("C#1", 1), ("D1", 2), ("D#1", 3),
            ("E1", 4), ("F1", 5), ("F#1", 6), ("G1", 7),
            ("G#1", 8), ("A1", 9), ("A#1", 10), ("B1", 11),
            ("C2", 12), ("C#2", 13), ("D2", 14), ("D#2", 15),
            ("E2", 16), ("F2", 17), ("F#2", 18), ("G2", 19),
            ("G#2", 20), ("A2", 21), ("A#2", 22), ("B2", 23),
            ("C3", 24), ("C#3", 25), ("D3", 26), ("D#3", 27), ("E3", 28)
        ]
    }

    // MARK: - MIDI CC Triggers Tab
    @State private var newCCKey: String = ""
    @State private var newCCLabel: String = ""
    @State private var newCCController: Int = 1
    @State private var newCCValue: Int = 127
    @State private var newCCMode: CCBindingMode = .momentary

    private var midiCCTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MIDI CC (Continuous Controller) Key Triggers")
                        .font(.title3.bold())
                    Text("Assign physical keyboard keys to send MIDI CC messages (0-127).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !appState.activeProfile.isDefault {
                    Button {
                        addNewCCBinding()
                    } label: {
                        Label("Add CC Trigger", systemImage: "plus")
                    }
                }
            }

            if appState.activeProfile.isDefault {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text("Default profile CC list is template only. Duplicate profile to add custom CC triggers (e.g. Page Up -> CC 55).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }

            // CC Table
            Table(appState.activeProfile.ccBindings) {
                TableColumn("Key") { binding in
                    Text(binding.keyChar.uppercased())
                        .font(.system(.body, design: .monospaced).bold())
                }
                .width(60)

                TableColumn("Label") { binding in
                    Text(binding.label)
                }
                .width(120)

                TableColumn("CC #") { binding in
                    Text("CC \(binding.controller)")
                        .font(.system(.body, design: .monospaced))
                }
                .width(80)

                TableColumn("Value") { binding in
                    Text("\(binding.value)")
                        .font(.system(.body, design: .monospaced))
                }
                .width(60)

                TableColumn("Mode") { binding in
                    Text(binding.mode.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
                .width(90)

                TableColumn("Action") { binding in
                    if !appState.activeProfile.isDefault {
                        Button(role: .destructive) {
                            appState.activeProfile.ccBindings.removeAll(where: { $0.id == binding.id })
                            appState.updateActiveProfile()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Text("-")
                            .foregroundStyle(.secondary)
                    }
                }
                .width(50)
            }
            .frame(minHeight: 180)

            if !appState.activeProfile.isDefault {
                // Quick Add Row
                HStack(spacing: 8) {
                    TextField("Key (e.g. p)", text: $newCCKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    TextField("Label (e.g. Filter)", text: $newCCLabel)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                    HStack(spacing: 2) {
                        Text("CC:")
                            .font(.caption)
                        TextField("CC", value: $newCCController, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                    }
                    HStack(spacing: 2) {
                        Text("Val:")
                            .font(.caption)
                        TextField("Val", value: $newCCValue, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                    }
                    Picker("Mode", selection: $newCCMode) {
                        ForEach(CCBindingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .frame(width: 110)

                    Button("Add") {
                        addNewCCBinding()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }
        }
    }

    private func addNewCCBinding() {
        let key = newCCKey.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty else { return }
        let label = newCCLabel.trimmingCharacters(in: .whitespaces).isEmpty ? "Custom CC" : newCCLabel
        let cc = UInt8(Swift.max(0, Swift.min(127, newCCController)))
        let val = UInt8(Swift.max(0, Swift.min(127, newCCValue)))

        let newBinding = CCKeyBinding(
            keyChar: key,
            label: label,
            controller: cc,
            value: val,
            mode: newCCMode
        )
        appState.activeProfile.ccBindings.append(newBinding)
        appState.updateActiveProfile()

        // Reset
        newCCKey = ""
        newCCLabel = ""
    }

    // MARK: - Mouse & Input Tab
    private var mouseTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mouse & Pointer Dynamics")
                    .font(.title3.bold())
                Text("Configure how mouse clicks and trackpad interactions produce MIDI events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Vertical Mouse Position Velocity Scaling", isOn: Binding(
                    get: { appState.activeProfile.mouseVerticalVelocityEnabled },
                    set: { val in
                        appState.activeProfile.mouseVerticalVelocityEnabled = val
                        appState.updateActiveProfile()
                    }
                ))
                .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("When enabled, clicking near the bottom edge of a virtual piano roll key sends maximum velocity (127), and clicking near the top edge sends minimum velocity (1).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Note: Computer keyboard key presses always transmit the fixed Velocity slider value from the top bar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 24)
            }
            .padding()
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pitch & Modulation Wheels")
                    .font(.headline)
                Text("• Pitch Bend Wheel: Centered at 8192 (0x2000 neutral). Springs back to center upon mouse release.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("• Modulation Wheel: Sends CC #1 (0-127). Friction drag, holds position upon release.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(8)

            Spacer()
        }
    }

    // MARK: - Chord Pads Tab
    private var chordPadsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chord Pads Configuration")
                        .font(.title3.bold())
                    Text("Configure the 12 performance pads, hot-keys (e.g. F1-F12), and chord / scale voicings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset to Defaults") {
                    appState.resetChordPadsToDefault()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if !KeyboardMonitor.shared.isAccessibilityTrusted {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("macOS System Hot-Keys Notice")
                            .font(.caption.bold())
                        Text("macOS reserves F11 for 'Show Desktop' by default. To let KKBB capture F11, either uncheck 'Show Desktop' in System Settings > Keyboard > Keyboard Shortcuts > Mission Control, or grant Accessibility access to KKBB in Privacy & Security.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(appState.activeProfile.chordPads.enumerated()), id: \.element.id) { idx, pad in
                        HStack(spacing: 8) {
                            Text("Pad \(idx + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 44, alignment: .leading)

                            // Hot-Key recording button
                            Button(action: {
                                if recordingPadIndex == idx {
                                    recordingPadIndex = nil
                                    KeyboardMonitor.shared.keyCaptureHandler = nil
                                } else {
                                    startRecordingPad(idx)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if recordingPadIndex == idx {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 6, height: 6)
                                        Text("Press key…")
                                            .font(.system(size: 9.5, weight: .bold))
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Text(pad.keyTrigger.isEmpty ? "Record" : pad.keyTrigger.uppercased())
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(pad.keyTrigger.isEmpty ? .secondary : .primary)
                                    }
                                }
                                .frame(width: 72, height: 22)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(recordingPadIndex == idx ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(recordingPadIndex == idx ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if !pad.keyTrigger.isEmpty {
                                Button(action: {
                                    appState.updateChordPadBinding(index: idx, keyTrigger: "", keyCode: nil, modifierFlags: nil)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            // Chord Type Picker
                            Picker("", selection: Binding(
                                get: { pad.chordTypeID },
                                set: { newChord in
                                    appState.updateChordPad(index: idx, chordTypeID: newChord)
                                }
                            )) {
                                Text("No Chord (Single Note)").tag("none")
                                Divider()
                                Section("Chords") {
                                    ForEach(ChordType.allTypes.filter { $0.category == .chords && $0.id != "none" }) { c in
                                        Text(c.name).tag(c.id)
                                    }
                                }
                                Section("Bitwig Scales & Modes") {
                                    ForEach(ChordType.allTypes.filter { $0.category == .scales }) { s in
                                        Text(s.name).tag(s.id)
                                    }
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.06))
                        .cornerRadius(6)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDisappear {
                if recordingPadIndex != nil {
                    recordingPadIndex = nil
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
            }
        }
    }

    private func startRecordingPad(_ index: Int) {
        recordingPadIndex = index
        KeyboardMonitor.shared.keyCaptureHandler = { event in
            guard event.type == .keyDown else { return false }

            if event.keyCode == 53 && event.modifierFlags.intersection([.shift, .control, .option, .command]).isEmpty {
                DispatchQueue.main.async {
                    recordingPadIndex = nil
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
                return true
            }

            if let parsed = ChordPadConfig.parseEvent(event) {
                DispatchQueue.main.async {
                    appState.updateChordPadBinding(
                        index: index,
                        keyTrigger: parsed.display,
                        keyCode: parsed.keyCode,
                        modifierFlags: parsed.modifierFlags
                    )
                    recordingPadIndex = nil
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
                return true
            }
            return false
        }
    }
}
