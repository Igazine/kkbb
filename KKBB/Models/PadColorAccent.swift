import Foundation
import SwiftUI

public enum PadColorAccent: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case rust = "rust"
    case tangerine = "tangerine"
    case gold = "gold"
    case sage = "sage"
    case teal = "teal"
    case cobalt = "cobalt"
    case lavender = "lavender"
    case rose = "rose"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "Default (Neutral)"
        case .rust: return "Rust (Warm Red)"
        case .tangerine: return "Tangerine (Orange)"
        case .gold: return "Gold (Warm Yellow)"
        case .sage: return "Sage (Muted Green)"
        case .teal: return "Teal (Mint Cyan)"
        case .cobalt: return "Cobalt (Slate Blue)"
        case .lavender: return "Lavender (Soft Purple)"
        case .rose: return "Rose (Dusty Pink)"
        }
    }

    public var swatchColor: Color {
        switch self {
        case .none:
            return Color.secondary
        case .rust:
            return Color(red: 0.82, green: 0.32, blue: 0.28)
        case .tangerine:
            return Color(red: 0.88, green: 0.52, blue: 0.24)
        case .gold:
            return Color(red: 0.86, green: 0.68, blue: 0.26)
        case .sage:
            return Color(red: 0.40, green: 0.65, blue: 0.45)
        case .teal:
            return Color(red: 0.25, green: 0.65, blue: 0.65)
        case .cobalt:
            return Color(red: 0.32, green: 0.54, blue: 0.84)
        case .lavender:
            return Color(red: 0.62, green: 0.48, blue: 0.82)
        case .rose:
            return Color(red: 0.82, green: 0.42, blue: 0.60)
        }
    }

    public func padBackground(isActive: Bool, isConfigured: Bool) -> Color {
        if self == .none {
            if isActive {
                return Color.accentColor.opacity(0.85)
            }
            return Color(nsColor: .controlBackgroundColor).opacity(isConfigured ? 0.70 : 0.40)
        }

        if isActive {
            return swatchColor.opacity(0.90)
        }
        return swatchColor.opacity(isConfigured ? 0.30 : 0.18)
    }

    public func padBorder(isActive: Bool, isConfigured: Bool) -> Color {
        if self == .none {
            if isActive {
                return isConfigured ? Color.white.opacity(0.85) : Color.accentColor
            }
            return isConfigured ? Color.accentColor.opacity(0.65) : Color.black.opacity(0.35)
        }

        if isActive {
            return Color.white.opacity(0.90)
        }
        return isConfigured ? swatchColor.opacity(0.80) : swatchColor.opacity(0.40)
    }
}
