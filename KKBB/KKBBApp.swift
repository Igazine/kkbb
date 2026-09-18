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
                Button("New Layout") {
                    LayoutDocumentManager.shared.newLayout(for: appState)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("Open Layout…") {
                    LayoutDocumentManager.shared.openLayout(for: appState)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save Layout") {
                    LayoutDocumentManager.shared.save(for: appState)
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button("Save Layout As…") {
                    LayoutDocumentManager.shared.saveAs(for: appState)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(after: .windowArrangement) {
                Toggle("Always on Top", isOn: Binding(
                    get: { appState.isAlwaysOnTop },
                    set: { appState.isAlwaysOnTop = $0 }
                ))
            }

            CommandMenu("View") {
                Toggle("MIDI Event Monitor", isOn: Binding(
                    get: { appState.isMIDIMonitorVisible },
                    set: { appState.isMIDIMonitorVisible = $0 }
                ))
                .keyboardShortcut("m", modifiers: [.command, .option])

                Toggle("Expand Event Monitor", isOn: Binding(
                    get: { appState.isMIDIMonitorExpanded },
                    set: { appState.isMIDIMonitorExpanded = $0 }
                ))
                .disabled(!appState.isMIDIMonitorVisible)
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
