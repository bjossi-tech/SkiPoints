import Foundation

// MARK: - FIS HTML Parser

enum FISHTMLParser {
    
    // MARK: - Parse Race Calendar
    
    static func parseRaceCalendar(html: String) throws -> [Race] {
        var races: [Race] = []
        
        // Find race rows in the calendar table
        // FIS uses div.g-row for each race entry
        let racePattern = #"<div class="g-row[^"]*"[^>]*>.*?<a[^>]*href="[^"]*raceid=(\d+)"[^>]*>.*?</div>"#
        
        // Simplified pattern to extract key data
        let rows = html.components(separatedBy: "g-row justify-sb")
        
        for row in rows.dropFirst() { // Skip header
            if let race = parseRaceRow(html: row) {
                races.append(race)
            }
        }
        
        // If structured parsing fails, try regex fallback
        if races.isEmpty {
            races = try parseRaceCalendarRegex(html: html)
        }
        
        return races
    }
    
    private static func parseRaceRow(html: String) -> Race? {
        // Extract race ID from link
        guard let raceID = extractValue(from: html, pattern: #"raceid=(\d+)"#) else {
            return nil
        }
        
        // Extract location
        let location = extractValue(from: html, pattern: #"<span class="clip"[^>]*>([^<]+)</span>"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        
        // Extract nation (3-letter code)
        let nation = extractValue(from: html, pattern: #"\(([A-Z]{3})\)"#) ?? "---"
        
        // Extract discipline
        let disciplineCode = extractValue(from: html, pattern: #"<span class="[^"]*disc[^"]*"[^>]*>([A-Z]{2})</span>"#) ?? "GS"
        let discipline = Discipline(rawValue: disciplineCode) ?? .giantSlalom
        
        // Extract event type
        let eventTypeCode = extractValue(from: html, pattern: #"<span class="[^"]*event[^"]*"[^>]*>([A-Z]{2,3})</span>"#) ?? "FIS"
        let eventType = EventType(rawValue: eventTypeCode) ?? .fis
        
        // Extract gender
        let genderCode = extractValue(from: html, pattern: #"<span class="[^"]*gender[^"]*"[^>]*>([MW])</span>"#) ?? "M"
        let gender = Gender(rawValue: genderCode) ?? .men
        
        // Extract date
        let dateStr = extractValue(from: html, pattern: #"(\d{2}\s+[A-Za-z]{3}\s+\d{4})"#) ?? ""
        let date = parseDate(dateStr) ?? Date()
        
        // Extract status
        let status = parseRaceStatus(from: html)
        
        // Extract codex
        let codex = extractValue(from: html, pattern: #"codex[^>]*>(\d+)"#) ?? "0000"
        
        return Race(
            id: raceID,
            codex: codex,
            location: cleanLocation(location),
            nation: nation,
            date: date,
            eventType: eventType,
            discipline: discipline,
            gender: gender,
            status: status,
            results: []
        )
    }
    
    private static func parseRaceCalendarRegex(html: String) throws -> [Race] {
        var races: [Race] = []
        
        // Pattern to find race links with IDs
        let linkPattern = #"href="[^"]*raceid=(\d+)[^"]*"[^>]*>([^<]*)</a>"#
        let regex = try NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive])
        let range = NSRange(html.startIndex..., in: html)
        
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let idRange = Range(match.range(at: 1), in: html) {
                let raceID = String(html[idRange])
                
                // Create a minimal race entry - full details fetched on demand
                let race = Race(
                    id: raceID,
                    codex: "0000",
                    location: "Loading...",
                    nation: "---",
                    date: Date(),
                    eventType: .fis,
                    discipline: .giantSlalom,
                    gender: .men,
                    status: .scheduled,
                    results: []
                )
                
                // Avoid duplicates
                if !races.contains(where: { $0.id == raceID }) {
                    races.append(race)
                }
            }
        }
        
        return races
    }
    
    // MARK: - Parse Race Results
    
    static func parseRaceResults(html: String, raceID: String) throws -> [RaceResult] {
        var results: [RaceResult] = []
        
        // Find the results table
        // FIS uses table.g-table or similar structures
        let rows = html.components(separatedBy: "<tr")
        
        for row in rows {
            // Skip header rows
            if row.contains("<th") || !row.contains("competitor") {
                continue
            }
            
            if let result = parseResultRow(html: row, raceID: raceID) {
                results.append(result)
            }
        }
        
        return results.sorted { $0.rank < $1.rank }
    }
    
    private static func parseResultRow(html: String, raceID: String) -> RaceResult? {
        // Extract rank
        guard let rankStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*rank[^"]*"[^>]*>(\d+)"#),
              let rank = Int(rankStr) else {
            return nil
        }
        
        // Extract bib
        let bibStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*bib[^"]*"[^>]*>(\d+)"#) ?? "0"
        let bib = Int(bibStr) ?? 0
        
        // Extract athlete FIS code from link
        guard let fisCode = extractValue(from: html, pattern: #"competitorid=(\d+)"#) else {
            return nil
        }
        
        // Extract athlete name
        let fullName = extractValue(from: html, pattern: #"<span class="[^"]*name[^"]*"[^>]*>([^<]+)</span>"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.dropLast().joined(separator: " ")
        let lastName = nameParts.last ?? fullName
        
        // Extract nation
        let nation = extractValue(from: html, pattern: #"\(([A-Z]{3})\)"#) ?? "---"
        
        // Extract time
        let timeStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*time[^"]*"[^>]*>([\d:\.]+)"#)
        let timeSeconds = parseTime(timeStr)
        
        // Extract difference
        let diffStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*diff[^"]*"[^>]*>\+?([\d\.]+)"#)
        let diffSeconds = diffStr.flatMap { Double($0) }
        
        // Extract FIS points
        let pointsStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*fis-points[^"]*"[^>]*>([\d\.]+)"#)
        let fisPoints = pointsStr.flatMap { Double($0) } ?? 0.0
        
        // Determine status
        let status: ResultStatus
        if html.contains("DNF") {
            status = .didNotFinish
        } else if html.contains("DNS") {
            status = .didNotStart
        } else if html.contains("DSQ") {
            status = .disqualified
        } else {
            status = .finished
        }
        
        // Extract World Cup points if present
        let cupPointsStr = extractValue(from: html, pattern: #"<td[^>]*class="[^"]*wc-points[^"]*"[^>]*>(\d+)"#)
        let cupPoints = cupPointsStr.flatMap { Int($0) } ?? 0
        
        let athlete = Athlete(
            fisCode: fisCode,
            firstName: firstName.isEmpty ? "Unknown" : firstName,
            lastName: lastName,
            nation: nation,
            yearOfBirth: 1990, // Will be fetched separately if needed
            gender: .men // Determined from race context
        )
        
        return RaceResult(
            raceID: raceID,
            rank: rank,
            bib: bib,
            athlete: athlete,
            timeSeconds: timeSeconds,
            differenceSeconds: diffSeconds,
            status: status,
            fisPoints: fisPoints,
            cupPoints: cupPoints
        )
    }
    
    // MARK: - Parse Athlete Biography
    
    static func parseAthleteBiography(html: String, fisCode: String) throws -> Athlete {
        // Extract name
        let fullName = extractValue(from: html, pattern: #"<h1[^>]*class="[^"]*athlete-name[^"]*"[^>]*>([^<]+)</h1>"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Athlete"
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.dropLast().joined(separator: " ")
        let lastName = nameParts.last ?? fullName
        
        // Extract nation
        let nation = extractValue(from: html, pattern: #"<span class="[^"]*country[^"]*"[^>]*>([A-Z]{3})</span>"#) ?? "---"
        
        // Extract birth year
        let birthStr = extractValue(from: html, pattern: #"Birthdate[^<]*<[^>]*>(\d{4})"#)
        let yearOfBirth = birthStr.flatMap { Int($0) } ?? 1990
        
        // Extract gender
        let genderStr = extractValue(from: html, pattern: #"Gender[^<]*<[^>]*>([^<]+)"#) ?? "Male"
        let gender: Gender = genderStr.lowercased().contains("female") ? .women : .men
        
        // Extract ski brand
        let skiBrand = extractValue(from: html, pattern: #"Skis[^<]*<[^>]*>([^<]+)"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract current FIS points (if shown)
        let pointsStr = extractValue(from: html, pattern: #"FIS Points[^<]*<[^>]*>([\d\.]+)"#)
        let currentFISPoints = pointsStr.flatMap { Double($0) }
        
        return Athlete(
            fisCode: fisCode,
            firstName: firstName,
            lastName: lastName,
            nation: nation,
            yearOfBirth: yearOfBirth,
            gender: gender,
            skiBrand: skiBrand,
            currentFISPoints: currentFISPoints
        )
    }
    
    // MARK: - Helper Methods
    
    private static func extractValue(from html: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[valueRange])
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "dd MMM yyyy",
            "yyyy-MM-dd",
            "dd.MM.yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private static func parseTime(_ timeString: String?) -> TimeInterval? {
        guard let time = timeString else { return nil }
        
        let parts = time.components(separatedBy: ":")
        
        if parts.count == 2 {
            // Format: M:SS.ss
            guard let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        } else if parts.count == 1 {
            // Format: SS.ss
            return Double(parts[0])
        }
        
        return nil
    }
    
    private static func parseRaceStatus(from html: String) -> RaceStatus {
        let lowercased = html.lowercased()
        
        if lowercased.contains("official") || lowercased.contains("final") {
            return .official
        } else if lowercased.contains("live") || lowercased.contains("progress") {
            return .inProgress
        } else if lowercased.contains("unofficial") || lowercased.contains("finished") {
            return .finished
        } else if lowercased.contains("cancelled") {
            return .cancelled
        }
        
        return .scheduled
    }
    
    private static func cleanLocation(_ location: String) -> String {
        // Remove extra whitespace and common suffixes
        var cleaned = location
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove trailing nation code if present
        if let range = cleaned.range(of: #"\s*\([A-Z]{3}\)\s*$"#, options: .regularExpression) {
            cleaned = String(cleaned[..<range.lowerBound])
        }
        
        return cleaned
    }
}

// MARK: - EventType Extension

extension EventType {
    var shortName: String {
        rawValue
    }
}
