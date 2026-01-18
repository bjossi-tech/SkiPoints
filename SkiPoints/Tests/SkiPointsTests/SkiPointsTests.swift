import XCTest
@testable import SkiPoints

final class SkiPointsTests: XCTestCase {
    
    // MARK: - FIS Points Calculator Tests
    
    func testFISPointsCalculator_WinnerGetsZeroPoints() {
        let calc = FISPointsCalculator()
        
        let points = calc.calculatePoints(
            raceTime: 105.19,
            winnerTime: 105.19,
            discipline: .superG
        )
        
        XCTAssertEqual(points, 0.0)
    }
    
    func testFISPointsCalculator_SuperGCalculation() {
        // Wengen 2025 Super G: Babinsky finished 0.35s behind Franzoni
        // Expected: 3.96 points
        let calc = FISPointsCalculator()
        
        let points = calc.calculatePoints(
            raceTime: 105.54,
            winnerTime: 105.19,
            discipline: .superG
        )
        
        XCTAssertNotNil(points)
        XCTAssertEqual(points!, 3.96, accuracy: 0.01)
    }
    
    func testFISPointsCalculator_DownhillFactor() {
        let calc = FISPointsCalculator()
        
        // 1 second behind in DH should give ~12.6 points (1330/105 ≈ 12.67)
        let points = calc.calculatePoints(
            raceTime: 106.0,
            winnerTime: 105.0,
            discipline: .downhill
        )
        
        XCTAssertNotNil(points)
        XCTAssertGreaterThan(points!, 12.0)
        XCTAssertLessThan(points!, 13.0)
    }
    
    func testFISPointsCalculator_SlalomFactor() {
        let calc = FISPointsCalculator()
        
        // Slalom has factor 730
        let points = calc.calculatePoints(
            raceTime: 91.0,
            winnerTime: 90.0,
            discipline: .slalom
        )
        
        XCTAssertNotNil(points)
        // (91-90)/90 * 730 ≈ 8.11
        XCTAssertEqual(points!, 8.11, accuracy: 0.1)
    }
    
    func testFISPointsCalculator_WithPenalty() {
        let calc = FISPointsCalculator()
        
        let points = calc.calculatePoints(
            raceTime: 105.54,
            winnerTime: 105.19,
            discipline: .superG,
            penalty: 5.0
        )
        
        XCTAssertNotNil(points)
        // 3.96 + 5.0 = 8.96
        XCTAssertEqual(points!, 8.96, accuracy: 0.1)
    }
    
    func testFISPointsCalculator_InvalidWinnerTime() {
        let calc = FISPointsCalculator()
        
        let points = calc.calculatePoints(
            raceTime: 105.0,
            winnerTime: 0,
            discipline: .superG
        )
        
        XCTAssertNil(points)
    }
    
    func testFISPointsCalculator_RaceFasterThanWinner() {
        let calc = FISPointsCalculator()
        
        let points = calc.calculatePoints(
            raceTime: 100.0,
            winnerTime: 105.0,
            discipline: .superG
        )
        
        XCTAssertNil(points)
    }
    
    func testFISPointsCalculator_WorldCupPoints() {
        let calc = FISPointsCalculator()
        
        XCTAssertEqual(calc.worldCupPoints(forRank: 1), 100)
        XCTAssertEqual(calc.worldCupPoints(forRank: 2), 80)
        XCTAssertEqual(calc.worldCupPoints(forRank: 3), 60)
        XCTAssertEqual(calc.worldCupPoints(forRank: 10), 26)
        XCTAssertEqual(calc.worldCupPoints(forRank: 30), 1)
        XCTAssertEqual(calc.worldCupPoints(forRank: 31), 0)
    }
    
    func testFISPointsCalculator_TimeForTargetPoints() {
        let calc = FISPointsCalculator()
        
        let targetTime = calc.timeForTargetPoints(
            targetPoints: 10.0,
            winnerTime: 100.0,
            discipline: .superG
        )
        
        // Verify by calculating back
        let verifyPoints = calc.calculatePoints(
            raceTime: targetTime,
            winnerTime: 100.0,
            discipline: .superG
        )
        
        XCTAssertNotNil(verifyPoints)
        XCTAssertEqual(verifyPoints!, 10.0, accuracy: 0.01)
    }
    
    // MARK: - Athlete Tests
    
    func testAthlete_FullName() {
        let athlete = PreviewData.odermatt
        
        XCTAssertEqual(athlete.fullName, "Marco ODERMATT")
    }
    
    func testAthlete_ShortName() {
        let athlete = PreviewData.odermatt
        
        XCTAssertEqual(athlete.shortName, "M. ODERMATT")
    }
    
