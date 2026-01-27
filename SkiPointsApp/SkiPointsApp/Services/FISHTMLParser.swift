import Foundation
import os

/// Parser for FIS website HTML content.
/// Note: The FIS website is built with React/Next.js and much of the content
/// is rendered client-side. This parser handles the server-rendered portions.
struct FISHTMLParser {

    // MARK: - Parse Calendar Events

    /// Parse events from the FIS calendar page.
    /// Events contain multiple races (e.g., Men's GS, Women's GS, etc.)
    static func parseCalendarEvents(html: String) throws -> [Race] {
        var events: [Race] = []

        AppLogger.parser.info("Parsing calendar HTML (\(html.count) chars)")

        // FIS calendar structure:
        // Links follow pattern: /DB/general/event-details.html?sectorcode=AL&eventid=58544&seasoncode=2026
        let eventPattern = #"event-details\.html\?sectorcode=AL&eventid=(\d+)&seasoncode=(\d+)"#

        let eventRegex = try buildRegex(pattern: eventPattern, context: "calendar event")

        let range = NSRange(html.startIndex..., in: html)
        let matches = eventRegex.matches(in: html, options: [], range: range)

        AppLogger.parser.info("Found \(matches.count) event links")

        var seenEventIDs = Set<String>()

        for match in matches {
            guard let eventIDRange = Range(match.range(at: 1), in: html),
                  let seasonRange = Range(match.range(at: 2), in: html) else {
                continue
            }

            let eventID = String(html[eventIDRange])
            _ = String(html[seasonRange]) // seasonCode extracted but not currently used

            // Skip duplicates (same event appears multiple times)
            if seenEventIDs.contains(eventID) {
                continue
            }
            seenEventIDs.insert(eventID)

            // Find the surrounding context for this event to extract metadata
            if let eventInfo = extractEventContext(html: html, eventID: eventID, matchRange: match.range) {
                let race = Race(
                    id: eventID,
                    codex: eventInfo.codex ?? eventID,
                    location: eventInfo.location ?? "Unknown Location",
                    nation: eventInfo.nation ?? "---",
                    date: eventInfo.date ?? Date(),
                    eventType: eventInfo.eventType ?? .fis,
                    discipline: eventInfo.discipline ?? .giantSlalom,
                    gender: eventInfo.gender ?? .men,
                    status: eventInfo.status ?? .scheduled,
                    results: []
                )
                events.append(race)
            }
        }

        AppLogger.parser.info("Parsed \(events.count) unique events")
        return events
    }

    // MARK: - Extract Event Context

    private struct EventInfo {
        var codex: String?
        var location: String?
        var nation: String?
        var date: Date?
        var eventType: EventType?
        var discipline: Discipline?
        var gender: Gender?
        var status: RaceStatus?
    }

    private static func extractEventContext(html: String, eventID: String, matchRange: NSRange) -> EventInfo? {
        // Use named constants for the context window offsets.
        // These define how many characters before/after the match to search for metadata.
        let leading = AppConstants.HTMLParser.eventContextLeadingOffset
        let trailing = AppConstants.HTMLParser.eventContextTrailingOffset

        let searchStart = max(0, matchRange.location - leading)
        let searchEnd = min(html.count, matchRange.location + matchRange.length + trailing)

        guard let startIndex = html.index(html.startIndex, offsetBy: searchStart, limitedBy: html.endIndex),
              let endIndex = html.index(html.startIndex, offsetBy: searchEnd, limitedBy: html.endIndex) else {
            AppLogger.parser.warning("Could not compute context window for event \(eventID)")
            return nil
        }

        let context = String(html[startIndex..<endIndex])

        var info = EventInfo()

        // Extract location
        if let location = extractFirstMatch(from: context, pattern: #"\[([A-Za-z\s\-\.]+(?:\s+\([A-Z]{3}\))?)\]"#) {
            info.location = location.trimmingCharacters(in: .whitespaces)
        } else if let location = extractFirstMatch(from: context, pattern: #"eventid=\d+[^>]*>([^<]+)</a>"#) {
            info.location = cleanLocation(location)
        }

        // Extract nation code (3 letters in brackets or standalone)
        if let nation = extractFirstMatch(from: context, pattern: #"\[([A-Z]{3})\]"#) {
            info.nation = nation
        } else if let nation = extractFirstMatch(from: context, pattern: #">([A-Z]{3})</a>"#) {
            info.nation = nation
        }

        // Extract date
        info.date = parseEventDate(from: context)

        // Extract event type (WC, EC, FIS, etc.)
        info.eventType = parseEventType(from: context)

        // Extract discipline (GS, SL, SG, DH, etc.)
        info.discipline = parseDiscipline(from: context)

        // Extract gender
        info.gender = parseGender(from: context)

        // Determine status (live, finished, scheduled)
        info.status = parseStatus(from: context)

        return info
    }

