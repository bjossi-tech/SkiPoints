import Foundation

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
    
    private let baseURL = "https://www.fis-ski.com"
    private let session: URLSession
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.5 // Rate limiting
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9"
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
    
    // MARK: - Fetch Methods
    
    /// Fetch today's races from the FIS calendar
    func fetchTodaysRaces() async throws -> [Race] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let today = dateFormatter.string(from: Date())
        
        return try await fetchRaces(forDate: today)
    }
    
    /// Fetch races for a specific date (format: dd.MM.yyyy)
    func fetchRaces(forDate dateString: String) async throws -> [Race] {
        await waitForRateLimit()
        
        // Extract month and year for seasonmonth parameter
        let parts = dateString.split(separator: ".")
        let seasonMonth = parts.count >= 3 ? "\(parts[1])-\(parts[2])" : "01-2026"
        let seasonCode = parts.count >= 3 ? String(parts[2]) : "2026"
        
        // FIS calendar URL with proper parameters for alpine skiing
        let urlString = "\(baseURL)/DB/general/calendar-results.html?sectorcode=AL&seasoncode=\(seasonCode)&racedate=\(dateString)&seasonmonth=\(seasonMonth)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        print("[FISNetworkService] Fetching races from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceCalendar(html: html)
    }
    
    /// Fetch races for a date range
    func fetchRaces(from startDate: String, to endDate: String) async throws -> [Race] {
        // Convert from yyyy-MM-dd to dd.MM.yyyy if needed
        let convertedStart = convertDateFormat(startDate)
        return try await fetchRaces(forDate: convertedStart)
    }
    
    private func convertDateFormat(_ dateString: String) -> String {
        // If already in dd.MM.yyyy format, return as is
        if dateString.contains(".") {
            return dateString
        }
        
        // Convert from yyyy-MM-dd to dd.MM.yyyy
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
    
    /// Fetch full results for a specific race/event
    func fetchRaceResults(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        print("[FISNetworkService] Fetching race results from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
    }
    
    /// Fetch event details (which contains individual races)
    func fetchEventDetails(eventID: String) async throws -> [Race] {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/event-details.html?sectorcode=AL&eventid=\(eventID)&seasoncode=2026"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        print("[FISNetworkService] Fetching event details from: \(urlString)")
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseEventDetails(html: html, eventID: eventID)
    }
    
    /// Fetch athlete details
    func fetchAthlete(fisCode: String) async throws -> Athlete {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/athlete-biography.html?sectorcode=AL&competitorid=\(fisCode)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseAthleteBiography(html: html, fisCode: fisCode)
    }
    
    /// Fetch live/startlist data for an ongoing race
    func fetchLiveData(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
    }
    
    // MARK: - Private Helpers
    
    private func fetchHTML(from url: URL) async throws -> String {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FISNetworkError.invalidResponse
            }
            
            print("[FISNetworkService] HTTP Status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 429:
                throw FISNetworkError.rateLimited
            default:
                throw FISNetworkError.httpError(httpResponse.statusCode)
            }
            
            // Try different encodings - FIS sometimes uses ISO-8859-1
            if let html = String(data: data, encoding: .utf8) {
                print("[FISNetworkService] Received \(html.count) characters")
                return html
            } else if let html = String(data: data, encoding: .isoLatin1) {
                print("[FISNetworkService] Received \(html.count) characters (Latin1)")
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
