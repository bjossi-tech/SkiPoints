import Foundation

/// Status of a ski race.
public enum RaceStatus: String, Codable, CaseIterable, Sendable {
    case scheduled = "Scheduled"
    case delayed = "Delayed"
    case inProgress = "In Progress"
    case intermission = "Intermission"
    case finished = "Finished"
    case official = "Official"
    case cancelled = "Cancelled"
    case postponed = "Postponed"
    
    // MARK: - Display Properties
    
    /// Human-readable display name
    public var displayName: String {
        rawValue
    }
    
    /// Short status indicator
    public var shortName: String {
        switch self {
        case .scheduled: return "SCHED"
        case .delayed: return "DELAY"
        case .inProgress: return "LIVE"
        case .intermission: return "BREAK"
        case .finished: return "UNOFF"
        case .official: return "FINAL"
        case .cancelled: return "CANC"
        case .postponed: return "POST"
        }
    }
    
    /// Whether the race is currently active (live)
    public var isLive: Bool {
        switch self {
        case .inProgress, .intermission: return true
        default: return false
        }
    }
    
    /// Whether results are available
    public var hasResults: Bool {
        switch self {
        case .inProgress, .intermission, .finished, .official: return true
        default: return false
        }
    }
    
    /// Whether results are final
    public var isFinal: Bool {
        self == .official
    }
    
    /// SF Symbol name for status indicator
    public var symbolName: String {
        switch self {
        case .scheduled: return "calendar"
        case .delayed: return "clock.badge.exclamationmark"
        case .inProgress: return "antenna.radiowaves.left.and.right"
        case .intermission: return "pause.circle"
        case .finished: return "clock"
        case .official: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        case .postponed: return "arrow.clockwise"
        }
    }
    
    /// Color (hex) for status badge
    public var colorHex: String {
        switch self {
        case .scheduled: return "#6C757D"      // Gray
        case .delayed: return "#FFC107"        // Yellow
        case .inProgress: return "#DC3545"     // Red (live)
        case .intermission: return "#FF9800"   // Orange
        case .finished: return "#FFC107"       // Yellow
        case .official: return "#28A745"       // Green
        case .cancelled: return "#343A40"      // Dark gray
        case .postponed: return "#17A2B8"      // Cyan
        }
    }
}

// MARK: - Parsing

extension RaceStatus {
    /// Initialize from FIS status strings
    public init?(fisString: String) {
        let normalized = fisString.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "scheduled", "not started":
            self = .scheduled
        case "delayed":
            self = .delayed
        case "in progress", "live", "running", "started":
            self = .inProgress
        case "intermission", "break", "between runs":
            self = .intermission
        case "finished", "completed", "unofficial":
            self = .finished
        case "official", "official result", "official results", "final":
            self = .official
        case "cancelled", "canceled":
            self = .cancelled
        case "postponed", "rescheduled":
            self = .postponed
        default:
            return nil
        }
    }
}

// MARK: - Comparable

extension RaceStatus: Comparable {
    /// Sort order: Live first, then scheduled, then completed
    private var sortOrder: Int {
        switch self {
        case .inProgress: return 0
        case .intermission: return 1
        case .scheduled: return 2
        case .delayed: return 3
        case .finished: return 4
        case .official: return 5
        case .postponed: return 6
        case .cancelled: return 7
        }
    }
    
    public static func < (lhs: RaceStatus, rhs: RaceStatus) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
