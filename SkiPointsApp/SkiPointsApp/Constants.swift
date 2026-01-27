import Foundation
import os.log

// MARK: - App Constants

enum AppConstants {

    // MARK: - Network Configuration

    enum Network {
        static let baseURL = "https://www.fis-ski.com"
        static let requestTimeoutSeconds: TimeInterval = 30
        static let minimumRequestInterval: TimeInterval = 0.5
    }

    // MARK: - Refresh Intervals

    enum RefreshInterval {
        static let raceListSeconds: TimeInterval = 30
        static let liveRaceSeconds: TimeInterval = 15
        static let searchDebounceNanoseconds: UInt64 = 300_000_000  // 300ms
    }

    // MARK: - Search

    enum Search {
        static let minimumQueryLength = 2
    }

    // MARK: - FIS Points Calculation

    enum FISPoints {
        static let validPointsThreshold: Double = 990.0
        static let defaultPoints: Double = 990.0
        static let defaultPenalty: Double = 100.0
        static let defaultComponentA: Double = 50.0
        static let penaltyMultiplier: Double = 0.75
        static let minimumRequiredAthletes = 5
        static let averagingDivisor: Double = 5.0
    }

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let favoriteAthletes = "favoriteAthletes"
        static let favoriteAthletesData = "favoriteAthletesData"
    }

    // MARK: - UI Constants

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let iconSize: CGFloat = 44
    }

    // MARK: - App Info

    enum AppInfo {
        static let version = "1.0.0"
        static let developer = "Bjorn"
        static let fisWebsiteURL = "https://www.fis-ski.com"
    }
}

// MARK: - Logging

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skipoints"

    static let network = Logger(subsystem: subsystem, category: "Network")
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let parser = Logger(subsystem: subsystem, category: "Parser")
    static let favorites = Logger(subsystem: subsystem, category: "Favorites")
    static let search = Logger(subsystem: subsystem, category: "Search")
}
