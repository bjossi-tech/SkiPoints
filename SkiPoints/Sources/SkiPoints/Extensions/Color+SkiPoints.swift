import SwiftUI

/// SkiPoints brand colors.
extension Color {
    
    /// Primary ski blue color
    public static let skiBlue = Color(hex: "#1E88E5")
    
    /// Secondary accent color
    public static let skiOrange = Color(hex: "#FB8C00")
    
    /// Success/official green
    public static let skiGreen = Color(hex: "#28A745")
    
    /// Live/danger red
    public static let skiRed = Color(hex: "#DC3545")
    
    /// Warning yellow
    public static let skiYellow = Color(hex: "#FFC107")
    
    // MARK: - Initialization
    
    /// Initialize from hex string (e.g., "#FF5733" or "FF5733")
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Discipline Colors

extension Discipline {
    /// SwiftUI color for the discipline
    public var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Event Type Colors

extension EventType {
    /// SwiftUI color for the event type
    public var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Race Status Colors

extension RaceStatus {
    /// SwiftUI color for the status
    public var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Result Status Colors

extension ResultStatus {
    /// SwiftUI color for the status
    public var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Medal Colors

extension RaceResult.Medal {
    /// SwiftUI color for the medal
    public var color: Color {
        Color(hex: colorHex)
    }
}
