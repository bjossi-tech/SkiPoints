import Foundation
import os

// MARK: - Network Errors

enum FISNetworkError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case parsingError(String)
    case rateLimited
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .rateLimited:
            return "Rate limited - please try again later"
        case .noData:
            return "No data received"
        }
    }

    /// Whether this error is transient and worth retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimited, .invalidResponse:
            return true
        case .httpError(let code):
            return code >= 500 || code == 429
        case .invalidURL, .parsingError, .noData:
            return false
        }
    }
}

// MARK: - Certificate Pinning Delegate

/// Validates that connections are only made to expected FIS hosts.
private class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Only apply pinning to known FIS hosts
        guard AppConstants.Network.pinnedHosts.contains(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the server certificate chain
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var error: CFError?
        if SecTrustEvaluateWithError(serverTrust, &error) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            AppLogger.network.error("Certificate validation failed for \(host): \(error?.localizedDescription ?? "unknown error")")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - FIS Network Service

actor FISNetworkService {
    static let shared = FISNetworkService()

    private let baseURL = "https://www.fis-ski.com"
    private let session: URLSession
    private var lastRequestTime: Date?
    private let cache = NetworkCache.shared

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.requestTimeout
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br"
        ]
        let pinningDelegate = CertificatePinningDelegate()
        self.session = URLSession(configuration: config, delegate: pinningDelegate, delegateQueue: nil)
    }

    // MARK: - Rate Limiting

    private func waitForRateLimit() async {
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < AppConstants.Network.minimumRequestInterval {
                let delay = AppConstants.Network.minimumRequestInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }

    // MARK: - Fetch Today's Races (Events)

    /// Fetch today's events from the FIS calendar
    func fetchTodaysRaces() async throws -> [Race] {
        let seasonCode = getCurrentSeasonCode()

        // Check cache first
        let cacheKey = NetworkCache.calendarKey(seasonCode: seasonCode)
        if let cached: [Race] = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached calendar for season \(seasonCode)")
            let calendar = Calendar.current
            let now = Date()
            let today = calendar.startOfDay(for: now)
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                throw FISNetworkError.parsingError("Failed to calculate tomorrow's date")
            }
            return cached.filter { $0.date >= today && $0.date < tomorrow }
        }

        let urlString = "\(baseURL)/DB/alpine-skiing/calendar-results.html?sectorcode=AL&seasoncode=\(seasonCode)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Fetching calendar from: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        let allEvents = try FISHTMLParser.parseCalendarEvents(html: html)

        // Cache the full calendar
        await cache.set(key: cacheKey, value: allEvents)

        // Filter to today's events
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            throw FISNetworkError.parsingError("Failed to calculate tomorrow's date")
        }

        let todaysEvents = allEvents.filter { event in
            event.date >= today && event.date < tomorrow
        }

        AppLogger.network.info("Found \(todaysEvents.count) events for today out of \(allEvents.count) total")

        return todaysEvents
    }

    /// Fetch events for a specific date range
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [Race] {
        let seasonCode = calculateSeasonCode(for: startDate)

        // Check cache first
        let cacheKey = NetworkCache.calendarKey(seasonCode: seasonCode)
        if let cached: [Race] = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached calendar for season \(seasonCode)")
            let calendar = Calendar.current
            let startOfStartDate = calendar.startOfDay(for: startDate)
            guard let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
                throw FISNetworkError.parsingError("Failed to calculate end date range")
            }
            return cached.filter { $0.date >= startOfStartDate && $0.date < endOfEndDate }
        }

        let urlString = "\(baseURL)/DB/alpine-skiing/calendar-results.html?sectorcode=AL&seasoncode=\(seasonCode)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        let html = try await fetchHTMLWithRetry(from: url)
        let allEvents = try FISHTMLParser.parseCalendarEvents(html: html)

        // Cache the full calendar
        await cache.set(key: cacheKey, value: allEvents)

        // Filter to date range
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        guard let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            throw FISNetworkError.parsingError("Failed to calculate end date range")
        }

        return allEvents.filter { event in
            event.date >= startOfStartDate && event.date < endOfEndDate
        }
    }

    // MARK: - Fetch Event Details (Individual Races within an Event)

    /// Fetch details for a specific event (which contains individual races)
    func fetchEventDetails(eventID: String, seasonCode: Int? = nil) async throws -> [Race] {
        await waitForRateLimit()

        // Check cache
        let cacheKey = NetworkCache.eventKey(eventID: eventID)
        if let cached: [Race] = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached event details for \(eventID)")
            return cached
        }

        let season = seasonCode ?? getCurrentSeasonCode()
        let urlString = "\(baseURL)/DB/general/event-details.html?sectorcode=AL&eventid=\(eventID)&seasoncode=\(season)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Fetching event details from: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        let races = try FISHTMLParser.parseEventDetails(html: html, eventID: eventID)

        await cache.set(key: cacheKey, value: races)
        return races
    }

    // MARK: - Fetch Race Results

    /// Fetch results for a specific race
    func fetchRaceResults(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()

        // Check cache (use shorter TTL since results change)
        let cacheKey = NetworkCache.raceResultsKey(raceID: raceID)
        if let cached: [RaceResult] = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached results for race \(raceID)")
            return cached
        }

        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Fetching race results from: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        let results = try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)

        // Use live TTL since race results can change frequently
        await cache.set(key: cacheKey, value: results, ttl: AppConstants.Cache.liveTTL)
        return results
    }

    // MARK: - Fetch Live Data

    /// Fetch live timing data for an ongoing race
    func fetchLiveData(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()

        // No caching for live data — always fetch fresh
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Fetching live data from: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
    }

    // MARK: - Fetch Athlete

    /// Fetch athlete biography and FIS points
    func fetchAthlete(competitorID: String) async throws -> Athlete {
        await waitForRateLimit()

        // Check cache
        let cacheKey = NetworkCache.athleteKey(competitorID: competitorID)
        if let cached: Athlete = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached athlete \(competitorID)")
            return cached
        }

        let urlString = "\(baseURL)/DB/general/athlete-biography.html?sectorcode=AL&competitorid=\(competitorID)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Fetching athlete from: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        let athlete = try FISHTMLParser.parseAthleteBiography(html: html, competitorID: competitorID)

        await cache.set(key: cacheKey, value: athlete)
        return athlete
    }

    // MARK: - Search Athletes

    /// Search for athletes by name
    func searchAthletes(query: String) async throws -> [Athlete] {
        await waitForRateLimit()

        // Check cache
        let cacheKey = NetworkCache.searchKey(query: query)
        if let cached: [Athlete] = await cache.get(key: cacheKey) {
            AppLogger.network.info("Returning cached search for '\(query)'")
            return cached
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/DB/general/biographies.html?sectorcode=AL&lastname=\(encodedQuery)"

        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }

        AppLogger.network.info("Searching athletes: \(urlString)")

        let html = try await fetchHTMLWithRetry(from: url)
        let athletes = try FISHTMLParser.parseAthleteSearch(html: html)

        await cache.set(key: cacheKey, value: athletes)
        return athletes
    }

    // MARK: - Private Helpers

    /// Compute season code from an arbitrary date.
    /// FIS season runs July to June: July 2025 → season 2026.
    private func calculateSeasonCode(for date: Date) -> Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return month >= AppConstants.seasonTransitionMonth ? year + 1 : year
    }

    /// Compute season code for the current date.
    private func getCurrentSeasonCode() -> Int {
        calculateSeasonCode(for: Date())
    }

    // MARK: - Retry Logic

    /// Fetch HTML with automatic retry on transient failures.
    /// Uses exponential backoff: 1s, 2s, 4s, etc.
    private func fetchHTMLWithRetry(from url: URL) async throws -> String {
        var lastError: Error?

        for attempt in 0...AppConstants.Network.maxRetryAttempts {
            do {
                if attempt > 0 {
                    let delay = AppConstants.Network.retryBaseDelay * pow(2.0, Double(attempt - 1))
                    AppLogger.network.info("Retry \(attempt)/\(AppConstants.Network.maxRetryAttempts) after \(delay)s for \(url.absoluteString)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                return try await fetchHTML(from: url)

            } catch let error as FISNetworkError where error.isRetryable && attempt < AppConstants.Network.maxRetryAttempts {
                lastError = error
                AppLogger.network.warning("Retryable error on attempt \(attempt + 1): \(error.localizedDescription)")
                continue

            } catch {
                throw error
            }
        }

        throw lastError ?? FISNetworkError.networkError(NSError(domain: "FISNetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"]))
    }

    private func fetchHTML(from url: URL) async throws -> String {
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FISNetworkError.invalidResponse
            }

            AppLogger.network.debug("HTTP \(httpResponse.statusCode) for \(url.lastPathComponent)")

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 429:
                throw FISNetworkError.rateLimited
            case 403:
                AppLogger.network.error("403 Forbidden — may need different User-Agent")
                throw FISNetworkError.httpError(403)
            default:
                throw FISNetworkError.httpError(httpResponse.statusCode)
            }

            // Try UTF-8 first, then ISO-8859-1 (FIS uses both)
            if let html = String(data: data, encoding: .utf8) {
                AppLogger.network.debug("Received \(html.count) characters (UTF-8)")
                return html
            } else if let html = String(data: data, encoding: .isoLatin1) {
                AppLogger.network.debug("Received \(html.count) characters (ISO-8859-1)")
                return html
            } else {
                throw FISNetworkError.noData
            }
        } catch let error as FISNetworkError {
            throw error
        } catch {
            throw FISNetworkError.networkError(error)
        }
    }
}
