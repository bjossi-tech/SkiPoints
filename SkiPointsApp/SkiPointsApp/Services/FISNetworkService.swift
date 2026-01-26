import Foundation
import os.log

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
}

// MARK: - FIS Network Service

actor FISNetworkService {
    static let shared = FISNetworkService()

    private let baseURL = AppConstants.Network.baseURL
    private let session: URLSession
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = AppConstants.Network.minimumRequestInterval

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.requestTimeoutSeconds
        // CRITICAL: Use a proper browser User-Agent - FIS blocks non-browser requests
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Rate Limiting
    
    private func waitForRateLimit() async {
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < minimumRequestInterval {
                let delay = minimumRequestInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    // MARK: - Fetch Today's Races (Events)
    
    /// Fetch today's events from the FIS calendar
    func fetchTodaysRaces() async throws -> [Race] {
        // Get current season code (FIS season runs July to June)
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        let seasonCode = month >= 7 ? year + 1 : year
        
        // FIS calendar URL - this returns the full calendar, filtered by season
        // The calendar is client-side rendered, so we need to parse the static content
        let urlString = "\(baseURL)/DB/alpine-skiing/calendar-results.html?sectorcode=AL&seasoncode=\(seasonCode)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Fetching calendar from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        
        // Parse events from the calendar HTML
        let allEvents = try FISHTMLParser.parseCalendarEvents(html: html)
        
        // Filter to today's events
        let today = calendar.startOfDay(for: now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return allEvents.filter { event in
                calendar.isDate(event.date, inSameDayAs: today)
            }
        }

        let todaysEvents = allEvents.filter { event in
            event.date >= today && event.date < tomorrow
        }
        
        Log.network.debug("[FISNetworkService] Found \(todaysEvents.count) events for today out of \(allEvents.count) total")
        
        return todaysEvents
    }
    
    /// Fetch events for a specific date range
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [Race] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: startDate)
        let year = calendar.component(.year, from: startDate)
        let seasonCode = month >= 7 ? year + 1 : year
        
        let urlString = "\(baseURL)/DB/alpine-skiing/calendar-results.html?sectorcode=AL&seasoncode=\(seasonCode)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        let html = try await fetchHTML(from: url)
        let allEvents = try FISHTMLParser.parseCalendarEvents(html: html)
        
        // Filter to date range
        let startOfStartDate = calendar.startOfDay(for: startDate)
        guard let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            return allEvents.filter { event in
                event.date >= startOfStartDate
            }
        }

        return allEvents.filter { event in
            event.date >= startOfStartDate && event.date < endOfEndDate
        }
    }
    
    // MARK: - Fetch Event Details (Individual Races within an Event)
    
    /// Fetch details for a specific event (which contains individual races)
    func fetchEventDetails(eventID: String, seasonCode: Int? = nil) async throws -> [Race] {
        await waitForRateLimit()
        
        let season = seasonCode ?? getCurrentSeasonCode()
        let urlString = "\(baseURL)/DB/general/event-details.html?sectorcode=AL&eventid=\(eventID)&seasoncode=\(season)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Fetching event details from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseEventDetails(html: html, eventID: eventID)
    }
    
    // MARK: - Fetch Race Results
    
    /// Fetch results for a specific race
    func fetchRaceResults(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Fetching race results from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
    }
    
    // MARK: - Fetch Live Data
    
    /// Fetch live timing data for an ongoing race
    func fetchLiveData(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()
        
        // FIS live timing endpoint
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Fetching live data from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
    }
    
    // MARK: - Fetch Athlete
    
    /// Fetch athlete biography and FIS points
    func fetchAthlete(competitorID: String) async throws -> Athlete {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/athlete-biography.html?sectorcode=AL&competitorid=\(competitorID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Fetching athlete from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseAthleteBiography(html: html, competitorID: competitorID)
    }
    
    // MARK: - Search Athletes
    
    /// Search for athletes by name
    func searchAthletes(query: String) async throws -> [Athlete] {
        await waitForRateLimit()
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/DB/general/biographies.html?sectorcode=AL&lastname=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        Log.network.debug("[FISNetworkService] Searching athletes: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseAthleteSearch(html: html)
    }
    
    // MARK: - Private Helpers
    
    private func getCurrentSeasonCode() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return month >= 7 ? year + 1 : year
    }
    
    private func fetchHTML(from url: URL) async throws -> String {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FISNetworkError.invalidResponse
            }
            
            Log.network.debug("[FISNetworkService] HTTP Status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 429:
                throw FISNetworkError.rateLimited
            case 403:
                Log.network.debug("[FISNetworkService] 403 Forbidden - may need different User-Agent")
                throw FISNetworkError.httpError(403)
            default:
                throw FISNetworkError.httpError(httpResponse.statusCode)
            }
            
            // Try UTF-8 first, then ISO-8859-1 (FIS uses both)
            if let html = String(data: data, encoding: .utf8) {
                Log.network.debug("[FISNetworkService] Received \(html.count) characters (UTF-8)")
                return html
            } else if let html = String(data: data, encoding: .isoLatin1) {
                Log.network.debug("[FISNetworkService] Received \(html.count) characters (ISO-8859-1)")
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
