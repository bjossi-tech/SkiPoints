import Foundation
import os

/// Thread-safe in-memory cache with TTL-based expiration for parsed network data.
/// Reduces redundant network requests and HTML re-parsing.
actor NetworkCache {
    static let shared = NetworkCache()

    private struct CacheEntry {
        let data: Any
        let timestamp: Date
        let ttl: TimeInterval

        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < ttl
        }
    }

    private var cache: [String: CacheEntry] = [:]

    // MARK: - Public API

    /// Retrieve a cached value if it exists and hasn't expired.
    func get<T>(key: String) -> T? {
        guard let entry = cache[key] else { return nil }

        if entry.isValid {
            AppLogger.cache.debug("Cache hit: \(key)")
            return entry.data as? T
        }

        // Entry expired — remove it
        cache.removeValue(forKey: key)
        AppLogger.cache.debug("Cache expired: \(key)")
        return nil
    }

    /// Store a value in the cache with a specified TTL.
    func set<T>(key: String, value: T, ttl: TimeInterval = AppConstants.Cache.defaultTTL) {
        if cache.count >= AppConstants.Cache.maxEntries {
            evictExpired()
        }
        cache[key] = CacheEntry(data: value, timestamp: Date(), ttl: ttl)
        AppLogger.cache.debug("Cache set: \(key) (TTL: \(ttl)s)")
    }

    /// Remove a specific cache entry.
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
    }

    /// Remove all cache entries.
    func invalidateAll() {
        let count = cache.count
        cache.removeAll()
        AppLogger.cache.info("Cache cleared (\(count) entries removed)")
    }

    // MARK: - Cache Key Helpers

    /// Generate a cache key for calendar data.
    static func calendarKey(seasonCode: Int) -> String {
        "calendar_\(seasonCode)"
    }

    /// Generate a cache key for event details.
    static func eventKey(eventID: String) -> String {
        "event_\(eventID)"
    }

    /// Generate a cache key for race results.
    static func raceResultsKey(raceID: String) -> String {
        "results_\(raceID)"
    }

    /// Generate a cache key for athlete data.
    static func athleteKey(competitorID: String) -> String {
        "athlete_\(competitorID)"
    }

    /// Generate a cache key for athlete search.
    static func searchKey(query: String) -> String {
        "search_\(query.lowercased())"
    }

    // MARK: - Private

    private func evictExpired() {
        let before = cache.count
        cache = cache.filter { $0.value.isValid }
        let evicted = before - cache.count
        if evicted > 0 {
            AppLogger.cache.debug("Evicted \(evicted) expired cache entries")
        }
    }
}
