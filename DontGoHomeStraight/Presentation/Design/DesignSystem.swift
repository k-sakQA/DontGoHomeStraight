import SwiftUI

// MARK: - Color + Hex initializer
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self = Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: alpha
        )
    }
}

// MARK: - App Theme Colors
extension Color {
    static let appBackground = Color(hex: "FAFAFA")
    static let appPrimary = Color(hex: "1976D2")
    static let appAccent = Color(hex: "FFC107")
    static let appText = Color(hex: "212121")
    
    // Surfaces / Utilities
    static let appSurface = Color.white
    static let appSurfaceAlt = Color(hex: "F5F5F5")
    static let appDivider = Color.black.opacity(0.06)
}