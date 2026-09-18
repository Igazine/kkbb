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
        .defaultSize(width: 820, height: 420)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Pad Grid Layout") {
                    PadGridDocumentManager.shared.newLayout(for: appState)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("Open Pad Grid Layout…") {
                    PadGridDocumentManager.shared.openLayout(for: appState)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save Pad Grid Layout") {
                    PadGridDocumentManager.shared.save(for: appState)
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button("Save Pad Grid Layout As…") {
                    PadGridDocumentManager.shared.saveAs(for: appState)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

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
