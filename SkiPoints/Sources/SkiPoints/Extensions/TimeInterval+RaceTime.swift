import Foundation

/// Extensions for formatting race times.
extension TimeInterval {
    
    // MARK: - Race Time Formatting
    
    /// Format as race time string (e.g., "1:45.19" or "45.19")
    ///
    /// - Uses format "M:SS.hh" for times over 60 seconds
    /// - Uses format "SS.hh" for times under 60 seconds
    public var raceTimeFormatted: String {
        let minutes = Int(self) / 60
        let seconds = self.truncatingRemainder(dividingBy: 60)
        
        if minutes > 0 {
            return String(format: "%d:%05.2f", minutes, seconds)
        } else {
            return String(format: "%.2f", seconds)
        }
    }
    
    /// Format as time difference string (e.g., "+0.35")
    ///
    /// Returns empty string if difference is 0 or negative.
    public var diffFormatted: String {
        guard self > 0 else { return "" }
        return String(format: "+%.2f", self)
    }
    
    /// Format with 3 decimal places (e.g., "1:45.192")
    public var raceTimeFormattedPrecise: String {
        let minutes = Int(self) / 60
        let seconds = self.truncatingRemainder(dividingBy: 60)
        
        if minutes > 0 {
            return String(format: "%d:%06.3f", minutes, seconds)
        } else {
            return String(format: "%.3f", seconds)
        }
    }
    
    // MARK: - Parsing
    
    /// Initialize from race time string (e.g., "1:45.19" or "45.19")
    ///
    /// - Parameter raceTimeString: Time string in "M:SS.hh" or "SS.hh" format
    /// - Returns: TimeInterval in seconds, or nil if parsing fails
    public init?(raceTimeString: String) {
        let trimmed = raceTimeString.trimmingCharacters(in: .whitespaces)
        
        // Handle "M:SS.hh" format
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else {
                return nil
            }
            self = minutes * 60 + seconds
        } else {
            // Handle "SS.hh" format
            guard let seconds = Double(trimmed) else {
                return nil
            }
            self = seconds
        }
    }
    
    // MARK: - Comparison Helpers
    
    /// Check if within a certain time of another time
    public func isWithin(_ threshold: TimeInterval, of other: TimeInterval) -> Bool {
        abs(self - other) <= threshold
    }
    
    /// Calculate percentage behind leader
    public func percentBehind(_ leaderTime: TimeInterval) -> Double {
        guard leaderTime > 0 else { return 0 }
        return ((self - leaderTime) / leaderTime) * 100
    }
}

// MARK: - Date Helpers

extension Date {
    
    /// Check if date is today
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is tomorrow
    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if date is yesterday
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Format as race date (e.g., "Jan 17, 2026")
    public var raceDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Format as short race date (e.g., "Jan 17")
    public var raceDateShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    /// Format for FIS API (e.g., "2026-01-17")
    public var fisDateFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
