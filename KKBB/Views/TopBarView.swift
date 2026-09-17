import SwiftUI

struct TopBarView: View {
    @Bindable var appState: AppState

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

                Divider()
                    .frame(height: 24)

                // Octave Slider
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Octave")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("C\(appState.octave)")
                            .font(.caption2.monospacedDigit().bold())
                    }
                    Slider(
                        value: Binding(
                            get: { Double(appState.octave) },
                            set: { appState.octave = Int($0) }
                        ),
                        in: 0...6,
                        step: 1
                    )
                    .frame(width: 90)
                }

                // Velocity Slider
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Velocity")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(appState.velocity)")
                            .font(.caption2.monospacedDigit().bold())
                    }
                    Slider(
                        value: Binding(
                            get: { Double(appState.velocity) },
                            set: { appState.velocity = Int($0) }
                        ),
                        in: 1...127,
                        step: 1
                    )
                    .frame(width: 90)
                }

                Spacer()

                // Panic Button
                Button("Panic") {
                    KeyboardMonitor.shared.allNotesOff()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("All Notes Off")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
