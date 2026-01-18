import Foundation

/// Represents a ski race event.
///
/// Contains all metadata about the race (location, discipline, etc.)
/// and optionally the full results list.
///
/// ## Example
/// ```swift
/// let race = Race(
///     id: "127380",
///     codex: "0027",
///     location: "Wengen",
///     nation: "SUI",
///     date: Date(),
///     eventType: .worldCup,
///     discipline: .superG,
///     gender: .men,
///     status: .official
/// )
/// ```
public struct Race: Codable, Sendable {
    
    // MARK: - Identification
    
    /// Unique FIS race ID
    public let id: String
    
    /// Race codex number
    public let codex: String
    
    // MARK: - Location
    
    /// Location/resort name
    public let location: String
    
    /// Host nation (3-letter code)
    public let nation: String
    
    // MARK: - Event Details
    
    /// Race date
    public let date: Date
    
    /// Event category (World Cup, FIS, etc.)
    public let eventType: EventType
    
    /// Racing discipline
    public let discipline: Discipline
    
    /// Gender category
    public let gender: Gender
    
    /// Current race status
    public var status: RaceStatus
    
    // MARK: - Course Information
    
    /// Vertical drop in meters
    public var verticalDrop: Int?
    
    /// Course length in meters
    public var courseLength: Int?
    
    /// Number of gates
    public var gateCount: Int?
    
    /// Start altitude in meters
    public var startAltitude: Int?
    
    /// Finish altitude in meters
    public var finishAltitude: Int?
    
    // MARK: - Race Penalty
    
    /// Race penalty for FIS points calculation
    public var racePenalty: Double
    
    // MARK: - Results
    
    /// All race results, sorted by rank
    public var results: [RaceResult]
    
    // MARK: - Initialization
    
    public init(
        id: String,
        codex: String,
        location: String,
        nation: String,
        date: Date,
        eventType: EventType,
        discipline: Discipline,
        gender: Gender,
        status: RaceStatus,
        verticalDrop: Int? = nil,
        courseLength: Int? = nil,
        gateCount: Int? = nil,
        startAltitude: Int? = nil,
        finishAltitude: Int? = nil,
        racePenalty: Double = 0.0,
        results: [RaceResult] = []
    ) {
        self.id = id
        self.codex = codex
        self.location = location
        self.nation = nation
        self.date = date
        self.eventType = eventType
        self.discipline = discipline
        self.gender = gender
        self.status = status
        self.verticalDrop = verticalDrop
        self.courseLength = courseLength
        self.gateCount = gateCount
        self.startAltitude = startAltitude
        self.finishAltitude = finishAltitude
        self.racePenalty = racePenalty
        self.results = results
    }
    
    // MARK: - Computed Properties
    
    /// Race title: "Men's Super G"
    public var title: String {
        "\(gender.possessive) \(discipline.displayName)"
    }
    
    /// Full title with event type: "World Cup Men's Super G"
    public var fullTitle: String {
        "\(eventType.displayName) \(title)"
    }
    
    /// Location with nation: "Wengen (SUI)"
    public var fullLocation: String {
        "\(location) (\(nation))"
    }
    
    /// Flag emoji for host nation
    public var flagEmoji: String {
        nationToFlagEmoji(nation)
    }
    
    /// Whether race is currently live
    public var isLive: Bool {
        status.isLive
    }
    
    /// Whether results are available
    public var hasResults: Bool {
        status.hasResults && !results.isEmpty
    }
    
    /// Whether this has course info
    public var courseInfo: Bool {
        verticalDrop != nil || courseLength != nil || gateCount != nil
    }
    
    /// URL to FIS results page
    public var fisResultsURL: URL? {
        URL(string: "https://www.fis-ski.com/DB/general/results.html?sectorcode=AL&raceid=\(id)")
    }
    
    // MARK: - Results Helpers
    
    /// Race winner (rank 1 result)
    public var winner: RaceResult? {
        results.first { $0.rank == 1 && $0.status == .finished }
    }
    
    /// Podium results (ranks 1-3)
    public var podium: [RaceResult] {
        results.filter { $0.rank <= 3 && $0.status == .finished }
            .sorted { $0.rank < $1.rank }
    }
    
    /// All finished results
    public var finishedResults: [RaceResult] {
        results.filter { $0.status == .finished }
            .sorted { $0.rank < $1.rank }
    }
    
    /// DNF results
    public var dnfResults: [RaceResult] {
        results.filter { $0.status == .didNotFinish }
    }
    
    /// DNS results
    public var dnsResults: [RaceResult] {
        results.filter { $0.status == .didNotStart }
    }
    
    /// DSQ results
    public var dsqResults: [RaceResult] {
        results.filter { $0.status == .disqualified }
    }
    
    /// Winner's time in seconds
    public var winnerTime: TimeInterval? {
        winner?.timeSeconds
    }
}

// MARK: - Identifiable

extension Race: Identifiable {}

// MARK: - Hashable & Equatable

extension Race: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Race, rhs: Race) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Helper

private func nationToFlagEmoji(_ code: String) -> String {
    let codeMap: [String: String] = [
        "SUI": "CH", "AUT": "AT", "GER": "DE", "FRA": "FR",
        "ITA": "IT", "USA": "US", "CAN": "CA", "NOR": "NO",
        "SWE": "SE", "SLO": "SI", "CZE": "CZ", "JPN": "JP",
        "GBR": "GB", "ESP": "ES", "POL": "PL", "FIN": "FI",
        "ISL": "IS"
    ]
    
    let alpha2 = codeMap[code.uppercased()] ?? code.prefix(2).uppercased()
    let base: UInt32 = 127397
    var flag = ""
    for scalar in alpha2.prefix(2).unicodeScalars {
        if let flagScalar = UnicodeScalar(base + scalar.value) {
            flag.append(Character(flagScalar))
        }
    }
    return flag.isEmpty ? "🏳️" : flag
}
