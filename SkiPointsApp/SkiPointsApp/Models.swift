import Foundation

// MARK: - Athlete

struct Athlete: Identifiable, Codable, Hashable, Sendable {
    let fisCode: String
    let firstName: String
    let lastName: String
    let nation: String
    let yearOfBirth: Int
    let gender: Gender
    var fisPoints: [Discipline: Double] = [:]
    
    var id: String { fisCode }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        // FIS style: LASTNAME Firstname
        "\(lastName.uppercased()) \(firstName)"
    }
    
    var age: Int {
        Calendar.current.component(.year, from: Date()) - yearOfBirth
    }
    
    // Get FIS points for a specific discipline
    func points(for discipline: Discipline) -> Double {
        fisPoints[discipline] ?? 999.99
    }

    /// Short name format: "M. Odermatt"
    var shortName: String {
        guard let firstInitial = firstName.first else {
            return lastName
        }
        return "\(firstInitial). \(lastName)"
    }

    /// Flag emoji for the athlete's nation
    var flagEmoji: String {
        Self.flagEmoji(for: nation)
    }

    /// Current best FIS points across all disciplines
    var currentFISPoints: Double? {
        let validPoints = fisPoints.values.filter { $0 < 990 }
        return validPoints.min()
    }

    /// Ski brand (placeholder - would need to be fetched from athlete bio)
    var skiBrand: String? {
        // This would typically be fetched from athlete biography
        // Returning nil as placeholder
        nil
    }

    /// Convert nation code to flag emoji
    static func flagEmoji(for nationCode: String) -> String {
        let flagMap: [String: String] = [
            "SUI": "🇨🇭",
            "USA": "🇺🇸",
            "AUT": "🇦🇹",
            "NOR": "🇳🇴",
            "FRA": "🇫🇷",
            "ITA": "🇮🇹",
            "GER": "🇩🇪",
            "CAN": "🇨🇦",
            "SWE": "🇸🇪",
            "SLO": "🇸🇮",
            "CRO": "🇭🇷",
            "SVK": "🇸🇰",
            "CZE": "🇨🇿",
            "JPN": "🇯🇵",
            "GBR": "🇬🇧",
            "POL": "🇵🇱",
            "FIN": "🇫🇮",
            "BEL": "🇧🇪",
            "NED": "🇳🇱",
            "ESP": "🇪🇸",
            "AUS": "🇦🇺",
            "NZL": "🇳🇿",
            "CHN": "🇨🇳",
            "KOR": "🇰🇷",
            "RUS": "🇷🇺",
            "AND": "🇦🇩",
            "LIE": "🇱🇮",
            "GRE": "🇬🇷",
            "BRA": "🇧🇷",
            "ARG": "🇦🇷",
            "CHI": "🇨🇱",
            "MEX": "🇲🇽",
            "BUL": "🇧🇬",
            "ROU": "🇷🇴",
            "UKR": "🇺🇦",
            "BIH": "🇧🇦",
            "SRB": "🇷🇸",
            "MNE": "🇲🇪",
            "MKD": "🇲🇰",
            "ALB": "🇦🇱",
            "TUR": "🇹🇷",
            "ISR": "🇮🇱",
            "IND": "🇮🇳",
            "PAK": "🇵🇰",
            "IRI": "🇮🇷",
            "KAZ": "🇰🇿",
            "MON": "🇲🇨"
        ]
        return flagMap[nationCode.uppercased()] ?? "🏳️"
    }

    // Convenience initializer without FIS points
    init(fisCode: String, firstName: String, lastName: String, nation: String, yearOfBirth: Int, gender: Gender, fisPoints: [Discipline: Double] = [:]) {
        self.fisCode = fisCode
        self.firstName = firstName
        self.lastName = lastName
        self.nation = nation
        self.yearOfBirth = yearOfBirth
        self.gender = gender
        self.fisPoints = fisPoints
    }
    
    // Codable conformance for nested dictionary
    enum CodingKeys: String, CodingKey {
        case fisCode, firstName, lastName, nation, yearOfBirth, gender, fisPoints
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fisCode = try container.decode(String.self, forKey: .fisCode)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        nation = try container.decode(String.self, forKey: .nation)
        yearOfBirth = try container.decode(Int.self, forKey: .yearOfBirth)
        gender = try container.decode(Gender.self, forKey: .gender)
        
        // Decode dictionary with string keys
        if let pointsDict = try container.decodeIfPresent([String: Double].self, forKey: .fisPoints) {
            fisPoints = pointsDict.reduce(into: [:]) { result, pair in
                if let discipline = Discipline(rawValue: pair.key) {
                    result[discipline] = pair.value
                }
            }
        } else {
            fisPoints = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fisCode, forKey: .fisCode)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(nation, forKey: .nation)
        try container.encode(yearOfBirth, forKey: .yearOfBirth)
        try container.encode(gender, forKey: .gender)
        
        // Encode dictionary with string keys
        let pointsDict = fisPoints.reduce(into: [String: Double]()) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        try container.encode(pointsDict, forKey: .fisPoints)
    }
}

