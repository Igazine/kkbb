import SwiftUI

@main
struct KKBBApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        Window("KKBB — KeyKeyBoardBoard", id: "main") {
            ContentView(appState: appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 820, height: 260)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Toggle("Always on Top", isOn: Binding(
                    get: { appState.isAlwaysOnTop },
                    set: { appState.isAlwaysOnTop = $0 }
                ))
            }

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
