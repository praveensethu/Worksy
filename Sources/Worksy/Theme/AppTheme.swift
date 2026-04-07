import SwiftUI

enum AppTheme {
    // Backgrounds — warm charcoal dark theme (not navy/blue)
    static let background = Color(hex: "#1C1C1E")
    static let surface = Color(hex: "#2C2C2E")
    static let card = Color(hex: "#333336")
    static let sidebar = Color(hex: "#161618")

    // Text
    static let textPrimary = Color(hex: "#E8E8E8")
    static let textSecondary = Color(hex: "#8B8DA3")
    static let textMuted = Color(hex: "#5A5C72")

    // Board accent colors (assigned to boards)
    static let accents: [Color] = [
        Color(hex: "#FFB800"),  // Amber
        Color(hex: "#FF6B6B"),  // Coral
        Color(hex: "#00D68F"),  // Emerald
        Color(hex: "#FF2D78"),  // Hot Pink
        Color(hex: "#A855F7"),  // Violet
        Color(hex: "#14B8A6"),  // Teal
        Color(hex: "#0F9BF7"),  // Electric Blue
        Color(hex: "#6366F1"),  // Indigo
    ]

    static func accentColor(for hex: String) -> Color {
        Color(hex: hex)
    }
}

// MARK: - Color extension for hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (e.g. "#RRGGBB")
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (e.g. "#AARRGGBB")
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, (int >> 24) & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
