import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(appState: appState)

            Divider()

            PianoRollView(appState: appState)
                .frame(minHeight: 120, maxHeight: .infinity)
        }
        .frame(minWidth: 700, minHeight: 220)
        .onAppear {
            refreshDestinations()
            KeyboardMonitor.shared.start(with: appState)
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
