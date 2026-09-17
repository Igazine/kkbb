import SwiftUI
import AppKit

struct ChordPadButtonView: View {
    let index: Int
    let pad: ChordPadConfig
    let isActive: Bool
    let onToggle: () -> Void
    let onChordSelect: (String) -> Void
    let onKeyTriggerChange: (String) -> Void

    @State private var isHovered: Bool = false
    @State private var showingKeySheet: Bool = false
    @State private var newKeyString: String = ""

    private var chordType: ChordType {
        ChordType.find(by: pad.chordTypeID)
    }

    var body: some View {
        Button(action: {
            NSApp.keyWindow?.makeFirstResponder(nil)
            onToggle()
        }) {
            VStack(spacing: 2) {
                Text(pad.keyTrigger.uppercased())
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
            newKeyString = pad.keyTrigger
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
            Text("Configure Pad \(index + 1) Hot-Key")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Enter the keyboard trigger (e.g. F1-F12, or any key):")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Hot-Key:")
                    TextField("e.g. F1", text: $newKeyString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    showingKeySheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    let cleaned = newKeyString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if !cleaned.isEmpty {
                        onKeyTriggerChange(cleaned)
                    }
                    showingKeySheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 320)
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
                    onKeyTriggerChange: { newTrigger in
                        appState.updateChordPadTrigger(index: index, keyTrigger: newTrigger)
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
