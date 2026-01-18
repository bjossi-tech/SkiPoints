import Foundation

/// Represents an individual athlete's result in a race.
///
/// Contains timing data, ranking, and calculated points.
///
/// ## Example
/// ```swift
/// let result = RaceResult(
///     raceID: "127380",
///     rank: 1,
///     bib: 10,
///     athlete: athlete,
///     timeSeconds: 105.19,
///     differenceSeconds: 0,
///     status: .finished,
///     fisPoints: 0.0,
///     cupPoints: 100
/// )
/// ```
public struct RaceResult: Codable, Sendable {
    
    // MARK: - Identification
    
    /// Parent race ID
    public let raceID: String
    
    /// Finishing rank (1 = winner)
    public let rank: Int
    
    /// Start bib number
    public let bib: Int
    
    /// The athlete
    public let athlete: Athlete
    
    // MARK: - Timing
    
    /// Total race time in seconds (nil if DNF/DNS)
    public let timeSeconds: TimeInterval?
    
    /// Time behind leader in seconds
    public let differenceSeconds: TimeInterval?
    
    // MARK: - Status & Points
    
    /// Result status (finished, DNF, DNS, etc.)
    public let status: ResultStatus
    
    /// Calculated FIS points
    public var fisPoints: Double
    
    /// World Cup points (if applicable)
    public var cupPoints: Int
    
    // MARK: - Initialization
    
    public init(
        raceID: String,
        rank: Int,
        bib: Int,
        athlete: Athlete,
        timeSeconds: TimeInterval?,
        differenceSeconds: TimeInterval?,
        status: ResultStatus,
        fisPoints: Double = 0.0,
        cupPoints: Int = 0
    ) {
        self.raceID = raceID
        self.rank = rank
        self.bib = bib
        self.athlete = athlete
        self.timeSeconds = timeSeconds
        self.differenceSeconds = differenceSeconds
        self.status = status
        self.fisPoints = fisPoints
        self.cupPoints = cupPoints
    }
    
    // MARK: - Computed Properties
    
    /// Formatted race time (e.g., "1:45.19")
    public var formattedTime: String {
        guard let time = timeSeconds else {
            return status.shortCode
        }
        return formatRaceTime(time)
    }
    
    /// Formatted difference (e.g., "+0.35" or "")
    public var formattedDiff: String {
        guard let diff = differenceSeconds, diff > 0 else {
            return ""
        }
        return String(format: "+%.2f", diff)
    }
    
    /// Formatted FIS points (e.g., "3.96")
    public var formattedFISPoints: String {
        String(format: "%.2f", fisPoints)
    }
    
    /// Whether this is a podium finish (1-3)
    public var isPodium: Bool {
        rank >= 1 && rank <= 3 && status == .finished
    }
    
    /// Whether this is the winner
    public var isWinner: Bool {
        rank == 1 && status == .finished
    }
    
    /// Medal for podium finishes
    public var medal: Medal? {
        guard status == .finished else { return nil }
        switch rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return nil
        }
    }
}

// MARK: - Medal Type

extension RaceResult {
    /// Medal types for podium finishes
    public enum Medal: String, CaseIterable, Sendable {
        case gold
        case silver
        case bronze
        
        public var emoji: String {
            switch self {
            case .gold: return "🥇"
            case .silver: return "🥈"
            case .bronze: return "🥉"
            }
        }
        
        public var colorHex: String {
            switch self {
            case .gold: return "#FFD700"
            case .silver: return "#C0C0C0"
            case .bronze: return "#CD7F32"
            }
        }
    }
}

// MARK: - Identifiable

extension RaceResult: Identifiable {
    /// Composite ID from race and athlete
    public var id: String {
        "\(raceID)-\(athlete.fisCode)"
    }
}

// MARK: - Hashable & Equatable

extension RaceResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(raceID)
        hasher.combine(athlete.fisCode)
    }
    
    public static func == (lhs: RaceResult, rhs: RaceResult) -> Bool {
        lhs.raceID == rhs.raceID && lhs.athlete.fisCode == rhs.athlete.fisCode
    }
}

// MARK: - Comparable

extension RaceResult: Comparable {
    /// Sort by rank (lower rank = better, DNF/DNS at end)
    public static func < (lhs: RaceResult, rhs: RaceResult) -> Bool {
        // Finished results come before DNF/DNS
        if lhs.status == .finished && rhs.status != .finished {
            return true
        }
        if lhs.status != .finished && rhs.status == .finished {
            return false
        }
        // Both finished or both DNF: sort by rank
        return lhs.rank < rhs.rank
    }
}

// MARK: - Time Formatting Helper

/// Format race time in seconds to display string
private func formatRaceTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let secs = seconds.truncatingRemainder(dividingBy: 60)
    
    if minutes > 0 {
        return String(format: "%d:%05.2f", minutes, secs)
    } else {
        return String(format: "%.2f", secs)
    }
}
