import Foundation
import SwiftUI

public enum AppWindowState: String, Codable, CaseIterable, Identifiable {
    case full = "full"
    case compact = "compact"
    case micro = "micro"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .full: return "Full Workstation"
        case .compact: return "Compact Controller"
        case .micro: return "Micro HUD"
        }
    }

    public var iconName: String {
        switch self {
        case .full: return "rectangle.split.2x2"
        case .compact: return "slider.horizontal.2.square"
        case .micro: return "dot.square"
        }
    }

    public var shortcutHint: String {
        switch self {
        case .full: return "⌥⌘1"
        case .compact: return "⌥⌘2"
        case .micro: return "⌥⌘3"
        }
    }
}
