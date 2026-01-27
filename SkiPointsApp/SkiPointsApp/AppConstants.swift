import Foundation

/// Centralized constants replacing magic numbers throughout the codebase.
enum AppConstants {

    // MARK: - FIS Points Calculation

    enum FISPoints {
        /// Default FIS points assigned when no real points exist (999.99)
        static let defaultPoints: Double = 999.99
        /// Points above this threshold are treated as "no valid FIS points" (990)
        static let validPointsThreshold: Double = 990.0
        /// Default high penalty when fewer than 5 valid athletes (100.0)
        static let defaultPenalty: Double = 100.0
        /// Multiplier applied to component A of penalty calculation (0.75)
        static let penaltyMultiplier: Double = 0.75
        /// Default component A value when not enough valid FIS points (50.0)
        static let defaultComponentA: Double = 50.0
        /// Minimum number of athletes required for penalty calculation
        static let minimumRequiredAthletes: Int = 5
        /// Divisor for averaging the best athletes' points
        static let averagingDivisor: Double = 5.0
    }

    // MARK: - Network

    enum Network {
        /// Minimum interval between HTTP requests (rate limiting)
        static let minimumRequestInterval: TimeInterval = 0.5
        /// HTTP request timeout in seconds
        static let requestTimeout: TimeInterval = 30
        /// Maximum number of retry attempts for transient failures
        static let maxRetryAttempts: Int = 3
        /// Base delay for exponential backoff retries (seconds)
        static let retryBaseDelay: TimeInterval = 1.0
        /// Hosts that are allowed through certificate pinning
        static let pinnedHosts: Set<String> = ["www.fis-ski.com", "fis-ski.com"]
    }

    // MARK: - Timing & Auto-Refresh

    enum Timing {
        /// Auto-refresh interval for race list (seconds)
        static let raceListAutoRefreshInterval: TimeInterval = 30
        /// Auto-refresh interval for race detail view (seconds)
        static let raceDetailAutoRefreshInterval: TimeInterval = 15
        /// Debounce interval for athlete search (nanoseconds)
        static let searchDebounceNanoseconds: UInt64 = 300_000_000
    }

    // MARK: - HTML Parser Context Windows

    enum HTMLParser {
        /// Characters to search before an event link match
        static let eventContextLeadingOffset: Int = 2000
        /// Characters to search after an event link match
        static let eventContextTrailingOffset: Int = 500
        /// Characters to search before a race link match
        static let raceContextLeadingOffset: Int = 1000
        /// Characters to search after a race link match
        static let raceContextTrailingOffset: Int = 300
    }

    // MARK: - Cache

    enum Cache {
        /// Default time-to-live for cached data (5 minutes)
        static let defaultTTL: TimeInterval = 300
        /// TTL for live/frequently-changing data (15 seconds)
        static let liveTTL: TimeInterval = 15
        /// Maximum number of cache entries before eviction
        static let maxEntries: Int = 100
    }

    // MARK: - Search

    enum Search {
        /// Minimum character count before triggering athlete search
        static let minimumQueryLength: Int = 2
    }

    // MARK: - FIS Season

    /// Month number (July = 7) when the FIS season transitions to next year
    static let seasonTransitionMonth: Int = 7

    // MARK: - App Info

    /// App version from the bundle, with fallback
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
