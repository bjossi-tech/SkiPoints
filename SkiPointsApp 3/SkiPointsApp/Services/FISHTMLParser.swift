import Foundation

// MARK: - FIS HTML Parser

enum FISHTMLParser {
    
    // MARK: - Parse Race Calendar
    
    static func parseRaceCalendar(html: String) throws -> [Race] {
        var races: [Race] = []
        
        print("[FISHTMLParser] Parsing calendar HTML (\(html.count) chars)")
        
        // Find all event links in the calendar
        // Pattern matches: event-details.html?sectorcode=AL&eventid=XXXXX
        let eventPattern = #"event-details\.html\?sectorcode=AL&eventid=(\d+)&seasoncode=\d+"#
        
        guard let eventRegex = try? NSRegularExpression(pattern: eventPattern, options: [.caseInsensitive]) else {
            throw FISNetworkError.parsingError("Failed to create event regex")
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let eventMatches = eventRegex.matches(in: html, options: [], range: range)
        
        // Get unique event IDs
        var seenEventIDs = Set<String>()
        var eventIDs: [String] = []
        
        for match in eventMatches {
            if let idRange = Range(match.range(at: 1), in: html) {
                let eventID = String(html[idRange])
                if !seenEventIDs.contains(eventID) {
                    seenEventIDs.insert(eventID)
                    eventIDs.append(eventID)
                }
            }
        }
        
        print("[FISHTMLParser] Found \(eventIDs.count) unique events")
        
        // Parse each event from the calendar data
        // The HTML contains blocks for each event with location, nation, discipline, etc.
        for eventID in eventIDs {
            if let race = parseEventFromCalendar(html: html, eventID: eventID) {
                races.append(race)
            }
        }
        
        // Sort by status (live first) then by date
        races.sort { race1, race2 in
            if race1.status.isLive && !race2.status.isLive { return true }
            if !race1.status.isLive && race2.status.isLive { return false }
            return race1.date < race2.date
        }
        
        print("[FISHTMLParser] Parsed \(races.count) races")
        
        return races
    }
    
    private static func parseEventFromCalendar(html: String, eventID: String) -> Race? {
        // The HTML from web_fetch is converted to markdown-like format
        // Pattern: [text](url) where url contains eventid
        
        // Find all lines/blocks related to this event
        let eventURLPattern = "eventid=\(eventID)"
        let lines = html.components(separatedBy: "\n")
        var eventContext: [String] = []
        
        for (index, line) in lines.enumerated() {
            if line.contains(eventURLPattern) {
                // Grab surrounding context
                let startIdx = max(0, index - 2)
                let endIdx = min(lines.count - 1, index + 2)
                for i in startIdx...endIdx {
                    eventContext.append(lines[i])
                }
            }
        }
        
        let context = eventContext.joined(separator: "\n")
        
        if context.isEmpty {
            // Fallback: search in full HTML
            return parseEventFallback(html: html, eventID: eventID)
        }
        
        // Extract location from [Location](url) or [Location WC/EC/FIS...](url) pattern
        var location = "Unknown"
        
        // Pattern 1: [Location](eventid=XXXX) - simple location name
        let simpleLocPattern = #"\[([A-Z][a-z]+(?:[ -][A-Za-z]+)*)\]\([^)]*eventid=\#(eventID)"#
        if let loc = extractValue(from: context, pattern: simpleLocPattern) {
            let cleaned = loc.trimmingCharacters(in: .whitespacesAndNewlines)
            // Filter out non-location matches
            if cleaned.count > 2 && cleaned.count < 40 &&
               !["AL", "WC", "EC", "FIS", "TRA", "NJC", "NJR", "NC", "UNI"].contains(cleaned) &&
               !cleaned.hasPrefix("D ") && !cleaned.hasPrefix("D\n") {
                location = cleaned
            }
        }
        
        // Pattern 2: [Location with more text WC/EC...](url)
        if location == "Unknown" {
            let fullLocPattern = #"\[([A-Z][a-z]+(?:[ -/][A-Za-z]+)*)\s+(?:WC|EC|FIS|NC|NJC|NJR|TRA|UNI)"#
            if let loc = extractValue(from: context, pattern: fullLocPattern) {
                location = loc.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Fallback: Look for known ski resort names
        if location == "Unknown" {
            let knownLocations = [
                "Kitzbuehel", "Kitzbühel", "Wengen", "Chamonix", "Cortina", "St. Moritz",
                "Val d'Isere", "Garmisch-Partenkirchen", "Garmisch", "Schladming", "Adelboden",
                "Courchevel", "Beaver Creek", "Lake Louise", "Hafjell", "Kvitfjell",
                "Are", "Saalbach", "Flachau", "Kronplatz", "Plan de Corones",
                "Kranjska Gora", "Meribel", "Val Gardena", "Alta Badia",
                "Madonna di Campiglio", "Hinterstoder", "Mont Garceau", "Mont Blanc",
                "El Tarter", "Schwende", "Gressan-Pila", "Jahorina", "Gaellivare",
                "Whiteface Mountain", "Whiteface", "Stowe Mountain Resort", "Stowe",
                "Pozza di Fassa", "Vail", "Steamboat", "Engaru", "Nozawa Onsen",
                "Yongpyong", "Hounokidaira", "Kijima", "Arxhena"
            ]
            
            for known in knownLocations {
                if context.localizedCaseInsensitiveContains(known) {
                    location = known
                    break
                }
            }
        }
        
        // Extract nation (3-letter code) - pattern: [AUT] or similar
        var nation = "---"
        let nationPattern = #"\[([A-Z]{3})\]"#
        if let n = extractValue(from: context, pattern: nationPattern) {
            nation = n
        }
        
        // Extract discipline from context
        var discipline: Discipline = .giantSlalom
        // Check for discipline codes - order matters (check longer patterns first)
        if context.contains("DH") || context.localizedCaseInsensitiveContains("Downhill") {
            discipline = .downhill
        } else if context.contains("SG") || context.localizedCaseInsensitiveContains("Super G") {
            discipline = .superG
        } else if context.contains("SL") || context.localizedCaseInsensitiveContains("Slalom") {
            discipline = .slalom
        } else if context.contains("GS") || context.localizedCaseInsensitiveContains("Giant") {
            discipline = .giantSlalom
        }
        
        // Extract event type
        var eventType: EventType = .fis
        if context.contains(" WC ") || context.contains("[WC]") || context.contains("WC •") ||
           context.localizedCaseInsensitiveContains("World Cup") {
            eventType = .worldCup
        } else if context.contains(" EC ") || context.contains("[EC]") || context.contains("EC •") ||
                  context.localizedCaseInsensitiveContains("Europa Cup") {
            eventType = .europaCup
        }
        
        // Extract gender - check for W or M indicators
        var gender: Gender = .men
        // Check for women-only indicators
        if (context.contains("[W]") || context.contains("\nW\n") || context.contains("AL\n\nW")) &&
           !(context.contains("[M]") || context.contains("\nM\n") || context.contains("AL\n\nM")) {
            gender = .women
        }
        
        // Determine status - check for "live" indicator
        var status: RaceStatus = .scheduled
        if context.localizedCaseInsensitiveContains("live") {
            status = .inProgress
        } else if context.localizedCaseInsensitiveContains("official") ||
                  context.localizedCaseInsensitiveContains("final") {
            status = .official
        } else if context.localizedCaseInsensitiveContains("cancelled") {
            status = .cancelled
        }
        
        // Parse date from context (format: "23 Jan" or "23-24 Jan")
        var date = Date()
        let datePattern = #"(\d{1,2})(?:-\d{1,2})?\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"#
        if let dateStr = extractValue(from: context, pattern: datePattern) {
            // Extract just the first day and month
            let cleanPattern = #"(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"#
            if let cleanMatch = extractValue(from: dateStr + " Jan", pattern: cleanPattern) {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                formatter.locale = Locale(identifier: "en_US")
                // Use current year
                let year = Calendar.current.component(.year, from: Date())
                if let parsed = formatter.date(from: "\(cleanMatch) \(year)") {
                    date = parsed
                }
            }
        }
        
        print("[FISHTMLParser] Parsed event \(eventID): \(location) (\(nation)) - \(discipline.rawValue) \(eventType.rawValue) - \(status.rawValue)")
        
        return Race(
            id: eventID,
            codex: String(eventID.suffix(4)),
            location: location,
            nation: nation,
            date: date,
            eventType: eventType,
            discipline: discipline,
            gender: gender,
            status: status,
            results: []
        )
    }
    
    private static func parseEventFallback(html: String, eventID: String) -> Race? {
        // Simple fallback parser
        let eventURLPattern = "eventid=\(eventID)"
        
        guard html.contains(eventURLPattern) else {
            return nil
        }
        
        // Check if live
        let isLive = html.localizedCaseInsensitiveContains("\(eventID)") &&
                     html.localizedCaseInsensitiveContains("live")
        
        return Race(
            id: eventID,
            codex: String(eventID.suffix(4)),
            location: "Event \(eventID)",
            nation: "---",
            date: Date(),
            eventType: .fis,
            discipline: .giantSlalom,
            gender: .men,
            status: isLive ? .inProgress : .scheduled,
            results: []
        )
    }
    
    // MARK: - Parse Event Details Page
    
    static func parseEventDetails(html: String, eventID: String) throws -> [Race] {
        var races: [Race] = []
        
        // Look for individual race links within the event
        // Pattern: results.html?sectorcode=AL&raceid=XXXXX
        let racePattern = #"results\.html\?sectorcode=AL&raceid=(\d+)"#
        
        guard let raceRegex = try? NSRegularExpression(pattern: racePattern, options: [.caseInsensitive]) else {
            return races
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = raceRegex.matches(in: html, options: [], range: range)
        
        var seenRaceIDs = Set<String>()
        
        for match in matches {
            if let idRange = Range(match.range(at: 1), in: html) {
                let raceID = String(html[idRange])
                if !seenRaceIDs.contains(raceID) {
                    seenRaceIDs.insert(raceID)
                    
                    // Create a race entry for each unique race ID
                    let race = Race(
                        id: raceID,
                        codex: String(raceID.suffix(4)),
                        location: "Loading...",
                        nation: "---",
                        date: Date(),
                        eventType: .fis,
                        discipline: .giantSlalom,
                        gender: .men,
                        status: .scheduled,
                        results: []
                    )
                    races.append(race)
                }
            }
        }
        
        return races
    }
    
    // MARK: - Parse Race Results
    
    static func parseRaceResults(html: String, raceID: String) throws -> [RaceResult] {
        var results: [RaceResult] = []
        
        print("[FISHTMLParser] Parsing results for race \(raceID)")
        
        // Find result rows in the HTML
        // FIS uses table rows with competitor data
        let rowPattern = #"<tr[^>]*>.*?competitorid=(\d+).*?</tr>"#
        
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return results
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = rowRegex.matches(in: html, options: [], range: range)
        
        var rank = 1
        for match in matches {
            if let fullRange = Range(match.range, in: html),
               let fisCodeRange = Range(match.range(at: 1), in: html) {
                
                let rowHTML = String(html[fullRange])
                let fisCode = String(html[fisCodeRange])
                
                if let result = parseResultRow(html: rowHTML, raceID: raceID, fisCode: fisCode, rank: rank) {
                    results.append(result)
                    rank += 1
                }
            }
        }
        
        // If no results found with table pattern, try alternative parsing
        if results.isEmpty {
            results = try parseResultsAlternative(html: html, raceID: raceID)
        }
        
        return results.sorted { $0.rank < $1.rank }
    }
    
    private static func parseResultRow(html: String, raceID: String, fisCode: String, rank: Int) -> RaceResult? {
        // Extract athlete name
        let namePattern = #"<span[^>]*>([^<]+)</span>"#
        let name = extractValue(from: html, pattern: namePattern) ?? "Unknown"
        
        let nameParts = name.components(separatedBy: " ")
        let firstName = nameParts.dropLast().joined(separator: " ")
        let lastName = nameParts.last ?? name
        
        // Extract nation
        let nationPattern = #"\(([A-Z]{3})\)"#
        let nation = extractValue(from: html, pattern: nationPattern) ?? "---"
        
        // Extract time
        let timePattern = #">(\d+:\d+\.\d+|\d+\.\d+)<"#
        let timeStr = extractValue(from: html, pattern: timePattern)
        let timeSeconds = parseTime(timeStr)
        
        // Extract bib number
        let bibPattern = #"<td[^>]*>\s*(\d{1,3})\s*</td>"#
        let bibStr = extractValue(from: html, pattern: bibPattern) ?? "0"
        let bib = Int(bibStr) ?? 0
        
        // Determine status
        var status: ResultStatus = .finished
        if html.contains("DNF") {
            status = .didNotFinish
        } else if html.contains("DNS") {
            status = .didNotStart
        } else if html.contains("DSQ") {
            status = .disqualified
        }
        
        let athlete = Athlete(
            fisCode: fisCode,
            firstName: firstName.isEmpty ? "Unknown" : firstName,
            lastName: lastName,
            nation: nation,
            yearOfBirth: 1990,
            gender: .men
        )
        
        return RaceResult(
            raceID: raceID,
            rank: rank,
            bib: bib,
            athlete: athlete,
            timeSeconds: timeSeconds,
            differenceSeconds: nil,
            status: status,
            fisPoints: 0.0,
            cupPoints: 0
        )
    }
    
    private static func parseResultsAlternative(html: String, raceID: String) throws -> [RaceResult] {
        var results: [RaceResult] = []
        
        // Alternative: look for competitor links
        let competitorPattern = #"competitorid=(\d+)[^>]*>([^<]+)</a>"#
        
        guard let regex = try? NSRegularExpression(pattern: competitorPattern, options: [.caseInsensitive]) else {
            return results
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        var rank = 1
        var seenCodes = Set<String>()
        
        for match in matches {
            if let codeRange = Range(match.range(at: 1), in: html),
               let nameRange = Range(match.range(at: 2), in: html) {
                
                let fisCode = String(html[codeRange])
                let fullName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip duplicates
                if seenCodes.contains(fisCode) { continue }
                seenCodes.insert(fisCode)
                
                let nameParts = fullName.components(separatedBy: " ")
                let firstName = nameParts.dropLast().joined(separator: " ")
                let lastName = nameParts.last ?? fullName
                
                let athlete = Athlete(
                    fisCode: fisCode,
                    firstName: firstName.isEmpty ? "Unknown" : firstName,
                    lastName: lastName,
                    nation: "---",
                    yearOfBirth: 1990,
                    gender: .men
                )
                
                let result = RaceResult(
                    raceID: raceID,
                    rank: rank,
                    bib: rank,
                    athlete: athlete,
                    timeSeconds: nil,
                    differenceSeconds: nil,
                    status: .finished,
                    fisPoints: 0.0,
                    cupPoints: 0
                )
                
                results.append(result)
                rank += 1
            }
        }
        
        return results
    }
    
    // MARK: - Parse Athlete Biography
    
    static func parseAthleteBiography(html: String, fisCode: String) throws -> Athlete {
        // Extract name
        let fullName = extractValue(from: html, pattern: #"<h1[^>]*>([^<]+)</h1>"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Athlete"
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.dropLast().joined(separator: " ")
        let lastName = nameParts.last ?? fullName
        
        // Extract nation
        let nation = extractValue(from: html, pattern: #"\(([A-Z]{3})\)"#) ?? "---"
        
        // Extract birth year
        let birthStr = extractValue(from: html, pattern: #"(\d{4})"#)
        let yearOfBirth = birthStr.flatMap { Int($0) } ?? 1990
        
        // Extract gender
        let genderStr = extractValue(from: html, pattern: #"Gender[^<]*<[^>]*>([^<]+)"#) ?? "Male"
        let gender: Gender = genderStr.lowercased().contains("female") ? .women : .men
        
        // Extract ski brand
        let skiBrand = extractValue(from: html, pattern: #"Skis[^<]*<[^>]*>([^<]+)"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract current FIS points
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
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[valueRange])
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
}

// MARK: - EventType Extension

extension EventType {
    var shortName: String {
        rawValue
    }
}