    // MARK: - Parse Event Details

    /// Parse individual races from an event details page
    static func parseEventDetails(html: String, eventID: String) throws -> [Race] {
        var races: [Race] = []

        AppLogger.parser.info("Parsing event details for event \(eventID)")

        // Look for race links within the event page
        let racePattern = #"results\.html\?sectorcode=AL&raceid=(\d+)"#

        let raceRegex = try buildRegex(pattern: racePattern, context: "race details")

        let range = NSRange(html.startIndex..., in: html)
        let matches = raceRegex.matches(in: html, options: [], range: range)

        var seenRaceIDs = Set<String>()

        for match in matches {
            guard let idRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let raceID = String(html[idRange])

            if seenRaceIDs.contains(raceID) {
                continue
            }
            seenRaceIDs.insert(raceID)

            // Extract race details from context
            let raceInfo = extractRaceContext(html: html, raceID: raceID, matchRange: match.range)

            let race = Race(
                id: raceID,
                codex: raceInfo?.codex ?? raceID,
                location: raceInfo?.location ?? "Unknown",
                nation: raceInfo?.nation ?? "---",
                date: raceInfo?.date ?? Date(),
                eventType: raceInfo?.eventType ?? .fis,
                discipline: raceInfo?.discipline ?? .giantSlalom,
                gender: raceInfo?.gender ?? .men,
                status: raceInfo?.status ?? .scheduled,
                results: []
            )
            races.append(race)
        }

        AppLogger.parser.info("Found \(races.count) races in event")
        return races
    }

    private static func extractRaceContext(html: String, raceID: String, matchRange: NSRange) -> EventInfo? {
        let leading = AppConstants.HTMLParser.raceContextLeadingOffset
        let trailing = AppConstants.HTMLParser.raceContextTrailingOffset

        let searchStart = max(0, matchRange.location - leading)
        let searchEnd = min(html.count, matchRange.location + matchRange.length + trailing)

        guard let startIndex = html.index(html.startIndex, offsetBy: searchStart, limitedBy: html.endIndex),
              let endIndex = html.index(html.startIndex, offsetBy: searchEnd, limitedBy: html.endIndex) else {
            AppLogger.parser.warning("Could not compute context window for race \(raceID)")
            return nil
        }

        let context = String(html[startIndex..<endIndex])

        var info = EventInfo()

        info.discipline = parseDiscipline(from: context)
        info.gender = parseGender(from: context)
        info.status = parseStatus(from: context)
        info.date = parseEventDate(from: context)

        // Try to extract location
        if let location = extractFirstMatch(from: context, pattern: #"<h[12][^>]*>([^<]+)</h[12]>"#) {
            info.location = cleanLocation(location)
        }

        return info
    }

    // MARK: - Parse Race Results

