import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var showSettings: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(appState: appState, showSettings: $showSettings)

            Divider()

            HStack(spacing: 0) {
                PitchModWheelsView(appState: appState)
                    .frame(width: 96)

                Divider()

                VStack(spacing: 0) {
                    OctaveBarView(appState: appState)

                    Divider()

                    KnobsStripView(appState: appState)

                    Divider()

                    PianoRollView(appState: appState)
                        .frame(minHeight: 120, maxHeight: .infinity)
                }
            }
            .focusable(false)
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            )
        }
        .frame(minWidth: 720, minHeight: 285)
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
    }

    private func refreshDestinations() {
        appState.availableDestinations = MIDIManager.shared.getDestinations()
    }
}
