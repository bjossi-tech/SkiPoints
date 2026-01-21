import Foundation

enum PreviewData {
    
    // MARK: - Athletes
    
    static let odermatt = Athlete(
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
    
    static let franzoni = Athlete(
        fisCode: "6293831",
        firstName: "Giovanni",
        lastName: "FRANZONI",
        nation: "ITA",
        yearOfBirth: 2001,
        gender: .men,
        skiBrand: "Rossignol",
        currentFISPoints: 8.15
    )
    
    static let babinsky = Athlete(
        fisCode: "54371",
        firstName: "Stefan",
        lastName: "BABINSKY",
        nation: "AUT",
        yearOfBirth: 1996,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 12.45
    )
    
    static let vonAllmen = Athlete(
        fisCode: "512471",
        firstName: "Franjo",
        lastName: "VON ALLMEN",
        nation: "SUI",
        yearOfBirth: 2001,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 4.19
    )
    
    static let cochranSiegle = Athlete(
        fisCode: "6530319",
        firstName: "Ryan",
        lastName: "COCHRAN-SIEGLE",
        nation: "USA",
        yearOfBirth: 1992,
        gender: .men,
        skiBrand: "Head",
        currentFISPoints: 9.39
    )
    
    static let shiffrin = Athlete(
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
    
    static let goggia = Athlete(
        fisCode: "298323",
        firstName: "Sofia",
        lastName: "GOGGIA",
        nation: "ITA",
        yearOfBirth: 1992,
        gender: .women,
        skiBrand: "Atomic",
        currentFISPoints: 1.25
    )
    
    static let allAthletes: [Athlete] = [
        odermatt, franzoni, babinsky, vonAllmen, cochranSiegle, shiffrin, goggia
    ]
    
    // MARK: - Race Results (Wengen 2025 Super G)
    
    static let wengenResults: [RaceResult] = [
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
        )
    ]
    
    // MARK: - Races
    
    static let wengenSuperG = Race(
        id: "127380",
        codex: "0027",
        location: "Wengen",
        nation: "SUI",
        date: makeDate(year: 2025, month: 1, day: 17),
        eventType: .worldCup,
        discipline: .superG,
        gender: .men,
        status: .official,
        results: wengenResults
    )
    
    static let cortinaSuperG = Race(
        id: "127385",
        codex: "0032",
        location: "Cortina d'Ampezzo",
        nation: "ITA",
        date: Date(),
        eventType: .worldCup,
        discipline: .superG,
        gender: .women,
        status: .inProgress,
        results: []
    )
    
    static let kitzbuehelDownhill = Race(
        id: "127390",
        codex: "0041",
        location: "Kitzbühel",
        nation: "AUT",
        date: makeDate(year: 2025, month: 1, day: 25),
        eventType: .worldCup,
        discipline: .downhill,
        gender: .men,
        status: .scheduled,
        results: []
    )
    
    static let allRaces: [Race] = [
        cortinaSuperG,
        wengenSuperG,
        kitzbuehelDownhill
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
