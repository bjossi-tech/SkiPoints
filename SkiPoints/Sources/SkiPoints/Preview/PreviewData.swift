import Foundation

/// Preview data for SwiftUI development.
///
/// Based on real FIS race results for accuracy.
///
/// ## Usage
/// ```swift
/// #Preview {
///     RaceDetailView(race: PreviewData.wengenSuperG)
/// }
/// ```
public enum PreviewData {
    
    // MARK: - Athletes
    
    public static let odermatt = Athlete(
        fisCode: "512269",
        firstName: "Marco",
        lastName: "ODERMATT",
        nation: "SUI",
        yearOfBirth: 1997,
        gender: .men,
        skiBrand: "Stöckli",
        currentFISPoints: 0.00,
        worldCupRank: 1
    )
    
    public static let franzoni = Athlete(
        fisCode: "6293831",
        firstName: "Giovanni",
        lastName: "FRANZONI",
        nation: "ITA",
        yearOfBirth: 2001,
        gender: .men,
        skiBrand: "Rossignol",
        currentFISPoints: 8.15
    )
    
    public static let babinsky = Athlete(
        fisCode: "54371",
        firstName: "Stefan",
        lastName: "BABINSKY",
        nation: "AUT",
        yearOfBirth: 1996,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 12.45
    )
    
    public static let vonAllmen = Athlete(
        fisCode: "512471",
        firstName: "Franjo",
        lastName: "VON ALLMEN",
        nation: "SUI",
        yearOfBirth: 2001,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 4.19
    )
    
    public static let cochranSiegle = Athlete(
        fisCode: "6530319",
        firstName: "Ryan",
        lastName: "COCHRAN-SIEGLE",
        nation: "USA",
        yearOfBirth: 1992,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 9.39
    )
    
    public static let casse = Athlete(
        fisCode: "990081",
        firstName: "Mattia",
        lastName: "CASSE",
        nation: "ITA",
        yearOfBirth: 1990,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 11.43
    )
    
    public static let kriechmayr = Athlete(
        fisCode: "53980",
        firstName: "Vincent",
        lastName: "KRIECHMAYR",
        nation: "AUT",
        yearOfBirth: 1991,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 14.48
    )
    
    public static let paris = Athlete(
        fisCode: "291459",
        firstName: "Dominik",
        lastName: "PARIS",
        nation: "ITA",
        yearOfBirth: 1989,
        gender: .men,
        skiBrand: "Nordica",
        currentFISPoints: 5.12
    )
    
    public static let shiffrin = Athlete(
        fisCode: "539909",
        firstName: "Mikaela",
        lastName: "SHIFFRIN",
        nation: "USA",
        yearOfBirth: 1995,
        gender: .women,
        skiBrand: "Atomic",
        currentFISPoints: 0.00,
        worldCupRank: 1
    )
    
    public static let goggia = Athlete(
        fisCode: "298323",
        firstName: "Sofia",
        lastName: "GOGGIA",
        nation: "ITA",
        yearOfBirth: 1992,
        gender: .women,
        skiBrand: "Atomic",
        currentFISPoints: 1.25
    )
    
    /// Collection of sample athletes
    public static let allAthletes: [Athlete] = [
        odermatt, franzoni, babinsky, vonAllmen,
        cochranSiegle, casse, kriechmayr, paris,
        shiffrin, goggia
    ]
    
    // MARK: - Race Results (Wengen 2025 Super G)
    