// MARK: - Race

struct Race: Identifiable, Codable, Hashable, Sendable {
    let id: String  // FIS event/race ID
    let codex: String
    let location: String
    let nation: String
    let date: Date
    let eventType: EventType
    let discipline: Discipline
    let gender: Gender
    var status: RaceStatus
    var results: [RaceResult]

    // MARK: - Cached DateFormatters (for performance)

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    var displayTitle: String {
        "\(location) - \(discipline.displayName)"
    }

    var formattedDate: String {
        Self.mediumDateFormatter.string(from: date)
    }

    var shortDate: String {
        Self.shortDateFormatter.string(from: date)
    }
    
    var isLive: Bool {
        status == .inProgress
    }
    
    var isFinished: Bool {
        status == .finished || status == .official
    }

    /// Flag emoji for the race nation
    var flagEmoji: String {
        Athlete.flagEmoji(for: nation)
    }

    /// Title combining discipline and gender: "Men's Giant Slalom"
    var title: String {
        "\(gender.displayName)'s \(discipline.displayName)"
    }

    /// Full location with nation: "Adelboden, SUI"
    var fullLocation: String {
        "\(location), \(nation)"
    }

    /// Top 3 results (podium finishers)
    var podium: [RaceResult] {
        results
            .filter { $0.status == .finished && $0.rank <= 3 }
            .sorted { $0.rank < $1.rank }
    }

    /// The race winner (first place finisher)
    var winner: RaceResult? {
        results.first { $0.status == .finished && $0.rank == 1 }
    }

    // Calculate penalty for this race (sum of best 5 FIS points)
    var calculatedPenalty: Double {
        // Filter to finished results with valid FIS points
        let finishedResults = results.filter { $0.status == .finished }
        
        // Get the 5 athletes with the best FIS points who started
        let bestFISPoints = finishedResults
            .compactMap { $0.athlete.points(for: discipline) }
            .filter { $0 < 990 }  // Exclude athletes without real FIS points
            .sorted()
            .prefix(5)
        
        guard bestFISPoints.count >= 5 else {
            // If less than 5 valid, use maximum penalty
            return 100.0  // Default high penalty
        }
        
        // Penalty = sum of best 5 FIS points divided by 5, multiplied by factor
        return bestFISPoints.reduce(0, +) / 5.0 * 0.75
    }
}

// MARK: - Race Result

struct RaceResult: Identifiable, Codable, Hashable, Sendable {
    let raceID: String
    var rank: Int
    let bib: Int
    let athlete: Athlete
    let timeSeconds: TimeInterval?
    let differenceSeconds: TimeInterval?
    var status: ResultStatus
    var fisPoints: Double
    let cupPoints: Int
    
    var id: String {
        "\(raceID)-\(athlete.fisCode)"
    }
    
