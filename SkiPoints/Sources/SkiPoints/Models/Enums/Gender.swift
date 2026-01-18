import Foundation

/// Gender category for ski racing events.
public enum Gender: String, Codable, CaseIterable, Sendable {
    case men = "M"
    case women = "W"
    
    // MARK: - Display Properties
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .men: return "Men"
        case .women: return "Women"
        }
    }
    
    /// Possessive form for labels (e.g., "Men's Downhill")
    public var possessive: String {
        switch self {
        case .men: return "Men's"
        case .women: return "Women's"
        }
    }
    
    /// SF Symbol name
    public var symbolName: String {
        switch self {
        case .men: return "figure.stand"
        case .women: return "figure.stand.dress"
        }
    }
}

// MARK: - Parsing

extension Gender {
    /// Initialize from FIS format strings
    public init?(fisString: String) {
        let normalized = fisString.uppercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "M", "MEN", "MALE", "GENTLEMEN": self = .men
        case "W", "L", "WOMEN", "LADIES", "FEMALE": self = .women
        default: return nil
        }
    }
}
