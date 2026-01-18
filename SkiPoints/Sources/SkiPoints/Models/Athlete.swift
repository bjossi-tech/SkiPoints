import Foundation

/// Represents a ski racer/athlete.
///
/// Contains biographical data and identification used throughout the app.
///
/// ## Example
/// ```swift
/// let odermatt = Athlete(
///     fisCode: "512269",
///     firstName: "Marco",
///     lastName: "ODERMATT",
///     nation: "SUI",
///     yearOfBirth: 1997,
///     gender: .men,
///     skiBrand: "Stoeckli"
/// )
/// print(odermatt.fullName)    // "Marco ODERMATT"
/// print(odermatt.flagEmoji)   // "🇨🇭"
/// ```
public struct Athlete: Codable, Sendable {
    
    // MARK: - Core Properties
    
    /// Unique FIS competitor ID
    public let fisCode: String
    
    /// First name(s)
    public let firstName: String
    
    /// Last name (typically uppercase in FIS data)
    public let lastName: String
    
    /// 3-letter nation code (IOC format)
    public let nation: String
    
    /// Year of birth
    public let yearOfBirth: Int
    
    /// Gender category
    public let gender: Gender
    
    // MARK: - Optional Properties
    
    /// Ski equipment brand (e.g., "Atomic", "Head")
    public let skiBrand: String?
    
    /// Current FIS points (best 2 results)
    public var currentFISPoints: Double?
    
    /// Current World Cup ranking
    public var worldCupRank: Int?
    
    // MARK: - Initialization
    
    public init(
        fisCode: String,
        firstName: String,
        lastName: String,
        nation: String,
        yearOfBirth: Int,
        gender: Gender,
        skiBrand: String? = nil,
        currentFISPoints: Double? = nil,
        worldCupRank: Int? = nil
    ) {
        self.fisCode = fisCode
        self.firstName = firstName
        self.lastName = lastName
        self.nation = nation
        self.yearOfBirth = yearOfBirth
        self.gender = gender
        self.skiBrand = skiBrand
        self.currentFISPoints = currentFISPoints
        self.worldCupRank = worldCupRank
    }
    
    // MARK: - Computed Properties
    
    /// Full name: "Marco ODERMATT"
    public var fullName: String {
        if firstName.isEmpty {
            return lastName
        }
        return "\(firstName) \(lastName)"
    }
    
    /// Short name: "M. ODERMATT"
    public var shortName: String {
        if firstName.isEmpty {
            return lastName
        }
        let initial = firstName.prefix(1)
        return "\(initial). \(lastName)"
    }
    
    /// Full name in FIS format: "ODERMATT Marco"
    public var fisFormatName: String {
        if firstName.isEmpty {
            return lastName
        }
        return "\(lastName) \(firstName)"
    }
    
    /// Current age based on year of birth
    public var age: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - yearOfBirth
    }
    
    /// URL to athlete's FIS biography page
    public var fisProfileURL: URL? {
        URL(string: "https://www.fis-ski.com/DB/general/athlete-biography.html?sectorcode=al&competitorid=\(fisCode)")
    }
    
    /// Flag emoji for nation
    public var flagEmoji: String {
        nationToFlagEmoji(nation)
    }
}

// MARK: - Identifiable

extension Athlete: Identifiable {
    /// Uses FIS code as unique identifier
    public var id: String { fisCode }
}

// MARK: - Hashable & Equatable

extension Athlete: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fisCode)
    }
    
    public static func == (lhs: Athlete, rhs: Athlete) -> Bool {
        lhs.fisCode == rhs.fisCode
    }
}

// MARK: - CustomStringConvertible

extension Athlete: CustomStringConvertible {
    public var description: String {
        "\(fullName) (\(nation), \(yearOfBirth))"
    }
}

// MARK: - Helper Functions

/// Convert 3-letter nation code to flag emoji
private func nationToFlagEmoji(_ code: String) -> String {
    // Map common skiing nation codes to ISO 3166-1 alpha-2
    let codeMap: [String: String] = [
        "SUI": "CH", "AUT": "AT", "GER": "DE", "FRA": "FR",
        "ITA": "IT", "USA": "US", "CAN": "CA", "NOR": "NO",
        "SWE": "SE", "SLO": "SI", "CZE": "CZ", "JPN": "JP",
        "GBR": "GB", "ESP": "ES", "POL": "PL", "FIN": "FI",
        "BEL": "BE", "NED": "NL", "AUS": "AU", "NZL": "NZ",
        "CHI": "CL", "ARG": "AR", "BRA": "BR", "CRO": "HR",
        "SVK": "SK", "ROU": "RO", "BUL": "BG", "GRE": "GR",
        "KOR": "KR", "CHN": "CN", "RUS": "RU", "UKR": "UA",
        "AND": "AD", "LIE": "LI", "MON": "MC", "EST": "EE",
        "LAT": "LV", "LTU": "LT", "MDA": "MD", "BIH": "BA",
        "SRB": "RS", "MNE": "ME", "MKD": "MK", "ALB": "AL",
        "ISL": "IS"
    ]
    
    let alpha2 = codeMap[code.uppercased()] ?? code.prefix(2).uppercased()
    
    // Convert to regional indicator symbols
    let base: UInt32 = 127397
    var flag = ""
    for scalar in alpha2.prefix(2).unicodeScalars {
        if let flagScalar = UnicodeScalar(base + scalar.value) {
            flag.append(Character(flagScalar))
        }
    }
    return flag.isEmpty ? "🏳️" : flag
}
