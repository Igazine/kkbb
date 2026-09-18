import SwiftUI

struct TopBarView: View {
    @Bindable var appState: AppState

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // ZONE 1: PERFORMANCE & TRIGGERING
            HStack(alignment: .bottom, spacing: 10) {
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
                    .frame(width: 125)
                }

                // Computer Keyboard Sub-Layout (only in Computer Keyboard mode)
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
                        .frame(width: 105)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Layer")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.secondary)
                        Picker("Layer", selection: Binding(
                            get: { appState.effectiveComputerKeyboardLayer },
                            set: { appState.computerKeyboardLayer = $0 }
                        )) {
                            ForEach(ComputerKeyboardLayer.allCases) { layer in
                                Text(layer.shortTitle).tag(layer)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 120)
                    }
                }

                // One-Shot Mode Toggle
                Toggle("One-Shot", isOn: $appState.isOneShotMode)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .padding(.bottom, 3)
                    .help("One-Shot Mode: sends a short 50ms trigger note without sustain (ideal for drums and percussion)")
            }

            // Hairline separator
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1, height: 26)
                .padding(.bottom, 2)

            // ZONE 2: MIDI ROUTING
            HStack(alignment: .bottom, spacing: 8) {
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
                    .lineLimit(1)
                    .frame(minWidth: 120, maxWidth: 160)
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
                    .frame(width: 52)
                }
            }

            Spacer(minLength: 8)

            // ZONE 3: SYSTEM & VIEW STATE
            HStack(alignment: .bottom, spacing: 8) {
                // Panic Button
                Button("Panic") {
                    KeyboardMonitor.shared.allNotesOff()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("All Notes Off (Panic)")

                // Window State Switcher (Full / Compact / Micro)
                HStack(spacing: 2) {
                    ForEach(AppWindowState.allCases) { state in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                appState.setWindowState(state)
                            }
                        } label: {
                            Image(systemName: state.iconName)
                                .font(.system(size: 10, weight: .semibold))
                                .frame(width: 17, height: 16)
                                .foregroundColor(appState.windowState == state ? .white : .secondary)
                                .background(appState.windowState == state ? Color.accentColor : Color.clear)
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                        .help("\(state.displayName) (\(state.shortcutHint))")
                    }
                }
                .padding(2)
                .background(Color.black.opacity(0.25))
                .cornerRadius(5)
                .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(height: 46)
        .background(.bar)
    }
}
