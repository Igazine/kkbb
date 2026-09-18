import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
public final class LayoutDocumentManager {
    public static let shared = LayoutDocumentManager()

    private let layoutType = UTType(filenameExtension: "kkbb") ?? .json

    private init() {}

    public func openLayout(for appState: AppState) {
        let panel = NSOpenPanel()
        panel.title = "Open Layout"
        panel.prompt = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [layoutType, .json]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            try appState.loadLayout(from: url)
        } catch {
            showErrorAlert(
                title: "Failed to Open Layout",
                message: "The selected file could not be read or is not a valid KKBB layout:\n\(error.localizedDescription)"
            )
        }
    }

    public func save(for appState: AppState) {
        if let existingURL = appState.currentLayoutURL {
            do {
                try appState.saveLayout(to: existingURL)
            } catch {
                showErrorAlert(
                    title: "Failed to Save Layout",
                    message: "Could not save to \(existingURL.lastPathComponent):\n\(error.localizedDescription)"
                )
            }
        } else {
            saveAs(for: appState)
        }
    }

    public func saveAs(for appState: AppState) {
        let panel = NSSavePanel()
        panel.title = "Save Layout As"
        panel.prompt = "Save"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [layoutType, .json]

        let initialName = appState.currentLayoutName ?? "KKBBLayout"
        panel.nameFieldStringValue = "\(initialName).kkbb"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            try appState.saveLayout(to: url)
        } catch {
            showErrorAlert(
                title: "Failed to Save Layout",
                message: "Could not save to \(url.lastPathComponent):\n\(error.localizedDescription)"
            )
        }
    }

    public func newLayout(for appState: AppState) {
        let hasPads = !appState.activeProfile.drumPads.isEmpty
        let hasKeys = !appState.activeProfile.computerKeyboardKeys.isEmpty

        if hasPads || hasKeys {
            let alert = NSAlert()
            alert.messageText = "Clear Current Layout?"
            alert.informativeText = "This will clear all custom pad and computer keyboard key assignments. Any unsaved changes will be lost."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Clear")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                appState.clearAllLayout()
            }
        } else {
            appState.clearAllLayout()
        }
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }
}
