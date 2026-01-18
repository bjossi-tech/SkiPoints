import Foundation

/// Ski racing discipline.
///
/// Each discipline has different characteristics affecting FIS points calculation
/// and race format (number of runs, course length, etc.)
public enum Discipline: String, Codable, CaseIterable, Sendable {
    case downhill = "DH"
    case superG = "SG"
    case giantSlalom = "GS"
    case slalom = "SL"
    case alpineCombined = "AC"
    case parallelSlalom = "PSL"
    case parallelGiantSlalom = "PGS"
    case teamEvent = "TE"
    
    // MARK: - Display Properties
    
    /// Full display name for the discipline
    public var displayName: String {
        switch self {
        case .downhill: return "Downhill"
        case .superG: return "Super G"
        case .giantSlalom: return "Giant Slalom"
        case .slalom: return "Slalom"
        case .alpineCombined: return "Alpine Combined"
        case .parallelSlalom: return "Parallel Slalom"
        case .parallelGiantSlalom: return "Parallel GS"
        case .teamEvent: return "Team Event"
        }
    }
    
    /// Short abbreviation for compact UI
    public var shortName: String {
        rawValue
    }
    
    /// SF Symbol name for discipline
    public var iconName: String {
        switch self {
        case .downhill: return "arrow.down.circle.fill"
        case .superG: return "bolt.circle.fill"
        case .giantSlalom: return "figure.skiing.downhill"
        case .slalom: return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .alpineCombined: return "square.stack.fill"
        case .parallelSlalom, .parallelGiantSlalom: return "arrow.left.arrow.right"
        case .teamEvent: return "person.3.fill"
        }
    }
    
    /// Brand color for the discipline (hex)
    public var colorHex: String {
        switch self {
        case .downhill: return "#E53935"      // Red
        case .superG: return "#FB8C00"        // Orange
        case .giantSlalom: return "#1E88E5"   // Blue
        case .slalom: return "#43A047"        // Green
        case .alpineCombined: return "#8E24AA" // Purple
        case .parallelSlalom, .parallelGiantSlalom: return "#00ACC1"  // Cyan
        case .teamEvent: return "#5C6BC0"     // Indigo
        }
    }
    
    // MARK: - FIS Points Factor
    
    /// Factor (F) used in the FIS points calculation formula.
    ///
    /// Formula: `FIS Points = ((Race Time - Winner Time) / Winner Time) × F + Penalty`
    public var fisPointsFactor: Double {
        switch self {
        case .downhill: return 1330.0
        case .superG: return 1190.0
        case .giantSlalom: return 1010.0
        case .slalom: return 730.0
        case .alpineCombined: return 1360.0
        case .parallelSlalom, .parallelGiantSlalom: return 730.0
        case .teamEvent: return 1010.0
        }
    }
    
    // MARK: - Race Characteristics
    
    /// Number of runs in a standard race
    public var numberOfRuns: Int {
        switch self {
        case .downhill, .superG: return 1
        case .giantSlalom, .slalom: return 2
        case .alpineCombined: return 2
        case .parallelSlalom, .parallelGiantSlalom: return 1
        case .teamEvent: return 1
        }
    }
    
    /// Whether this is a speed discipline
    public var isSpeedEvent: Bool {
        switch self {
        case .downhill, .superG: return true
        default: return false
        }
    }
    
    /// Whether this is a technical discipline
    public var isTechnicalEvent: Bool {
        switch self {
        case .giantSlalom, .slalom: return true
        default: return false
        }
    }
}

// MARK: - Parsing

extension Discipline {
    /// Initialize from various FIS format strings
    public init?(fisString: String) {
        let normalized = fisString.uppercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "DH", "DOWNHILL": self = .downhill
        case "SG", "SUPER G", "SUPER-G", "SUPERG": self = .superG
        case "GS", "GIANT SLALOM", "GIANTSLALOM": self = .giantSlalom
        case "SL", "SLALOM": self = .slalom
        case "AC", "ALPINE COMBINED", "COMBINED": self = .alpineCombined
        case "PSL", "PARALLEL SLALOM": self = .parallelSlalom
        case "PGS", "PARALLEL GIANT SLALOM": self = .parallelGiantSlalom
        case "TE", "TEAM", "TEAM EVENT": self = .teamEvent
        default: return nil
        }
    }
}
