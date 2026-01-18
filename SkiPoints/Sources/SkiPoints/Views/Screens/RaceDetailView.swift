import SwiftUI

/// Detailed view of a race with full results.
///
/// Displays race metadata, podium, and complete results list.
///
/// ## Example
/// ```swift
/// RaceDetailView(
///     race: race,
///     favoriteAthletes: favorites,
///     onAthleteSelected: { athlete in ... }
/// )
/// ```
public struct RaceDetailView: View {
    let race: Race
    var favoriteAthletes: Set<String> = []
    var isRefreshing: Bool = false
    var onRefresh: (() async -> Void)?
    var onAthleteSelected: ((Athlete) -> Void)?
    var onToggleFavorite: ((Athlete) -> Void)?
    
    public init(
        race: Race,
        favoriteAthletes: Set<String> = [],
        isRefreshing: Bool = false,
        onRefresh: (() async -> Void)? = nil,
        onAthleteSelected: ((Athlete) -> Void)? = nil,
        onToggleFavorite: ((Athlete) -> Void)? = nil
    ) {
        self.race = race
        self.favoriteAthletes = favoriteAthletes
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.onAthleteSelected = onAthleteSelected
        self.onToggleFavorite = onToggleFavorite
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Race header
                raceHeader
                
                // Live indicator
                if race.isLive {
                    liveIndicator
                }
                
                // Podium (if results exist)
                if !race.podium.isEmpty {
                    podiumView
                }
                
                // Full results
                if !race.results.isEmpty {
                    resultsSection
                }
                
                // DNF/DNS sections
                if !race.dnfResults.isEmpty {
                    NonFinisherSection(
                        title: "Did Not Finish (\(race.dnfResults.count))",
                        results: race.dnfResults,
                        onAthleteTap: onAthleteSelected
                    )
                }
                
                if !race.dnsResults.isEmpty {
                    NonFinisherSection(
                        title: "Did Not Start (\(race.dnsResults.count))",
                        results: race.dnsResults,
                        onAthleteTap: onAthleteSelected
                    )
                }
                
                // Course info
                if race.courseInfo {
                    courseInfoSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(race.location)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = race.fisResultsURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .refreshable {
            await onRefresh?()
        }
    }
    
    // MARK: - Race Header
    
    private var raceHeader: some View {
        VStack(spacing: 12) {
            // Title and badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(race.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(race.flagEmoji)
                        Text(race.fullLocation)
                            .foregroundStyle(.secondary)
                        
                        EventTypeBadge(eventType: race.eventType)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                StatusBadge(status: race.status)
            }
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(race.date.raceDateFormatted)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let winnerTime = race.winnerTime {
                    Text("Winner: \(winnerTime.raceTimeFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    // MARK: - Live Indicator
    
    private var liveIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            
            Text("LIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.red)
            
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.7)
            }
            
            Spacer()
            
            Text("Auto-updating")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.1))
        )
    }
    
    // MARK: - Podium
    
    private var podiumView: some View {
        VStack(spacing: 16) {
            Text("Podium")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Silver (2nd)
                if let second = race.podium.first(where: { $0.rank == 2 }) {
                    podiumPosition(result: second, height: 60)
                }
                
                // Gold (1st)
                if let first = race.podium.first(where: { $0.rank == 1 }) {
                    podiumPosition(result: first, height: 80)
                }
                
                // Bronze (3rd)
                if let third = race.podium.first(where: { $0.rank == 3 }) {
                    podiumPosition(result: third, height: 50)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    private func podiumPosition(result: RaceResult, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Medal
            Text(result.medal?.emoji ?? "")
                .font(.title)
            
            // Name
            Text(result.athlete.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            // Nation
            Text(result.athlete.flagEmoji)
            
            // Time
            Text(result.formattedTime)
                .font(.caption2)
                .monospacedDigit()
            
            // Platform
            RoundedRectangle(cornerRadius: 4)
                .fill(result.medal?.color ?? .gray)
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.headline)
            
            ResultHeaderRow()
            
            Divider()
            
            ForEach(race.finishedResults) { result in
                ResultRowView(
                    result: result,
                    isFavorite: favoriteAthletes.contains(result.athlete.fisCode),
                    onTap: { onAthleteSelected?(result.athlete) }
                )
                .contextMenu {
                    Button {
                        onToggleFavorite?(result.athlete)
                    } label: {
                        let isFav = favoriteAthletes.contains(result.athlete.fisCode)
                        Label(
                            isFav ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: isFav ? "star.slash" : "star"
                        )
                    }
                    
                    Button {
                        onAthleteSelected?(result.athlete)
                    } label: {
                        Label("View Profile", systemImage: "person")
                    }
                }
                
                if result.id != race.finishedResults.last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    // MARK: - Course Info
    
    @ViewBuilder
    private var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course Information")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let drop = race.verticalDrop {
                    courseInfoItem(label: "Vertical Drop", value: "\(drop)m")
                }
                if let length = race.courseLength {
                    courseInfoItem(label: "Course Length", value: "\(length)m")
                }
                if let gates = race.gateCount {
                    courseInfoItem(label: "Gates", value: "\(gates)")
                }
                if let start = race.startAltitude {
                    courseInfoItem(label: "Start Altitude", value: "\(start)m")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    private func courseInfoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Race Detail - Official") {
    NavigationStack {
        RaceDetailView(
            race: PreviewData.wengenSuperG,
            favoriteAthletes: ["512269"],
            onAthleteSelected: { print("Selected: \($0.fullName)") }
        )
    }
}

#Preview("Race Detail - Live") {
    NavigationStack {
        RaceDetailView(
            race: PreviewData.cortinaSuperG,
            isRefreshing: false
        )
    }
}
