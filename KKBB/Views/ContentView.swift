import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var showSettings: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(appState: appState, showSettings: $showSettings)

            darkHDivider

            HStack(spacing: 0) {
                PitchModWheelsView(appState: appState)
                    .frame(width: 96)

                darkVDivider

                VStack(spacing: 0) {
                    OctaveBarView(appState: appState)

                    KnobsStripView(appState: appState)

                    darkHDivider

                    if appState.mode == .drumGrid {
                        DrumPadGridView(appState: appState)
                            .frame(minHeight: 180, maxHeight: .infinity)
                            .clipped()
                    } else {
                        PianoRollView(appState: appState)
                            .frame(minHeight: 120, maxHeight: .infinity)
                            .clipped()

                        darkHDivider

                        ChordPadsStripView(appState: appState)
                    }
                }
            }
            .focusable(false)
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            )
        }
        .frame(minWidth: 720, minHeight: appState.mode == .drumGrid ? 390 : 330)
        .sheet(isPresented: $showSettings) {
            SettingsView(appState: appState)
        }
        .background {
            // Hidden button to catch Cmd+, shortcut
            Button("") {
                showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
            .focusable(false)
            .opacity(0)
        }
        .onAppear {
            refreshDestinations()
            KeyboardMonitor.shared.start(with: appState)
            appState.applyWindowLevel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onDisappear {
            KeyboardMonitor.shared.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: .midiDestinationsChanged)) { _ in
            refreshDestinations()
        }
        .onChange(of: appState.currentPadGridName) { _, newName in
            updateWindowSubtitle(newName)
        }
        .onChange(of: appState.mode) { _, _ in
            updateWindowSubtitle(appState.currentPadGridName)
        }
    }

    private func updateWindowSubtitle(_ name: String?) {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                if window.identifier?.rawValue == "main" || window.title.contains("KKBB") {
                    window.subtitle = (appState.mode == .drumGrid && name != nil) ? name! : ""
                }
            }
        }
    }

    private func refreshDestinations() {
        appState.availableDestinations = MIDIManager.shared.getDestinations()
    }

    private var darkHDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.65))
            .frame(height: 1)
    }

    private var darkVDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.65))
            .frame(width: 1)
    }
}
