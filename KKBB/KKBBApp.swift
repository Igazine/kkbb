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
                Button("Octave Up") {
                    if appState.octave < 6 {
                        appState.octave += 1
                    }
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Octave Down") {
                    if appState.octave > 0 {
                        appState.octave -= 1
                    }
                }
                .keyboardShortcut(.downArrow, modifiers: [])

                Divider()

                Button("Increase Velocity (+1)") {
                    appState.velocity = Swift.min(127, appState.velocity + 1)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Decrease Velocity (-1)") {
                    appState.velocity = Swift.max(1, appState.velocity - 1)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Button("Increase Velocity (+10)") {
                    appState.velocity = Swift.min(127, appState.velocity + 10)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.shift])

                Button("Decrease Velocity (-10)") {
                    appState.velocity = Swift.max(1, appState.velocity - 10)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.shift])

                Divider()

                Button("Panic (All Notes Off)") {
                    KeyboardMonitor.shared.allNotesOff()
                }
                .keyboardShortcut(".", modifiers: [.command])
            }
        }
    }
}