    func testAthlete_FlagEmoji_Switzerland() {
        let athlete = PreviewData.odermatt
        
        XCTAssertEqual(athlete.flagEmoji, "🇨🇭")
    }
    
    func testAthlete_FlagEmoji_USA() {
        let athlete = PreviewData.shiffrin
        
        XCTAssertEqual(athlete.flagEmoji, "🇺🇸")
    }
    
    func testAthlete_FlagEmoji_Austria() {
        let athlete = PreviewData.babinsky
        
        XCTAssertEqual(athlete.flagEmoji, "🇦🇹")
    }
    
    func testAthlete_FlagEmoji_Italy() {
        let athlete = PreviewData.franzoni
        
        XCTAssertEqual(athlete.flagEmoji, "🇮🇹")
    }
    
    func testAthlete_Age() {
        let athlete = PreviewData.odermatt
        let currentYear = Calendar.current.component(.year, from: Date())
        let expectedAge = currentYear - 1997
        
        XCTAssertEqual(athlete.age, expectedAge)
    }
    
    func testAthlete_FISProfileURL() {
        let athlete = PreviewData.odermatt
        
        XCTAssertNotNil(athlete.fisProfileURL)
        XCTAssertTrue(athlete.fisProfileURL!.absoluteString.contains("512269"))
    }
    
    func testAthlete_Equality() {
        let athlete1 = PreviewData.odermatt
        let athlete2 = Athlete(
            fisCode: "512269",
            firstName: "Different",
            lastName: "Name",
            nation: "SUI",
            yearOfBirth: 1997,
            gender: .men
        )
        
        XCTAssertEqual(athlete1, athlete2) // Same FIS code
    }
    