    var formattedTime: String {
        guard let time = timeSeconds else {
            return status.displayText
        }
        
        let minutes = Int(time) / 60
        let seconds = time.truncatingRemainder(dividingBy: 60)
        
        if minutes > 0 {
            return String(format: "%d:%05.2f", minutes, seconds)
        } else {
            return String(format: "%.2f", seconds)
        }
    }
    
    var formattedDifference: String {
        guard let diff = differenceSeconds else {
            return ""
        }
        
        if diff == 0 {
            return ""
        }
        
        return String(format: "+%.2f", diff)
    }
    
    var formattedFISPoints: String {
        String(format: "%.2f", fisPoints)
    }

    /// Whether this result is a podium finish (rank 1-3)
    var isPodium: Bool {
        status == .finished && rank >= 1 && rank <= 3
    }

    /// Medal for podium finishers
    var medal: Medal? {
        guard status == .finished else { return nil }
        switch rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return nil
        }
    }

    /// Medal types for podium finishers
    enum Medal: String, CaseIterable, Sendable {
        case gold
        case silver
        case bronze

        var emoji: String {
            switch self {
            case .gold: return "🥇"
            case .silver: return "🥈"
            case .bronze: return "🥉"
            }
        }

        var color: String {
            switch self {
            case .gold: return "yellow"
            case .silver: return "gray"
            case .bronze: return "orange"
            }
        }
    }
}

// MARK: - Enums

enum Gender: String, Codable, CaseIterable, Hashable, Sendable {
    case men = "M"
    case women = "W"
    
    var displayName: String {
        switch self {
        case .men: return "Men"
        case .women: return "Women"
        }
    }
    
    var symbol: String {
        switch self {
        case .men: return "♂"
        case .women: return "♀"
        }
    }
}

enum Discipline: String, Codable, CaseIterable, Hashable, Sendable {
    case downhill = "DH"
    case superG = "SG"
    case giantSlalom = "GS"
    case slalom = "SL"
    case combined = "AC"
    case parallelSlalom = "PSL"
    
    var displayName: String {
        switch self {
        case .downhill: return "Downhill"
        case .superG: return "Super G"
        case .giantSlalom: return "Giant Slalom"
        case .slalom: return "Slalom"
        case .combined: return "Combined"
        case .parallelSlalom: return "Parallel Slalom"
        }
    }
    
    var shortName: String {
        rawValue
    }

    /// SF Symbol icon name for the discipline
    var iconName: String {
        switch self {
        case .downhill: return "arrow.down.circle.fill"
        case .superG: return "bolt.circle.fill"
        case .giantSlalom: return "chevron.down.circle.fill"
        case .slalom: return "arrow.left.arrow.right.circle.fill"
        case .combined: return "plus.circle.fill"
        case .parallelSlalom: return "arrow.left.and.right.circle.fill"
        }
    }

    var fFactor: Double {
        switch self {
        case .downhill: return 1330.0
        case .superG: return 1190.0
        case .giantSlalom: return 1010.0
        case .slalom: return 730.0
        case .combined: return 1360.0
        case .parallelSlalom: return 730.0
        }
    }
}

enum EventType: String, Codable, CaseIterable, Hashable, Sendable {
    case worldCup = "WC"
    case europaCup = "EC"
    case norAmCup = "NAC"
    case fis = "FIS"
    case junior = "NJR"
    case worldChampionships = "WSC"
    case olympics = "OWG"
    case nationalChampionships = "NC"
    
    var displayName: String {
        switch self {
        case .worldCup: return "World Cup"
        case .europaCup: return "Europa Cup"
        case .norAmCup: return "Nor-Am Cup"
        case .fis: return "FIS"
        case .junior: return "Junior"
        case .worldChampionships: return "World Championships"
        case .olympics: return "Olympics"
        case .nationalChampionships: return "National Championships"
        }
    }
    
