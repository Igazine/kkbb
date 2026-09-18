import SwiftUI
import AppKit

public struct MicroHUDView: View {
    @Bindable var appState: AppState
    private let monitor = MIDIMonitorService.shared
    @State private var isAppFocused: Bool = true
    @State private var isPadPressed: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 6) {
            // 1. Top Header: State Switcher & Octave/Channel
            HStack(spacing: 6) {
                // State Switcher (Full / Compact / Micro)
                HStack(spacing: 2) {
                    stateButton(for: .full)
                    stateButton(for: .compact)
                    stateButton(for: .micro)
                }
                .padding(2)
                .background(Color.black.opacity(0.35))
                .cornerRadius(5)

                Spacer(minLength: 2)

                // Octave Stepper
                HStack(spacing: 2) {
                    Button {
                        if appState.octave > 0 { appState.octave -= 1 }
                    } label: {
                        Text("-")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .frame(width: 13, height: 16)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.octave <= 0)

                    Text("OCT \(appState.octave)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Button {
                        if appState.octave < 6 { appState.octave += 1 }
                    } label: {
                        Text("+")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .frame(width: 13, height: 16)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.octave >= 6)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)

                // Channel Badge
                Text("CH\(appState.channel)")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.75, green: 0.52, blue: 0.99))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // 2. Clickable Keyboard Focus Box (Touch Pad)
            Button {
                activateWindowFocus()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isPadPressed
                                ? Color.accentColor.opacity(0.3)
                                : (isAppFocused ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isPadPressed
                                        ? Color.accentColor
                                        : (isAppFocused ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.15)),
                                    lineWidth: 1.5
                                )
                        )

                    VStack(spacing: 6) {
                        // 4 Live Activity LEDs
                        HStack(spacing: 8) {
                            hudLED(color: Color(red: 0.20, green: 0.85, blue: 0.55), isActive: monitor.isNoteOnActive)
                            hudLED(color: Color(white: 0.88), isActive: monitor.isNoteOffActive)
                            hudLED(color: Color(red: 0.98, green: 0.62, blue: 0.05), isActive: monitor.isCCActive)
                            hudLED(color: Color(red: 0.22, green: 0.75, blue: 0.98), isActive: monitor.isPitchSysActive)
                        }
                        .padding(.top, 4)

                        // Center Icon & Status Prompt
                        Image(systemName: isAppFocused ? "keyboard.fill" : "hand.tap.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isAppFocused ? .accentColor : .secondary)

                        Text(isAppFocused ? "KEYBOARD READY" : "CLICK TO FOCUS")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(isAppFocused ? .primary : .secondary.opacity(0.85))
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPadPressed = true }
                    .onEnded { _ in isPadPressed = false }
            )

            // 3. Bottom Panic Button
            Button {
                KeyboardMonitor.shared.allNotesOff()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text("PANIC")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(Color.red.opacity(0.22))
                .foregroundColor(Color(red: 0.98, green: 0.40, blue: 0.40))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.red.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            .help("All Notes Off (Panic)")
        }
        .frame(width: 195, height: 195)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .onAppear {
            isAppFocused = NSApp.isActive
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isAppFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            isAppFocused = false
        }
    }

    private func stateButton(for state: AppWindowState) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                appState.setWindowState(state)
            }
        } label: {
            Image(systemName: state.iconName)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 18, height: 18)
                .foregroundColor(appState.windowState == state ? .white : .secondary)
                .background(appState.windowState == state ? Color.accentColor : Color.clear)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .help("\(state.displayName) (\(state.shortcutHint))")
    }

    private func hudLED(color: Color, isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? color : color.opacity(0.2))
            .frame(width: 6, height: 6)
            .shadow(color: isActive ? color.opacity(0.9) : .clear, radius: 3)
    }

    private func activateWindowFocus() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.title.contains("KKBB") }) {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(nil)
        }
    }
}
