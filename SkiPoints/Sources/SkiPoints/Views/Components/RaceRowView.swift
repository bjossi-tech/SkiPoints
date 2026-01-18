import SwiftUI

/// Card component for displaying a race in a list.
///
/// Shows race location, discipline, status, and key details.
///
/// ## Example
/// ```swift
/// RaceRowView(race: race) {
///     print("Selected: \(race.location)")
/// }
/// ```
public struct RaceRowView: View {
    let race: Race
    var onTap: (() -> Void)?
    
    public init(race: Race, onTap: (() -> Void)? = nil) {
        self.race = race
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Discipline icon
                disciplineIcon
                
                // Race info
                VStack(alignment: .leading, spacing: 4) {
                    // Location + Nation
                    HStack(spacing: 6) {
                        Text(race.flagEmoji)
                        Text(race.location)
                            .font(.headline)
                    }
                    
                    // Discipline + Event type
                    HStack(spacing: 8) {
                        Text(race.discipline.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        EventTypeBadge(eventType: race.eventType)
                    }
                }
                
                Spacer()
                
                // Status + Time
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: race.status)
                    
                    if race.hasResults, let winner = race.winner {
                        Text(winner.athlete.shortName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(race.date.raceDateShort)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var disciplineIcon: some View {
        Image(systemName: race.discipline.iconName)
            .font(.title2)
            .foregroundStyle(race.discipline.color)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(race.discipline.color.opacity(0.1))
            )
    }
}

// MARK: - Status Badge

public struct StatusBadge: View {
    let status: RaceStatus
    
    public init(status: RaceStatus) {
        self.status = status
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if status.isLive {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
            }
            
            Text(status.shortName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
        .foregroundStyle(status.color)
    }
}

// MARK: - Event Type Badge

public struct EventTypeBadge: View {
    let eventType: EventType
    
    public init(eventType: EventType) {
        self.eventType = eventType
    }
    
    public var body: some View {
        Text(eventType.shortName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(eventType.color.opacity(0.2))
            )
            .foregroundStyle(eventType.color)
    }
}

// MARK: - Preview

#Preview("Race Row - Official") {
    VStack(spacing: 12) {
        RaceRowView(race: PreviewData.wengenSuperG)
        RaceRowView(race: PreviewData.cortinaSuperG)
        RaceRowView(race: PreviewData.kitzbuehelDownhill)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
