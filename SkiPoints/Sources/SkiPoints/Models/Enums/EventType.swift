import Foundation

/// Competition category/level in the FIS racing hierarchy.
///
/// Determines the prestige of the race and affects World Cup standings eligibility.
public enum EventType: String, Codable, CaseIterable, Sendable {
    case worldCup = "WC"
    case europaCup = "EC"
    case norAmCup = "NAC"
    case fis = "FIS"
    case nationalChampionship = "NC"
    case worldChampionship = "WSC"
    case olympics = "OWG"
    
    // MARK: - Display Properties
    
    /// Full display name
    public var displayName: String {
        switch self {
        case .worldCup: return "World Cup"
        case .europaCup: return "Europa Cup"
        case .norAmCup: return "Nor-Am Cup"
        case .fis: return "FIS Race"
        case .nationalChampionship: return "National Championship"
        case .worldChampionship: return "World Championship"
        case .olympics: return "Olympic Games"
        }
    }
    
    /// Short code for compact display
    public var shortName: String {
        rawValue
    }
    
    /// Whether this event type awards World Cup points
    public var awardsWorldCupPoints: Bool {
        self == .worldCup
    }
    
    /// Whether this is a major championship
    public var isMajorEvent: Bool {
        switch self {
        case .worldChampionship, .olympics: return true
        default: return false
        }
    }
    
    /// Color (hex) for event type badge
    public var colorHex: String {
        switch self {
        case .worldCup: return "#FFD700"        // Gold
        case .europaCup: return "#C0C0C0"       // Silver
        case .norAmCup: return "#CD7F32"        // Bronze
        case .fis: return "#4A90D9"             // Blue
        case .nationalChampionship: return "#50C878" // Emerald
        case .worldChampionship: return "#9B59B6"    // Purple
        case .olympics: return "#E74C3C"         // Olympic Red
        }
    }
    
    /// Badge priority for sorting (higher = more prestigious)
    public var priority: Int {
        switch self {
        case .olympics: return 100
        case .worldChampionship: return 90
        case .worldCup: return 80
        case .europaCup: return 60
        case .norAmCup: return 50
        case .nationalChampionship: return 40
        case .fis: return 20
        }
    }
}

// MARK: - Parsing

extension EventType {
    /// Initialize from FIS format strings
    public init?(fisString: String) {
        let normalized = fisString.uppercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "WC", "WORLD CUP": self = .worldCup
        case "EC", "EUROPA CUP", "EUROPEAN CUP": self = .europaCup
        case "NAC", "NOR-AM", "NOR-AM CUP", "NORAM": self = .norAmCup
        case "FIS", "FIS RACE": self = .fis
        case "NC", "NATIONAL", "NATIONAL CHAMPIONSHIP": self = .nationalChampionship
        case "WSC", "WORLD CHAMPIONSHIP", "WORLD CHAMPIONSHIPS": self = .worldChampionship
        case "OWG", "OLYMPIC", "OLYMPICS", "OLYMPIC GAMES": self = .olympics
        default: return nil
        }
    }
}
