import SwiftUI

@main
struct KKBBApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandMenu("Keyboard") {
                Button("Octave Up (+)") {
                    if appState.octave < 6 {
                        appState.octave += 1
                    }
                }
                .keyboardShortcut("*", modifiers: [])

                Button("Octave Down (-)") {
                    if appState.octave > 0 {
                        appState.octave -= 1
                    }
                }
                .keyboardShortcut("/", modifiers: [])

                Divider()

                Button("Panic (All Notes Off)") {
                    KeyboardMonitor.shared.allNotesOff()
                }
                .keyboardShortcut(".", modifiers: [.command])
            }
        }
    }
}
