import SwiftUI

struct TopBarView: View {
    @Bindable var appState: AppState
    @Binding var showSettings: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            // Mode
            VStack(alignment: .leading, spacing: 2) {
                Text("Mode")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("Mode", selection: $appState.mode) {
                    ForEach(KeyboardMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 142)
            }

            // Computer Keyboard Sub-Layout (only visible in Computer Keyboard mode)
            if appState.mode == .computerKeyboard {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Layout")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Picker("Layout", selection: $appState.computerKeyboardType) {
                        ForEach(ComputerKeyboardType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 125)
                }
            }

            // Output Destination
            VStack(alignment: .leading, spacing: 2) {
                Text("MIDI Output")
                    .font(.system(size: 9.5, weight: .medium))
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
                .frame(minWidth: 155)
            }

            // Channel
            VStack(alignment: .leading, spacing: 2) {
                Text("Channel")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("Channel", selection: $appState.channel) {
                    ForEach(1...16, id: \.self) { ch in
                        Text("\(ch)").tag(ch)
                    }
                }
                .labelsHidden()
                .frame(width: 58)
            }

            // One-Shot Mode Toggle
            Toggle("One-Shot", isOn: $appState.isOneShotMode)
                .toggleStyle(.checkbox)
                .font(.caption)
                .padding(.bottom, 3)
                .help("One-Shot Mode: sends a short 50ms trigger note without sustain (ideal for drums and percussion)")

            Spacer(minLength: 8)

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
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(height: 46)
        .background(.bar)
    }
}
