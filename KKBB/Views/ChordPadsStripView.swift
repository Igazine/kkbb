import SwiftUI
import AppKit

struct ChordPadButtonView: View {
    let index: Int
    let pad: ChordPadConfig
    let isActive: Bool
    let onToggle: () -> Void
    let onChordSelect: (String) -> Void
    let onBindingChange: (_ display: String, _ keyCode: UInt16?, _ modifierFlags: UInt?) -> Void

    @State private var isHovered: Bool = false
    @State private var showingKeySheet: Bool = false

    @State private var isListening: Bool = true
    @State private var recordedDisplay: String = ""
    @State private var recordedKeyCode: UInt16? = nil
    @State private var recordedModifiers: UInt? = nil

    private var chordType: ChordType {
        ChordType.find(by: pad.chordTypeID)
    }

    var body: some View {
        Button(action: {
            NSApp.keyWindow?.makeFirstResponder(nil)
            onToggle()
        }) {
            VStack(spacing: 2) {
                Text(pad.keyTrigger.isEmpty ? "-" : pad.keyTrigger.uppercased())
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)

                Text(chordType.shortName)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(isActive ? .primary : (isHovered ? .primary : .secondary))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        isActive
                            ? Color.accentColor.opacity(0.22)
                            : (isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.8) : Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        isActive ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.4) : Color.black.opacity(0.2)),
                        lineWidth: isActive ? 1.5 : 0.8
                    )
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuContent
        }
        .sheet(isPresented: $showingKeySheet) {
            configureKeySheet
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button(action: { onChordSelect("none") }) {
            if chordType.id == "none" {
                Label("No Chord (Single Note)", systemImage: "checkmark")
            } else {
                Text("No Chord (Single Note)")
            }
        }

        Divider()

        Menu("Chords") {
            ForEach(ChordType.allTypes.filter { $0.category == .chords && $0.id != "none" }) { type in
                Button(action: { onChordSelect(type.id) }) {
                    if chordType.id == type.id {
                        Label(type.name, systemImage: "checkmark")
                    } else {
                        Text(type.name)
                    }
                }
            }
        }

        Menu("Bitwig Scales & Modes") {
            ForEach(ChordType.allTypes.filter { $0.category == .scales }) { type in
                Button(action: { onChordSelect(type.id) }) {
                    if chordType.id == type.id {
                        Label(type.name, systemImage: "checkmark")
                    } else {
                        Text(type.name)
                    }
                }
            }
        }

        Divider()

        Button("Change Hot-Key…") {
            recordedDisplay = pad.keyTrigger.isEmpty ? "" : pad.keyTrigger.uppercased()
            recordedKeyCode = pad.keyCode
            recordedModifiers = pad.modifierFlags
            showingKeySheet = true
        }

        if isActive {
            Divider()
            Button("Deactivate Pad") {
                onToggle()
            }
        }
    }

    private var configureKeySheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Configure Pad \(index + 1) Hot-Key")
                        .font(.headline)
                    Text(chordType.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Key capture card
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

                    Text("Press any key or combination on your keyboard\n(e.g. F1–F12, 1–9, ⇧1, ⌥A, ⌘K, etc.)")
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
                    showingKeySheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                    onBindingChange(recordedDisplay, recordedKeyCode, recordedModifiers)
                    showingKeySheet = false
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
            guard event.type == .keyDown else { return false }

            // Allow Esc to cancel listening
            if event.keyCode == 53 && event.modifierFlags.intersection([.shift, .control, .option, .command]).isEmpty {
                DispatchQueue.main.async {
                    isListening = false
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
                return true
            }

            if let parsed = ChordPadConfig.parseEvent(event) {
                DispatchQueue.main.async {
                    recordedDisplay = parsed.display
                    recordedKeyCode = parsed.keyCode
                    recordedModifiers = parsed.modifierFlags
                    isListening = false
                    KeyboardMonitor.shared.keyCaptureHandler = nil
                }
                return true
            }
            return false
        }
    }
}

struct ChordPadsStripView: View {
    @Bindable var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(appState.activeProfile.chordPads.enumerated()), id: \.element.id) { index, pad in
                ChordPadButtonView(
                    index: index,
                    pad: pad,
                    isActive: appState.activeChordPadIndex == index,
                    onToggle: {
                        appState.toggleChordPad(index: index)
                    },
                    onChordSelect: { newChordID in
                        appState.updateChordPad(index: index, chordTypeID: newChordID)
                    },
                    onBindingChange: { display, keyCode, modifiers in
                        appState.updateChordPadBinding(
                            index: index,
                            keyTrigger: display,
                            keyCode: keyCode,
                            modifierFlags: modifiers
                        )
                    }
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(height: 42)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))
        .focusable(false)
    }
}
