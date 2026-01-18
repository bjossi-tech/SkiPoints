import Foundation

/// Status of an individual athlete's result in a race.
public enum ResultStatus: String, Codable, CaseIterable, Sendable {
    case finished = "FIN"
    case didNotFinish = "DNF"
    case didNotStart = "DNS"
    case disqualified = "DSQ"
    case didNotQualify = "DNQ"
    case notClassified = "NC"
    case inProgress = "IP"
    
    // MARK: - Display Properties
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .finished: return "Finished"
        case .didNotFinish: return "Did Not Finish"
        case .didNotStart: return "Did Not Start"
        case .disqualified: return "Disqualified"
        case .didNotQualify: return "Did Not Qualify"
        case .notClassified: return "Not Classified"
        case .inProgress: return "In Progress"
        }
    }
    
    /// Short code for compact display
    public var shortCode: String {
        rawValue
    }
    
    /// Whether this is a valid finishing result with a time
    public var hasValidTime: Bool {
        self == .finished
    }
    
    /// Whether this status earns FIS/Cup points
    public var earnsPoints: Bool {
        self == .finished
    }
    
    /// Whether athlete participated (started the race)
    public var participated: Bool {
        self != .didNotStart
    }
    
    /// Color (hex) for status indicator
    public var colorHex: String {
        switch self {
        case .finished: return "#4CAF50"     // Green
        case .didNotFinish: return "#FF9800" // Orange
        case .didNotStart: return "#9E9E9E"  // Gray
        case .disqualified: return "#F44336" // Red
        case .didNotQualify: return "#795548" // Brown
        case .notClassified: return "#607D8B" // Blue-gray
        case .inProgress: return "#2196F3"   // Blue
        }
    }
}

// MARK: - Parsing

extension ResultStatus {
    /// Initialize from FIS format strings
    public init?(fisString: String) {
        let normalized = fisString.uppercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "FIN", "FINISHED", "": self = .finished
        case "DNF", "DID NOT FINISH": self = .didNotFinish
        case "DNS", "DID NOT START": self = .didNotStart
        case "DSQ", "DISQUALIFIED", "DQ": self = .disqualified
        case "DNQ", "DID NOT QUALIFY", "NQ": self = .didNotQualify
        case "NC", "NOT CLASSIFIED", "NPS": self = .notClassified
        case "IP", "IN PROGRESS", "RUNNING": self = .inProgress
        default: return nil
        }
    }
}
