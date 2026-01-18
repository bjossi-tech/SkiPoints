import Foundation

/// Calculator for FIS race points.
///
/// Implements the official FIS points formula used to rank athletes
/// across all alpine skiing disciplines.
///
/// ## Formula
/// ```
/// Race Points = (Racer Time - Winner Time) / Winner Time × F + Penalty
/// ```
///
/// Where F varies by discipline:
/// - Downhill: 1330
/// - Super G: 1190
/// - Giant Slalom: 1010
/// - Slalom: 730
///
/// ## Example
/// ```swift
/// let calc = FISPointsCalculator()
/// let points = calc.calculatePoints(
///     raceTime: 105.54,
///     winnerTime: 105.19,
///     discipline: .superG
/// )
/// // points ≈ 3.96
/// ```
public struct FISPointsCalculator: Sendable {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Points Calculation
    
    /// Calculate FIS race points for a given result.
    ///
    /// - Parameters:
    ///   - raceTime: Athlete's total race time in seconds
    ///   - winnerTime: Winner's total race time in seconds
    ///   - discipline: Race discipline
    ///   - penalty: Race penalty (optional, defaults to 0)
    /// - Returns: Calculated FIS points, or nil if invalid
    public func calculatePoints(
        raceTime: TimeInterval,
        winnerTime: TimeInterval,
        discipline: Discipline,
        penalty: Double = 0
    ) -> Double? {
        // Validate inputs
        guard winnerTime > 0, raceTime >= winnerTime else {
            return nil
        }
        
        let factor = discipline.fisPointsFactor
        let timeDiff = raceTime - winnerTime
        let points = (timeDiff / winnerTime) * factor + penalty
        
        // FIS points are rounded to 2 decimal places
        return max(0, (points * 100).rounded() / 100)
    }
    
    /// Calculate points for all results in a race.
    ///
    /// - Parameters:
    ///   - results: Array of race results
    ///   - discipline: Race discipline
    ///   - penalty: Race penalty (default 0)
    /// - Returns: Dictionary mapping athlete FIS codes to calculated points
    public func calculatePointsForRace(
        results: [RaceResult],
        discipline: Discipline,
        penalty: Double = 0
    ) -> [String: Double] {
        // Find winner's time
        guard let winnerTime = results
            .filter({ $0.status == .finished })
            .compactMap({ $0.timeSeconds })
            .min() else {
            return [:]
        }
        
        var pointsMap: [String: Double] = [:]
        
        for result in results where result.status == .finished {
            if let time = result.timeSeconds,
               let points = calculatePoints(
                   raceTime: time,
                   winnerTime: winnerTime,
                   discipline: discipline,
                   penalty: penalty
               ) {
                pointsMap[result.athlete.fisCode] = points
            }
        }
        
        return pointsMap
    }
    
    // MARK: - Utility Methods
    
    /// Calculate time difference from winner.
    ///
    /// - Parameters:
    ///   - raceTime: Athlete's time
    ///   - winnerTime: Winner's time
    /// - Returns: Time difference in seconds
    public func calculateTimeDiff(
        raceTime: TimeInterval,
        winnerTime: TimeInterval
    ) -> TimeInterval {
        max(0, raceTime - winnerTime)
    }
    
    /// Calculate what time would be needed to achieve target points.
    ///
    /// - Parameters:
    ///   - targetPoints: Desired FIS points
    ///   - winnerTime: Winner's time
    ///   - discipline: Race discipline
    ///   - penalty: Race penalty
    /// - Returns: Required race time in seconds
    public func timeForTargetPoints(
        targetPoints: Double,
        winnerTime: TimeInterval,
        discipline: Discipline,
        penalty: Double = 0
    ) -> TimeInterval {
        // Reverse the formula:
        // points = (raceTime - winnerTime) / winnerTime * F + penalty
        // points - penalty = (raceTime - winnerTime) / winnerTime * F
        // (points - penalty) / F = (raceTime - winnerTime) / winnerTime
        // winnerTime * (points - penalty) / F = raceTime - winnerTime
        // raceTime = winnerTime + winnerTime * (points - penalty) / F
        // raceTime = winnerTime * (1 + (points - penalty) / F)
        
        let factor = discipline.fisPointsFactor
        let adjustedPoints = max(0, targetPoints - penalty)
        return winnerTime * (1 + adjustedPoints / factor)
    }
}

// MARK: - World Cup Points

extension FISPointsCalculator {
    
    /// World Cup points distribution for top 30 finishers.
    ///
    /// Points are awarded to the top 30 in World Cup races:
    /// 1st: 100, 2nd: 80, 3rd: 60, 4th: 50, 5th: 45...
    public static let worldCupPointsDistribution: [Int: Int] = [
        1: 100, 2: 80, 3: 60, 4: 50, 5: 45,
        6: 40, 7: 36, 8: 32, 9: 29, 10: 26,
        11: 24, 12: 22, 13: 20, 14: 18, 15: 16,
        16: 15, 17: 14, 18: 13, 19: 12, 20: 11,
        21: 10, 22: 9, 23: 8, 24: 7, 25: 6,
        26: 5, 27: 4, 28: 3, 29: 2, 30: 1
    ]
    
    /// Get World Cup points for a given rank.
    ///
    /// - Parameter rank: Finishing position (1-30)
    /// - Returns: World Cup points (0 if rank > 30)
    public func worldCupPoints(forRank rank: Int) -> Int {
        Self.worldCupPointsDistribution[rank] ?? 0
    }
    
    /// Europa Cup points distribution (same as WC for top 30)
    public static let europaCupPointsDistribution: [Int: Int] = worldCupPointsDistribution
}

// MARK: - Penalty Calculation

extension FISPointsCalculator {
    
    /// Calculate race penalty based on top 10 results.
    ///
    /// The race penalty is calculated from the FIS points of the
    /// top 10 finishers (top 5 from each group).
    ///
    /// This is a simplified version - actual FIS calculation is more complex.
    ///
    /// - Parameters:
    ///   - results: Race results with pre-existing FIS points
    /// - Returns: Calculated race penalty
    public func calculateRacePenalty(from results: [RaceResult]) -> Double {
        let topTenPoints = results
            .filter { $0.status == .finished }
            .prefix(10)
            .compactMap { $0.athlete.currentFISPoints }
            .sorted()
        
        guard !topTenPoints.isEmpty else { return 0 }
        
        // Take top 5 FIS points and calculate average
        let top5 = Array(topTenPoints.prefix(5))
        let average = top5.reduce(0, +) / Double(top5.count)
        
        // Minimum penalty is 0
        return max(0, average)
    }
}
