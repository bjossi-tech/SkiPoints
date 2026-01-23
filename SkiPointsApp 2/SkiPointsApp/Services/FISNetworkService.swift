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
            "User-Agent": "SkiPoints/1.0 iOS",
            "Accept": "text/html,application/xhtml+xml",
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
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        return try await fetchRaces(from: today, to: today)
    }
    
    /// Fetch races for a date range
    func fetchRaces(from startDate: String, to endDate: String) async throws -> [Race] {
        await waitForRateLimit()
        
        // FIS calendar URL with filters for alpine skiing
        let urlString = "\(baseURL)/DB/alpine-skiing/calendar-results.html?eventselection=&place=&session=&ression=&nationcode=&seasoncode=&categorycode=WC,EC,FIS&disciplinecode=&gession=&date_from=\(startDate)&date_to=\(endDate)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceCalendar(html: html)
    }
    
    /// Fetch full results for a specific race
    func fetchRaceResults(raceID: String) async throws -> [RaceResult] {
        await waitForRateLimit()
        
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)"
        
        guard let url = URL(string: urlString) else {
            throw FISNetworkError.invalidURL
        }
        
        let html = try await fetchHTML(from: url)
        return try FISHTMLParser.parseRaceResults(html: html, raceID: raceID)
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
        
        // FIS uses a different endpoint for live timing
        let urlString = "\(baseURL)/DB/general/results.html?sectorcode=AL&raceid=\(raceID)&type=result"
        
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
                return html
            } else if let html = String(data: data, encoding: .isoLatin1) {
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
