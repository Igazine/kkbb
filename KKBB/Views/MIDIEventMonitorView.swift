import SwiftUI

public struct MIDIEventMonitorView: View {
    @Bindable var appState: AppState
    private let monitor = MIDIMonitorService.shared

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Status Bar (24px)
            HStack(spacing: 12) {
                // 1. Hardware Activity LEDs
                activityLEDsSection

                darkVDivider

                // 2. Middle Ticker / Status Area
                if appState.isMIDIMonitorExpanded {
                    HStack(spacing: 6) {
                        Text("EVENT LOG")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("(\(monitor.entries.count) EVENTS)")
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                } else {
                    tickerSection
                }

                Spacer(minLength: 4)

                // 3. Right Control Buttons
                HStack(spacing: 4) {
                    // Clear Log
                    Button {
                        monitor.clear()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(monitor.entries.isEmpty ? .secondary.opacity(0.3) : .secondary)
                    .disabled(monitor.entries.isEmpty)
                    .help("Clear Monitor Log")

                    // Expand / Collapse Chevron
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            appState.isMIDIMonitorExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: appState.isMIDIMonitorExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help(appState.isMIDIMonitorExpanded ? "Collapse to Status Bar" : "Expand Event History")
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Color(red: 0.09, green: 0.10, blue: 0.12))

            // Expanded Event History Table
            if appState.isMIDIMonitorExpanded {
                darkHDivider

                expandedLogView
                    .frame(height: 84)
                    .background(Color(red: 0.06, green: 0.07, blue: 0.08))
            }
        }
        .clipped()
    }

    // MARK: - Activity LEDs Section

    private var activityLEDsSection: some View {
        HStack(spacing: 10) {
            ledItem(
                label: "NOTE ON",
                isActive: monitor.isNoteOnActive,
                color: Color(red: 0.20, green: 0.85, blue: 0.55) // Emerald Green
            )

            ledItem(
                label: "NOTE OFF",
                isActive: monitor.isNoteOffActive,
                color: Color(white: 0.88) // Slate White
            )

            ledItem(
                label: "CC",
                isActive: monitor.isCCActive,
                color: Color(red: 0.98, green: 0.62, blue: 0.05) // Amber
            )

            ledItem(
                label: "PITCH/SYS",
                isActive: monitor.isPitchSysActive,
                color: Color(red: 0.22, green: 0.75, blue: 0.98) // Cyan
            )
        }
    }

    private func ledItem(label: String, isActive: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : color.opacity(0.18))
                .frame(width: 5.5, height: 5.5)
                .shadow(color: isActive ? color.opacity(0.9) : .clear, radius: 3)

            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? color : .secondary.opacity(0.75))
        }
    }

    // MARK: - Collapsed Single-Line Ticker

    private var tickerSection: some View {
        HStack(spacing: 8) {
            if let entry = monitor.lastEntry {
                Text("[\(entry.formattedTime)]")
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(entry.channelString)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.22, green: 0.75, blue: 0.98))

                Text(entry.type.rawValue)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(entry.type.badgeColor.opacity(0.18))
                    .foregroundColor(entry.type.badgeColor)
                    .cornerRadius(3)

                Text(entry.detail)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)

                Text(entry.hexBytes)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.7))

                Text("→ \(entry.destination)")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else {
                Text("MIDI MONITOR ACTIVE · LISTENING")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.55))
            }
        }
        .lineLimit(1)
    }

    // MARK: - Expanded Log Table

    private var expandedLogView: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 8) {
                Text("TIME")
                    .frame(width: 72, alignment: .leading)
                Text("CH")
                    .frame(width: 42, alignment: .leading)
                Text("EVENT")
                    .frame(width: 66, alignment: .leading)
                Text("DATA")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("HEX")
                    .frame(width: 76, alignment: .leading)
                Text("DESTINATION")
                    .frame(width: 140, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 10)
            .frame(height: 18)
            .background(Color.black.opacity(0.4))

            darkHDivider

            if monitor.entries.isEmpty {
                VStack {
                    Spacer()
                    Text("No MIDI events captured yet. Play keys, knobs, or pads to see traffic.")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(monitor.entries.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: 8) {
                                Text(entry.formattedTime)
                                    .frame(width: 72, alignment: .leading)
                                    .foregroundStyle(.secondary)

                                Text(entry.channelString)
                                    .frame(width: 42, alignment: .leading)
                                    .foregroundColor(Color(red: 0.22, green: 0.75, blue: 0.98))

                                Text(entry.type.rawValue)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 0.5)
                                    .background(entry.type.badgeColor.opacity(0.18))
                                    .foregroundColor(entry.type.badgeColor)
                                    .cornerRadius(2)
                                    .frame(width: 66, alignment: .leading)

                                Text(entry.detail)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(entry.hexBytes)
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundStyle(.secondary.opacity(0.8))
                                    .frame(width: 76, alignment: .leading)

                                Text(entry.destination)
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .frame(width: 140, alignment: .trailing)
                            }
                            .font(.system(size: 9, design: .monospaced))
                            .padding(.horizontal, 10)
                            .frame(height: 17)
                            .background(index % 2 == 0 ? Color.clear : Color.white.opacity(0.018))
                        }
                    }
                }
            }
        }
    }

    private var darkHDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.65))
            .frame(height: 1)
    }

    private var darkVDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.65))
            .frame(width: 1, height: 14)
    }
}