    public static let wengenResults: [RaceResult] = [
        RaceResult(
            raceID: "127380",
            rank: 1,
            bib: 10,
            athlete: franzoni,
            timeSeconds: 105.19,
            differenceSeconds: 0,
            status: .finished,
            fisPoints: 0.0,
            cupPoints: 100
        ),
        RaceResult(
            raceID: "127380",
            rank: 2,
            bib: 6,
            athlete: babinsky,
            timeSeconds: 105.54,
            differenceSeconds: 0.35,
            status: .finished,
            fisPoints: 3.96,
            cupPoints: 80
        ),
        RaceResult(
            raceID: "127380",
            rank: 3,
            bib: 8,
            athlete: vonAllmen,
            timeSeconds: 105.56,
            differenceSeconds: 0.37,
            status: .finished,
            fisPoints: 4.19,
            cupPoints: 60
        ),
        RaceResult(
            raceID: "127380",
            rank: 4,
            bib: 12,
            athlete: odermatt,
            timeSeconds: 105.72,
            differenceSeconds: 0.53,
            status: .finished,
            fisPoints: 6.00,
            cupPoints: 50
        ),
        RaceResult(
            raceID: "127380",
            rank: 5,
            bib: 17,
            athlete: cochranSiegle,
            timeSeconds: 106.02,
            differenceSeconds: 0.83,
            status: .finished,
            fisPoints: 9.39,
            cupPoints: 45
        ),
        RaceResult(
            raceID: "127380",
            rank: 6,
            bib: 2,
            athlete: casse,
            timeSeconds: 106.20,
            differenceSeconds: 1.01,
            status: .finished,
            fisPoints: 11.43,
            cupPoints: 40
        ),
        RaceResult(
            raceID: "127380",
            rank: 7,
            bib: 7,
            athlete: kriechmayr,
            timeSeconds: 106.47,
            differenceSeconds: 1.28,
            status: .finished,
            fisPoints: 14.48,
            cupPoints: 36
        ),
        RaceResult(
            raceID: "127380",
            rank: 8,
            bib: 3,
            athlete: paris,
            timeSeconds: 106.65,
            differenceSeconds: 1.46,
            status: .finished,
            fisPoints: 16.52,
            cupPoints: 32
        )
    ]
    
    // MARK: - Races
    
    /// Wengen Super G - Official Results
    public static let wengenSuperG = Race(
        id: "127380",
        codex: "0027",
        location: "Wengen",
        nation: "SUI",
        date: makeDate(year: 2025, month: 1, day: 17),
        eventType: .worldCup,
        discipline: .superG,
        gender: .men,
        status: .official,
        verticalDrop: 590,
        courseLength: 2480,
        gateCount: 42,
        startAltitude: 2200,
        finishAltitude: 1610,
        racePenalty: 0.0,
        results: wengenResults
    )
    
    /// Cortina Super G - Live Race (simulated)
    public static let cortinaSuperG = Race(
        id: "127385",
        codex: "0032",
        location: "Cortina d'Ampezzo",
        nation: "ITA",
        date: Date(),
        eventType: .worldCup,
        discipline: .superG,
        gender: .women,
        status: .inProgress,
        verticalDrop: 740,
        courseLength: 2100,
        gateCount: 38,
        racePenalty: 0.0,
        results: []
    )
    
    /// Kitzbühel Downhill - Scheduled
    public static let kitzbuehelDownhill = Race(
        id: "127390",
        codex: "0041",
        location: "Kitzbühel",
        nation: "AUT",
        date: makeDate(year: 2025, month: 1, day: 25),
        eventType: .worldCup,
        discipline: .downhill,
        gender: .men,
        status: .scheduled,
        verticalDrop: 860,
        courseLength: 3312,
        gateCount: 47,
        startAltitude: 1665,
        finishAltitude: 805,
        racePenalty: 0.0,
        results: []
    )
    
    /// Collection of sample races
    public static let allRaces: [Race] = [
        cortinaSuperG,   // Live first
        wengenSuperG,    // Official
        kitzbuehelDownhill // Scheduled
    ]
    
    // MARK: - Helper
    
    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 10
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Model Extensions for Preview

extension Race {
    /// Preview race for SwiftUI
    public static var preview: Race {
        PreviewData.wengenSuperG
    }
    
    /// Preview races array
    public static var previewRaces: [Race] {
        PreviewData.allRaces
    }
}

extension Athlete {
    /// Preview athlete for SwiftUI
    public static var preview: Athlete {
        PreviewData.odermatt
    }
    
    /// Preview athletes array
    public static var previewAthletes: [Athlete] {
        PreviewData.allAthletes
    }
}

extension RaceResult {
    /// Preview result for SwiftUI
    public static var preview: RaceResult {
        PreviewData.wengenResults[0]
    }
    
    /// Preview results array
    public static var previewResults: [RaceResult] {
        PreviewData.wengenResults
    }
}
