import os

/// Centralized logging using os.Logger, replacing scattered print() statements.
/// Each subsystem category maps to a logical area of the app.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skipoints.app"

    /// Network service operations (HTTP requests, responses, rate limiting)
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// HTML parsing operations (regex matching, data extraction)
    static let parser = Logger(subsystem: subsystem, category: "HTMLParser")

    /// View model state changes (loading, refreshing, data updates)
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")

    /// Favorites management (persistence, loading, saving)
    static let favorites = Logger(subsystem: subsystem, category: "Favorites")

    /// Cache operations (hits, misses, evictions)
    static let cache = Logger(subsystem: subsystem, category: "Cache")
}
