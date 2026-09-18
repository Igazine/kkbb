import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
public final class PadGridDocumentManager {
    public static let shared = PadGridDocumentManager()

    private let gridType = UTType(filenameExtension: "kkbbgrid") ?? .json

    private init() {}

    public func openLayout(for appState: AppState) {
        let panel = NSOpenPanel()
        panel.title = "Open Pad Grid Layout"
        panel.prompt = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [gridType, .json]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            try appState.loadPadGridLayout(from: url)
        } catch {
            showErrorAlert(
                title: "Failed to Open Layout",
                message: "The selected file could not be read or is not a valid Pad Grid layout:\n\(error.localizedDescription)"
            )
        }
    }

    public func save(for appState: AppState) {
        if let existingURL = appState.currentPadGridURL {
            do {
                try appState.savePadGridLayout(to: existingURL)
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
        panel.title = "Save Pad Grid Layout As"
        panel.prompt = "Save"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [gridType, .json]
        
        let initialName = appState.currentPadGridName ?? "PadGridLayout"
        panel.nameFieldStringValue = "\(initialName).kkbbgrid"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            try appState.savePadGridLayout(to: url)
        } catch {
            showErrorAlert(
                title: "Failed to Save Layout",
                message: "Could not save to \(url.lastPathComponent):\n\(error.localizedDescription)"
            )
        }
    }

    public func newLayout(for appState: AppState) {
        if !appState.activeProfile.drumPads.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Clear Pad Grid Layout?"
            alert.informativeText = "This will clear all pad assignments across Banks 0–6. Any unsaved changes will be lost."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Clear")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                appState.clearAllDrumPads()
            }
        } else {
            appState.clearAllDrumPads()
        }
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