    /// Parse results from a race results page
    static func parseRaceResults(html: String, raceID: String) throws -> [RaceResult] {
        var results: [RaceResult] = []

        AppLogger.parser.info("Parsing results for race \(raceID)")

        // FIS results page has competitor rows with competitorid parameter
        let competitorPattern = #"competitorid=(\d+)[^>]*>([^<]*)</a>"#

        let regex = try buildRegex(pattern: competitorPattern, context: "competitor results")

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        var rank = 1
        var seenCompetitors = Set<String>()
        var winnerTime: TimeInterval?

        for match in matches {
            guard let competitorIDRange = Range(match.range(at: 1), in: html),
                  let nameRange = Range(match.range(at: 2), in: html) else {
                continue
            }

            let competitorID = String(html[competitorIDRange])
            let fullName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip duplicates
            if seenCompetitors.contains(competitorID) {
                continue
            }
            seenCompetitors.insert(competitorID)

            // Parse the result row context
            let resultInfo = extractResultContext(html: html, competitorID: competitorID, matchRange: match.range, rank: rank)

            // Parse name
            let (firstName, lastName) = parseName(fullName)

            // Determine time
            let timeSeconds = resultInfo?.timeSeconds
            if rank == 1, let time = timeSeconds {
                winnerTime = time
            }

            // Calculate difference from winner
            var differenceSeconds: TimeInterval?
            if let time = timeSeconds, let winner = winnerTime, rank > 1 {
                differenceSeconds = time - winner
            }

            let athlete = Athlete(
                fisCode: competitorID,
                firstName: firstName,
                lastName: lastName,
                nation: resultInfo?.nation ?? "---",
                yearOfBirth: resultInfo?.yearOfBirth ?? 1990,
                gender: resultInfo?.gender ?? .men
            )

            let result = RaceResult(
                raceID: raceID,
                rank: rank,
                bib: resultInfo?.bib ?? rank,
                athlete: athlete,
                timeSeconds: timeSeconds,
                differenceSeconds: differenceSeconds,
                status: resultInfo?.resultStatus ?? .finished,
                fisPoints: 0.0,  // Will be calculated
                cupPoints: 0
            )

            results.append(result)
            rank += 1
        }

        AppLogger.parser.info("Parsed \(results.count) results")
        return results
    }

    private struct ResultInfo {
        var timeSeconds: TimeInterval?
        var nation: String?
        var bib: Int?
        var yearOfBirth: Int?
        var gender: Gender?
        var resultStatus: ResultStatus?
    }

    private static func extractResultContext(html: String, competitorID: String, matchRange: NSRange, rank: Int) -> ResultInfo? {
        // Get the row containing this result
        let rowStart = html.range(of: "<tr", options: .backwards, range: html.startIndex..<html.index(html.startIndex, offsetBy: matchRange.location))?.lowerBound ?? html.startIndex
        let rowEnd = html.range(of: "</tr>", range: html.index(html.startIndex, offsetBy: matchRange.location)..<html.endIndex)?.upperBound ?? html.endIndex

        let rowHTML = String(html[rowStart..<rowEnd])

        var info = ResultInfo()

        // Extract time (format: MM:SS.ss or S.ss)
        if let timeStr = extractFirstMatch(from: rowHTML, pattern: #">(\d{1,2}:\d{2}\.\d{2})<"#) {
            info.timeSeconds = parseTime(timeStr)
        } else if let timeStr = extractFirstMatch(from: rowHTML, pattern: #">(\d+\.\d{2})<"#) {
            info.timeSeconds = parseTime(timeStr)
        }

        // Extract nation (3-letter code)
        if let nation = extractFirstMatch(from: rowHTML, pattern: #"\(([A-Z]{3})\)"#) {
            info.nation = nation
        } else if let nation = extractFirstMatch(from: rowHTML, pattern: #">([A-Z]{3})<"#) {
            info.nation = nation
        }

        // Extract bib number
        if let bibStr = extractFirstMatch(from: rowHTML, pattern: #"<td[^>]*>\s*(\d{1,3})\s*</td>"#) {
            info.bib = Int(bibStr)
        }

        // Extract birth year
        if let yearStr = extractFirstMatch(from: rowHTML, pattern: #"\b(19\d{2}|20[012]\d)\b"#) {
            info.yearOfBirth = Int(yearStr)
        }

        // Determine status
        if rowHTML.contains("DNF") {
            info.resultStatus = .didNotFinish
        } else if rowHTML.contains("DNS") {
            info.resultStatus = .didNotStart
        } else if rowHTML.contains("DSQ") || rowHTML.contains("DQ") {
            info.resultStatus = .disqualified
        } else {
            info.resultStatus = .finished
        }

        return info
    }