    func testAthlete_Hashable() {
        var set = Set<Athlete>()
        set.insert(PreviewData.odermatt)
        set.insert(PreviewData.franzoni)
        set.insert(PreviewData.odermatt) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Race Tests
    
    func testRace_Title() {
        let race = PreviewData.wengenSuperG
        
        XCTAssertEqual(race.title, "Men's Super G")
    }
    
    func testRace_FullLocation() {
        let race = PreviewData.wengenSuperG
        
        XCTAssertEqual(race.fullLocation, "Wengen (SUI)")
    }
    
    func testRace_Winner() {
        let race = PreviewData.wengenSuperG
        
        XCTAssertNotNil(race.winner)
        XCTAssertEqual(race.winner?.athlete.lastName, "FRANZONI")
    }
    
    func testRace_Podium() {
        let race = PreviewData.wengenSuperG
        let podium = race.podium
        
        XCTAssertEqual(podium.count, 3)
        XCTAssertEqual(podium[0].rank, 1)
        XCTAssertEqual(podium[1].rank, 2)
        XCTAssertEqual(podium[2].rank, 3)
    }
    
    func testRace_IsLive() {
        let official = PreviewData.wengenSuperG
        let live = PreviewData.cortinaSuperG
        
        XCTAssertFalse(official.isLive)
        XCTAssertTrue(live.isLive)
    }
    
    func testRace_HasResults() {
        let withResults = PreviewData.wengenSuperG
        let scheduled = PreviewData.kitzbuehelDownhill
        
        XCTAssertTrue(withResults.hasResults)
        XCTAssertFalse(scheduled.hasResults)
    }
    
    // MARK: - RaceResult Tests
    
    func testRaceResult_FormattedTime() {
        let result = PreviewData.wengenResults[0]
        
        XCTAssertEqual(result.formattedTime, "1:45.19")
    }
    
    func testRaceResult_FormattedDiff_Winner() {
        let winner = PreviewData.wengenResults[0]
        
        XCTAssertEqual(winner.formattedDiff, "")
    }
    
    func testRaceResult_FormattedDiff_NotWinner() {
        let second = PreviewData.wengenResults[1]
        
        XCTAssertEqual(second.formattedDiff, "+0.35")
    }
    
    func testRaceResult_IsPodium() {
        let first = PreviewData.wengenResults[0]
        let third = PreviewData.wengenResults[2]
        let fourth = PreviewData.wengenResults[3]
        
        XCTAssertTrue(first.isPodium)
        XCTAssertTrue(third.isPodium)
        XCTAssertFalse(fourth.isPodium)
    }
    
    func testRaceResult_Medal() {
        let results = PreviewData.wengenResults
        
        XCTAssertEqual(results[0].medal, .gold)
        XCTAssertEqual(results[1].medal, .silver)
        XCTAssertEqual(results[2].medal, .bronze)
        XCTAssertNil(results[3].medal)
    }
    
    func testRaceResult_Comparable() {
        var results = PreviewData.wengenResults.shuffled()
        results.sort()
        
        XCTAssertEqual(results[0].rank, 1)
        XCTAssertEqual(results[1].rank, 2)
        XCTAssertEqual(results[2].rank, 3)
    }
    
    // MARK: - Discipline Tests
    
    func testDiscipline_FISPointsFactor() {
        XCTAssertEqual(Discipline.downhill.fisPointsFactor, 1330.0)
        XCTAssertEqual(Discipline.superG.fisPointsFactor, 1190.0)
        XCTAssertEqual(Discipline.giantSlalom.fisPointsFactor, 1010.0)
        XCTAssertEqual(Discipline.slalom.fisPointsFactor, 730.0)
    }
    
    func testDiscipline_Parsing() {
        XCTAssertEqual(Discipline(fisString: "DH"), .downhill)
        XCTAssertEqual(Discipline(fisString: "SG"), .superG)
        XCTAssertEqual(Discipline(fisString: "Giant Slalom"), .giantSlalom)
        XCTAssertEqual(Discipline(fisString: "sl"), .slalom)
        XCTAssertNil(Discipline(fisString: "Invalid"))
    }
    
    func testDiscipline_IsSpeedEvent() {
        XCTAssertTrue(Discipline.downhill.isSpeedEvent)
        XCTAssertTrue(Discipline.superG.isSpeedEvent)
        XCTAssertFalse(Discipline.slalom.isSpeedEvent)
        XCTAssertFalse(Discipline.giantSlalom.isSpeedEvent)
    }
    
    // MARK: - TimeInterval Extension Tests
    
    func testTimeInterval_RaceTimeFormatted_UnderMinute() {
        let time: TimeInterval = 45.19
        
        XCTAssertEqual(time.raceTimeFormatted, "45.19")
    }
    
    func testTimeInterval_RaceTimeFormatted_OverMinute() {
        let time: TimeInterval = 105.19
        
        XCTAssertEqual(time.raceTimeFormatted, "1:45.19")
    }
    
    func testTimeInterval_DiffFormatted() {
        let diff: TimeInterval = 0.35
        
        XCTAssertEqual(diff.diffFormatted, "+0.35")
    }
    
    func testTimeInterval_DiffFormatted_Zero() {
        let diff: TimeInterval = 0.0
        
        XCTAssertEqual(diff.diffFormatted, "")
    }
    
    func testTimeInterval_Parsing() {
        XCTAssertEqual(TimeInterval(raceTimeString: "1:45.19"), 105.19, accuracy: 0.001)
        XCTAssertEqual(TimeInterval(raceTimeString: "45.19"), 45.19, accuracy: 0.001)
        XCTAssertNil(TimeInterval(raceTimeString: "invalid"))
    }
    
    // MARK: - RaceStatus Tests
    
    func testRaceStatus_IsLive() {
        XCTAssertTrue(RaceStatus.inProgress.isLive)
        XCTAssertTrue(RaceStatus.intermission.isLive)
        XCTAssertFalse(RaceStatus.scheduled.isLive)
        XCTAssertFalse(RaceStatus.official.isLive)
    }
    
    func testRaceStatus_HasResults() {
        XCTAssertTrue(RaceStatus.inProgress.hasResults)
        XCTAssertTrue(RaceStatus.official.hasResults)
        XCTAssertFalse(RaceStatus.scheduled.hasResults)
        XCTAssertFalse(RaceStatus.cancelled.hasResults)
    }
    
    func testRaceStatus_Parsing() {
        XCTAssertEqual(RaceStatus(fisString: "live"), .inProgress)
        XCTAssertEqual(RaceStatus(fisString: "Official Result"), .official)
        XCTAssertEqual(RaceStatus(fisString: "CANCELLED"), .cancelled)
    }
    
    func testRaceStatus_Comparable() {
        var statuses: [RaceStatus] = [.official, .inProgress, .scheduled, .cancelled]
        statuses.sort()
        
        XCTAssertEqual(statuses[0], .inProgress) // Live first
        XCTAssertEqual(statuses[1], .scheduled)
        XCTAssertEqual(statuses[2], .official)
        XCTAssertEqual(statuses[3], .cancelled)
    }
    
    // MARK: - ResultStatus Tests
    
    func testResultStatus_HasValidTime() {
        XCTAssertTrue(ResultStatus.finished.hasValidTime)
        XCTAssertFalse(ResultStatus.didNotFinish.hasValidTime)
        XCTAssertFalse(ResultStatus.didNotStart.hasValidTime)
    }
    
    func testResultStatus_Parsing() {
        XCTAssertEqual(ResultStatus(fisString: "FIN"), .finished)
        XCTAssertEqual(ResultStatus(fisString: "DNF"), .didNotFinish)
        XCTAssertEqual(ResultStatus(fisString: "dns"), .didNotStart)
        XCTAssertEqual(ResultStatus(fisString: "DSQ"), .disqualified)
    }
}
