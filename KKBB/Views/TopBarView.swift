import SwiftUI

struct TopBarView: View {
    @Bindable var appState: AppState
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Mode
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mode")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Picker("Mode", selection: $appState.mode) {
                        ForEach(KeyboardMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }

                // Output Destination
                VStack(alignment: .leading, spacing: 2) {
                    Text("MIDI Output")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Picker("Output", selection: $appState.selectedDestinationUID) {
                        Text("KKBB Virtual Only").tag(Int32?.none)
                        Divider()
                        ForEach(appState.availableDestinations) { dest in
                            Text(dest.name).tag(Int32?.some(dest.id))
                        }
                        if let selectedUID = appState.selectedDestinationUID,
                           !appState.availableDestinations.contains(where: { $0.id == selectedUID }) {
                            Text("Offline Device (Saved)").tag(Int32?.some(selectedUID))
                        }
                    }
                    .labelsHidden()
                    .frame(minWidth: 160)
                }

                // Channel
                VStack(alignment: .leading, spacing: 2) {
                    Text("Channel")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Picker("Channel", selection: $appState.channel) {
                        ForEach(1...16, id: \.self) { ch in
                            Text("\(ch)").tag(ch)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 60)
                }

                // One-Shot Mode Toggle
                Toggle("One-Shot", isOn: $appState.isOneShotMode)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .help("One-Shot Mode: sends a short 50ms trigger note without sustain (ideal for drums and percussion)")

                Spacer()

                // Panic Button
                Button("Panic") {
                    KeyboardMonitor.shared.allNotesOff()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("All Notes Off")

                // Settings Button
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Settings (⌘,)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