    var shortName: String {
        rawValue
    }
    
    var priority: Int {
        switch self {
        case .olympics: return 1
        case .worldChampionships: return 2
        case .worldCup: return 3
        case .europaCup: return 4
        case .norAmCup: return 5
        case .fis: return 6
        case .junior: return 7
        case .nationalChampionships: return 8
        }
    }
}

enum RaceStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case scheduled = "SCHEDULED"
    case inProgress = "LIVE"
    case finished = "FINISHED"
    case official = "OFFICIAL"
    case cancelled = "CANCELLED"
    case postponed = "POSTPONED"
    
    var displayText: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "Live"
        case .finished: return "Finished"
        case .official: return "Official"
        case .cancelled: return "Cancelled"
        case .postponed: return "Postponed"
        }
    }

    /// Short abbreviated name for the status
    var shortName: String {
        switch self {
        case .scheduled: return "SCH"
        case .inProgress: return "LIVE"
        case .finished: return "FIN"
        case .official: return "OFF"
        case .cancelled: return "CAN"
        case .postponed: return "PPD"
        }
    }

    /// Whether this race is currently live
    var isLive: Bool {
        self == .inProgress
    }

    var isActive: Bool {
        self == .inProgress
    }
    
    var isComplete: Bool {
        self == .finished || self == .official
    }
}

enum ResultStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case finished = "FIN"
    case didNotFinish = "DNF"
    case didNotStart = "DNS"
    case disqualified = "DSQ"
    case notQualified = "NQ"
    
    var displayText: String {
        switch self {
        case .finished: return ""
        case .didNotFinish: return "DNF"
        case .didNotStart: return "DNS"
        case .disqualified: return "DSQ"
        case .notQualified: return "NQ"
        }
    }
    
    var isClassified: Bool {
        self == .finished
    }
}

// MARK: - FIS Points Calculator

struct FISPointsCalculator {
    
    /// Calculate race points using the official FIS formula
    /// Race Points = ((Athlete Time - Winner Time) / Winner Time) × F-Factor
    static func calculateRacePoints(
        athleteTime: TimeInterval,
        winnerTime: TimeInterval,
        discipline: Discipline
    ) -> Double {
        guard winnerTime > 0, athleteTime >= winnerTime else {
            return 0.0
        }
        
        let timeDiff = athleteTime - winnerTime
        let percentage = timeDiff / winnerTime
        let racePoints = percentage * discipline.fFactor
        
        return max(0.0, round(racePoints * 100) / 100)
    }
    
    /// Calculate FIS points including race penalty
    /// FIS Points = Race Points + Penalty
    static func calculateFISPoints(
        racePoints: Double,
        penalty: Double
    ) -> Double {
        return max(0.0, racePoints + penalty)
    }
    
    /// Calculate race penalty from starting field
    /// Penalty = (Sum of best 5 FIS points among starters) / 5 × 0.75 + (Sum of best 5 race points among top 10) / 5
    static func calculatePenalty(
        startersFISPoints: [Double],
        top10RacePoints: [Double]
    ) -> Double {
        // Component A: Best 5 FIS points among starters
        let bestFISPoints = startersFISPoints
            .filter { $0 < 990 }
            .sorted()
            .prefix(5)
        
        let componentA: Double
        if bestFISPoints.count >= 5 {
            componentA = bestFISPoints.reduce(0, +) / 5.0 * 0.75
        } else {
            componentA = 50.0  // Default if not enough valid FIS points
        }
        
        // Component B: Best 5 race points among top 10
        let bestRacePoints = top10RacePoints
            .sorted()
            .prefix(5)
        
        let componentB: Double
        if bestRacePoints.count >= 5 {
            componentB = bestRacePoints.reduce(0, +) / 5.0
        } else {
            componentB = 0.0
        }
        
        // Total penalty (with minimum of 0)
        let penalty = componentA + componentB
        return max(0.0, round(penalty * 100) / 100)
    }
}