    // MARK: - Parse Athlete Biography

    /// Parse athlete details from biography page
    static func parseAthleteBiography(html: String, competitorID: String) throws -> Athlete {
        AppLogger.parser.info("Parsing athlete biography for \(competitorID)")

        // Extract name
        var firstName = "Unknown"
        var lastName = "Athlete"
        if let fullName = extractFirstMatch(from: html, pattern: #"<h1[^>]*>([^<]+)</h1>"#) {
            let (first, last) = parseName(fullName)
            firstName = first
            lastName = last
        }

        // Extract nation
        let nation = extractFirstMatch(from: html, pattern: #"Nation[^<]*<[^>]*>([A-Z]{3})<"#) ?? "---"

        // Extract birth year
        let yearOfBirth = Int(extractFirstMatch(from: html, pattern: #"Birthdate[^<]*<[^>]*>\d{2}\s+[A-Za-z]{3}\s+(\d{4})"#) ?? "1990") ?? 1990

        // Extract gender
        let genderStr = extractFirstMatch(from: html, pattern: #"Gender[^<]*<[^>]*>([MWF])"#) ?? "M"
        let gender = Gender(rawValue: genderStr == "F" ? "W" : genderStr) ?? .men

        // Extract FIS points by discipline
        var fisPoints: [Discipline: Double] = [:]

        let disciplines: [(pattern: String, discipline: Discipline)] = [
            ("DH[^<]*<[^>]*>([0-9.]+)", .downhill),
            ("SL[^<]*<[^>]*>([0-9.]+)", .slalom),
            ("GS[^<]*<[^>]*>([0-9.]+)", .giantSlalom),
            ("SG[^<]*<[^>]*>([0-9.]+)", .superG)
        ]

        for (pattern, discipline) in disciplines {
            if let pointsStr = extractFirstMatch(from: html, pattern: pattern),
               let points = Double(pointsStr) {
                fisPoints[discipline] = points
            }
        }

        return Athlete(
            fisCode: competitorID,
            firstName: firstName,
            lastName: lastName,
            nation: nation,
            yearOfBirth: yearOfBirth,
            gender: gender,
            fisPoints: fisPoints
        )
    }

    // MARK: - Parse Athlete Search

    /// Parse athlete search results
    static func parseAthleteSearch(html: String) throws -> [Athlete] {
        var athletes: [Athlete] = []

        let competitorPattern = #"competitorid=(\d+)[^>]*>([^<]+)</a>[^<]*<[^>]*>([A-Z]{3})"#

        let regex = try buildRegex(pattern: competitorPattern, context: "athlete search")

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let idRange = Range(match.range(at: 1), in: html),
                  let nameRange = Range(match.range(at: 2), in: html),
                  let nationRange = Range(match.range(at: 3), in: html) else {
                continue
            }

            let competitorID = String(html[idRange])
            let fullName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let nation = String(html[nationRange])

            let (firstName, lastName) = parseName(fullName)

            let athlete = Athlete(
                fisCode: competitorID,
                firstName: firstName,
                lastName: lastName,
                nation: nation,
                yearOfBirth: 1990,
                gender: .men
            )
            athletes.append(athlete)
        }

        return athletes
    }

    // MARK: - Regex Builder

    /// Build a regex with proper error handling and logging instead of silent `try?`.
    /// Throws a `FISNetworkError.parsingError` with context on failure.
    private static func buildRegex(pattern: String, context: String) throws -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            AppLogger.parser.error("Failed to compile regex for \(context): \(error.localizedDescription). Pattern: \(pattern)")
            throw FISNetworkError.parsingError("Failed to create \(context) regex: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Functions

    private static func extractFirstMatch(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            AppLogger.parser.debug("Regex compilation failed for pattern in extractFirstMatch")
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[captureRange])
    }

    private static func cleanLocation(_ location: String) -> String {
        var clean = location
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")

        // Remove common prefixes/suffixes
        let prefixes = ["FIS", "WC", "EC", "NAC", "\u{2022}"] // last is bullet character
        for prefix in prefixes {
            if clean.hasPrefix(prefix) {
                clean = String(clean.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        return clean
    }

    private static func parseName(_ fullName: String) -> (firstName: String, lastName: String) {
        let components = fullName.components(separatedBy: " ")
        guard let lastName = components.first, components.count >= 2 else {
            return (fullName, "")
        }
        // FIS typically uses "LASTNAME Firstname" format
        let firstName = components.dropFirst().joined(separator: " ")
        return (firstName, lastName)
    }

    private static func parseTime(_ timeStr: String?) -> TimeInterval? {
        guard let timeStr = timeStr else { return nil }

        // Format: MM:SS.ss or SS.ss
        let components = timeStr.split(separator: ":")

        if components.count == 2,
           let minutesPart = components.first,
           let secondsPart = components.last,
           let minutes = Double(minutesPart),
           let seconds = Double(secondsPart) {
            // MM:SS.ss
            return minutes * 60 + seconds
        } else if components.count == 1 {
            // SS.ss
            return Double(timeStr)
        }

        return nil
    }

    private static func parseEventDate(from context: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")

        let patterns: [(pattern: String, format: String)] = [
            (#"(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})"#, "d MMM yyyy"),
            (#"(\d{1,2})\s+([A-Za-z]{3})"#, "d MMM"),
            (#"(\d{1,2})-\d{1,2}\s+([A-Za-z]{3})"#, "d MMM"),  // Range like "24-25 Jan"
        ]

        for (pattern, format) in patterns {
            if let dateStr = extractFirstMatch(from: context, pattern: pattern) {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateStr) {
                    // If no year in format, use current season
                    if !format.contains("yyyy") {
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.day, .month], from: date)
                        let now = Date()
                        let currentMonth = calendar.component(.month, from: now)
                        let currentYear = calendar.component(.year, from: now)

                        // FIS season runs July to June
                        if let month = components.month {
                            if month >= AppConstants.seasonTransitionMonth {
                                components.year = currentMonth >= AppConstants.seasonTransitionMonth ? currentYear : currentYear - 1
                            } else {
                                components.year = currentMonth >= AppConstants.seasonTransitionMonth ? currentYear + 1 : currentYear
                            }
                        }

                        return calendar.date(from: components)
                    }
                    return date
                }
            }
        }

        return nil
    }

    private static func parseEventType(from context: String) -> EventType? {
        if context.contains("WC") || context.contains("World Cup") {
            return .worldCup
        } else if context.contains("EC") || context.contains("Europa Cup") {
            return .europaCup
        } else if context.contains("NAC") || context.contains("Nor-Am") {
            return .norAmCup
        } else if context.contains("FIS") {
            return .fis
        } else if context.contains("NJR") || context.contains("Junior") {
            return .junior
        }
        return nil
    }

    private static func parseDiscipline(from context: String) -> Discipline? {
        if context.contains("DH") || context.lowercased().contains("downhill") {
            return .downhill
        } else if context.contains("SG") || context.lowercased().contains("super") {
            return .superG
        } else if context.contains("GS") || context.lowercased().contains("giant") {
            return .giantSlalom
        } else if context.contains("SL") || context.lowercased().contains("slalom") {
            return .slalom
        } else if context.contains("AC") || context.contains("combined") {
            return .combined
        }
        return nil
    }

    private static func parseGender(from context: String) -> Gender? {
        if context.contains(">M<") || context.contains(">Men<") || context.contains("Men's") {
            return .men
        } else if context.contains(">W<") || context.contains(">Women<") || context.contains("Women's") || context.contains(">F<") {
            return .women
        }
        return nil
    }

    private static func parseStatus(from context: String) -> RaceStatus? {
        if context.lowercased().contains("live") {
            return .inProgress
        } else if context.lowercased().contains("official") || context.lowercased().contains("final") {
            return .official
        } else if context.lowercased().contains("cancelled") {
            return .cancelled
        } else if context.lowercased().contains("finished") {
            return .finished
        }
        return .scheduled
    }
}
