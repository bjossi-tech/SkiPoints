import Foundation

// MARK: - Enums

enum Discipline: String, Codable, CaseIterable {
    case downhill = "DH"
    case superG = "SG"
    case giantSlalom = "GS"
    case slalom = "SL"
    
    var displayName: String {
        switch self {
        case .downhill: return "Downhill"
        case .superG: return "Super G"
        case .giantSlalom: return "Giant Slalom"
        case .slalom: return "Slalom"
        }
    }
    
    var iconName: String {
        switch self {
        case .downhill: return "arrow.down.circle.fill"
        case .superG: return "bolt.circle.fill"
        case .giantSlalom: return "figure.skiing.downhill"
        case .slalom: return "point.topleft.down.to.point.bottomright.curvepath.fill"
        }
    }
    
    var fisPointsFactor: Double {
        switch self {
        case .downhill: return 1330.0
        case .superG: return 1190.0
        case .giantSlalom: return 1010.0
        case .slalom: return 730.0
        }
    }
}

enum EventType: String, Codable, CaseIterable {
    case worldCup = "WC"
    case europaCup = "EC"
    case fis = "FIS"
    
    var displayName: String {
        switch self {
        case .worldCup: return "World Cup"
        case .europaCup: return "Europa Cup"
        case .fis: return "FIS Race"
        }
    }
    
    var shortName: String {
        rawValue
    }
}

enum Gender: String, Codable {
    case men = "M"
    case women = "W"
    
    var possessive: String {
        switch self {
        case .men: return "Men's"
        case .women: return "Women's"
        }
    }
}

enum RaceStatus: String, Codable, Comparable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case finished = "Finished"
    case official = "Official"
    case cancelled = "Cancelled"
    
    var isLive: Bool {
        self == .inProgress
    }
    
    var shortName: String {
        switch self {
        case .scheduled: return "SCHED"
        case .inProgress: return "LIVE"
        case .finished: return "UNOFF"
        case .official: return "FINAL"
        case .cancelled: return "CANC"
        }
    }
    
    static func < (lhs: RaceStatus, rhs: RaceStatus) -> Bool {
        let order: [RaceStatus] = [.inProgress, .scheduled, .finished, .official, .cancelled]
        let lhsIndex = order.firstIndex(of: lhs) ?? 0
        let rhsIndex = order.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }
}

enum ResultStatus: String, Codable {
    case finished = "FIN"
    case didNotFinish = "DNF"
    case didNotStart = "DNS"
    case disqualified = "DSQ"
    
    var shortCode: String { rawValue }
}

// MARK: - Athlete

struct Athlete: Identifiable, Codable, Hashable {
    let fisCode: String
    let firstName: String
    let lastName: String
    let nation: String
    let yearOfBirth: Int
    let gender: Gender
    var skiBrand: String?
    var currentFISPoints: Double?
    var worldCupRank: Int?
    
    var id: String { fisCode }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var shortName: String {
        "\(firstName.prefix(1)). \(lastName)"
    }
    
    var age: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - yearOfBirth
    }
    
    var flagEmoji: String {
        let codeMap: [String: String] = [
            "SUI": "CH", "AUT": "AT", "GER": "DE", "FRA": "FR",
            "ITA": "IT", "USA": "US", "CAN": "CA", "NOR": "NO",
            "SWE": "SE", "SLO": "SI", "CZE": "CZ"
        ]
        let alpha2 = codeMap[nation.uppercased()] ?? String(nation.prefix(2)).uppercased()
        let base: UInt32 = 127397
        var flag = ""
        for scalar in alpha2.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                flag.append(Character(flagScalar))
            }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
    
    static func == (lhs: Athlete, rhs: Athlete) -> Bool {
        lhs.fisCode == rhs.fisCode
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fisCode)
    }
}

// MARK: - Race

struct Race: Identifiable, Codable, Hashable {
    let id: String
    let codex: String
    let location: String
    let nation: String
    let date: Date
    let eventType: EventType
    let discipline: Discipline
    let gender: Gender
    var status: RaceStatus
    var results: [RaceResult]
    
    var title: String {
        "\(gender.possessive) \(discipline.displayName)"
    }
    
    var fullLocation: String {
        "\(location) (\(nation))"
    }
    
    var flagEmoji: String {
        let codeMap: [String: String] = [
            "SUI": "CH", "AUT": "AT", "GER": "DE", "FRA": "FR",
            "ITA": "IT", "USA": "US"
        ]
        let alpha2 = codeMap[nation.uppercased()] ?? String(nation.prefix(2)).uppercased()
        let base: UInt32 = 127397
        var flag = ""
        for scalar in alpha2.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                flag.append(Character(flagScalar))
            }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
    
    var isLive: Bool { status.isLive }
    
    var winner: RaceResult? {
        results.first { $0.rank == 1 && $0.status == .finished }
    }
    
    var podium: [RaceResult] {
        results.filter { $0.rank <= 3 && $0.status == .finished }.sorted { $0.rank < $1.rank }
    }
    
    static func == (lhs: Race, rhs: Race) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - RaceResult

struct RaceResult: Identifiable, Codable, Hashable {
    let raceID: String
    let rank: Int
    let bib: Int
    let athlete: Athlete
    let timeSeconds: TimeInterval?
    let differenceSeconds: TimeInterval?
    let status: ResultStatus
    var fisPoints: Double
    var cupPoints: Int
    
    var id: String { "\(raceID)-\(athlete.fisCode)" }
    
    var formattedTime: String {
        guard let time = timeSeconds else { return status.shortCode }
        let minutes = Int(time) / 60
        let secs = time.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            return String(format: "%d:%05.2f", minutes, secs)
        }
        return String(format: "%.2f", secs)
    }
    
    var formattedDiff: String {
        guard let diff = differenceSeconds, diff > 0 else { return "" }
        return String(format: "+%.2f", diff)
    }
    
    var formattedFISPoints: String {
        String(format: "%.2f", fisPoints)
    }
    
    var isPodium: Bool {
        rank >= 1 && rank <= 3 && status == .finished
    }
    
    var medal: Medal? {
        guard status == .finished else { return nil }
        switch rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return nil
        }
    }
    
    enum Medal: String {
        case gold, silver, bronze
        
        var emoji: String {
            switch self {
            case .gold: return "🥇"
            case .silver: return "🥈"
            case .bronze: return "🥉"
            }
        }
    }
}

// MARK: - FIS Points Calculator

struct FISPointsCalculator {
    func calculatePoints(raceTime: TimeInterval, winnerTime: TimeInterval, discipline: Discipline, penalty: Double = 0) -> Double? {
        guard winnerTime > 0, raceTime >= winnerTime else { return nil }
        let factor = discipline.fisPointsFactor
        let timeDiff = raceTime - winnerTime
        let points = (timeDiff / winnerTime) * factor + penalty
        return max(0, (points * 100).rounded() / 100)
    }
    
    static let worldCupPointsDistribution: [Int: Int] = [
        1: 100, 2: 80, 3: 60, 4: 50, 5: 45,
        6: 40, 7: 36, 8: 32, 9: 29, 10: 26,
        11: 24, 12: 22, 13: 20, 14: 18, 15: 16,
        16: 15, 17: 14, 18: 13, 19: 12, 20: 11,
        21: 10, 22: 9, 23: 8, 24: 7, 25: 6,
        26: 5, 27: 4, 28: 3, 29: 2, 30: 1
    ]
}
