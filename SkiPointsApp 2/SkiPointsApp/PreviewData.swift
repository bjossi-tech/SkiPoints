import Foundation

/// Preview data for SwiftUI previews and DEBUG fallback
struct PreviewData {
    
    // MARK: - Sample Athletes
    
    static let athletes: [Athlete] = [
        Athlete(
            fisCode: "561244",
            firstName: "Marco",
            lastName: "Odermatt",
            nation: "SUI",
            yearOfBirth: 1997,
            gender: .men,
            fisPoints: [
                .giantSlalom: 0.0,
                .superG: 0.0,
                .downhill: 0.35,
                .slalom: 25.50
            ]
        ),
        Athlete(
            fisCode: "422403",
            firstName: "Henrik",
            lastName: "Kristoffersen",
            nation: "NOR",
            yearOfBirth: 1994,
            gender: .men,
            fisPoints: [
                .giantSlalom: 0.0,
                .slalom: 0.0,
                .superG: 15.20
            ]
        ),
        Athlete(
            fisCode: "6190403",
            firstName: "Loic",
            lastName: "Meillard",
            nation: "SUI",
            yearOfBirth: 1996,
            gender: .men,
            fisPoints: [
                .giantSlalom: 0.0,
                .slalom: 0.0,
                .superG: 4.50
            ]
        ),
        Athlete(
            fisCode: "194495",
            firstName: "Alexis",
            lastName: "Pinturault",
            nation: "FRA",
            yearOfBirth: 1991,
            gender: .men,
            fisPoints: [
                .giantSlalom: 0.0,
                .slalom: 3.25,
                .superG: 8.10
            ]
        ),
        Athlete(
            fisCode: "56388",
            firstName: "Manuel",
            lastName: "Feller",
            nation: "AUT",
            yearOfBirth: 1992,
            gender: .men,
            fisPoints: [
                .slalom: 0.0,
                .giantSlalom: 12.80
            ]
        ),
        // Women athletes
        Athlete(
            fisCode: "539909",
            firstName: "Mikaela",
            lastName: "Shiffrin",
            nation: "USA",
            yearOfBirth: 1995,
            gender: .women,
            fisPoints: [
                .slalom: 0.0,
                .giantSlalom: 0.0,
                .superG: 2.50,
                .downhill: 8.75
            ]
        ),
        Athlete(
            fisCode: "297601",
            firstName: "Federica",
            lastName: "Brignone",
            nation: "ITA",
            yearOfBirth: 1990,
            gender: .women,
            fisPoints: [
                .giantSlalom: 0.0,
                .superG: 0.0,
                .downhill: 5.20
            ]
        ),
        Athlete(
            fisCode: "425929",
            firstName: "Ragnhild",
            lastName: "Mowinckel",
            nation: "NOR",
            yearOfBirth: 1992,
            gender: .women,
            fisPoints: [
                .giantSlalom: 2.30,
                .superG: 0.85,
                .downhill: 0.0
            ]
        ),
    ]
    
    // MARK: - Sample Results
    
    static func makeResults(for raceID: String, discipline: Discipline) -> [RaceResult] {
        let selectedAthletes = discipline == .slalom || discipline == .giantSlalom
            ? athletes.filter { $0.gender == .men }
            : athletes.filter { $0.gender == .men }.prefix(5)
        
        var results: [RaceResult] = []
        var currentTime: TimeInterval = 65.50  // Winner time in seconds
        
        for (index, athlete) in selectedAthletes.enumerated() {
            let rank = index + 1
            let timeVariation = Double(index) * 0.35 + Double.random(in: 0...0.2)
            let athleteTime = currentTime + timeVariation
            
            let racePoints = FISPointsCalculator.calculateRacePoints(
                athleteTime: athleteTime,
                winnerTime: currentTime,
                discipline: discipline
            )
            
            let result = RaceResult(
                raceID: raceID,
                rank: rank,
                bib: rank + 5,
                athlete: athlete,
                timeSeconds: athleteTime,
                differenceSeconds: rank == 1 ? nil : athleteTime - currentTime,
                status: .finished,
                fisPoints: racePoints + 5.0,  // Add approximate penalty
                cupPoints: max(0, 100 - (rank - 1) * 8)
            )
            results.append(result)
        }
        
        // Add a DNF
        results.append(RaceResult(
            raceID: raceID,
            rank: 99,
            bib: 15,
            athlete: Athlete(
                fisCode: "123456",
                firstName: "Test",
                lastName: "DNF",
                nation: "USA",
                yearOfBirth: 1995,
                gender: .men
            ),
            timeSeconds: nil,
            differenceSeconds: nil,
            status: .didNotFinish,
            fisPoints: 0,
            cupPoints: 0
        ))
        
        return results
    }
    
    // MARK: - Sample Races
    
    static let races: [Race] = [
        // Live World Cup GS
        Race(
            id: "58015",
            codex: "0001",
            location: "Adelboden",
            nation: "SUI",
            date: Date(),
            eventType: .worldCup,
            discipline: .giantSlalom,
            gender: .men,
            status: .inProgress,
            results: makeResults(for: "58015", discipline: .giantSlalom)
        ),
        
        // Scheduled World Cup SL
        Race(
            id: "58016",
            codex: "0002",
            location: "Adelboden",
            nation: "SUI",
            date: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
            eventType: .worldCup,
            discipline: .slalom,
            gender: .men,
            status: .scheduled,
            results: []
        ),
        
        // Finished Europa Cup GS
        Race(
            id: "58087",
            codex: "0003",
            location: "Sestriere",
            nation: "ITA",
            date: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
            eventType: .europaCup,
            discipline: .giantSlalom,
            gender: .women,
            status: .official,
            results: makeResults(for: "58087", discipline: .giantSlalom)
        ),
        
        // Women's World Cup
        Race(
            id: "58012",
            codex: "0004",
            location: "Kranjska Gora",
            nation: "SLO",
            date: Date(),
            eventType: .worldCup,
            discipline: .giantSlalom,
            gender: .women,
            status: .finished,
            results: []
        ),
        
        // FIS Race
        Race(
            id: "59323",
            codex: "0005",
            location: "Rjukan",
            nation: "NOR",
            date: Date(),
            eventType: .fis,
            discipline: .slalom,
            gender: .men,
            status: .scheduled,
            results: []
        ),
    ]
    
    // MARK: - Convenience Getters
    
    static var sampleRace: Race {
        races[0]
    }
    
    static var sampleAthlete: Athlete {
        athletes[0]
    }
    
    static var sampleResult: RaceResult {
        races[0].results[0]
    }
    
    static var liveRaces: [Race] {
        races.filter { $0.status == .inProgress }
    }
    
    static var finishedRaces: [Race] {
        races.filter { $0.status == .finished || $0.status == .official }
    }
    
    static var scheduledRaces: [Race] {
        races.filter { $0.status == .scheduled }
    }
}
