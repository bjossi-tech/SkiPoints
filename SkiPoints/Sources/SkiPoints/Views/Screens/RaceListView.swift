import SwiftUI

/// Main screen showing today's races.
///
/// Displays races grouped by status (Live, Completed, Upcoming).
///
/// ## Example
/// ```swift
/// RaceListView(
///     races: races,
///     isLoading: false,
///     onRefresh: { await fetchRaces() },
///     onRaceSelected: { race in navigateTo(race) }
/// )
/// ```
public struct RaceListView: View {
    let races: [Race]
    var isLoading: Bool = false
    var error: Error?
    var onRefresh: (() async -> Void)?
    var onRaceSelected: ((Race) -> Void)?
    
    public init(
        races: [Race],
        isLoading: Bool = false,
        error: Error? = nil,
        onRefresh: (() async -> Void)? = nil,
        onRaceSelected: ((Race) -> Void)? = nil
    ) {
        self.races = races
        self.isLoading = isLoading
        self.error = error
        self.onRefresh = onRefresh
        self.onRaceSelected = onRaceSelected
    }
    
    // Grouped races
    private var liveRaces: [Race] {
        races.filter { $0.status.isLive }.sorted { $0.status < $1.status }
    }
    
    private var completedRaces: [Race] {
        races.filter { $0.status == .official || $0.status == .finished }
    }
    
    private var upcomingRaces: [Race] {
        races.filter { $0.status == .scheduled || $0.status == .delayed || $0.status == .postponed }
            .sorted { $0.date < $1.date }
    }
    
    public var body: some View {
        Group {
            if isLoading && races.isEmpty {
                loadingView
            } else if races.isEmpty {
                emptyView
            } else {
                racesList
            }
        }
        .navigationTitle("Races")
        .refreshable {
            await onRefresh?()
        }
    }
    
    // MARK: - Race List
    
    private var racesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Live races (priority)
                if !liveRaces.isEmpty {
                    raceSection(title: "Live Now", races: liveRaces, showPulse: true)
                }
                
                // Completed races
                if !completedRaces.isEmpty {
                    raceSection(title: "Completed", races: completedRaces)
                }
                
                // Upcoming races
                if !upcomingRaces.isEmpty {
                    raceSection(title: "Upcoming", races: upcomingRaces)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func raceSection(title: String, races: [Race], showPulse: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if showPulse {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                Text("\(races.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(races) { race in
                RaceRowView(race: race) {
                    onRaceSelected?(race)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Races", systemImage: "figure.skiing.downhill")
        } description: {
            Text("There are no races scheduled for today.")
        } actions: {
            Button("Refresh") {
                Task { await onRefresh?() }
            }
        }
    }
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading races...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Race List") {
    NavigationStack {
        RaceListView(
            races: PreviewData.allRaces,
            onRefresh: {
                try? await Task.sleep(for: .seconds(1))
            },
            onRaceSelected: { race in
                print("Selected: \(race.location)")
            }
        )
    }
}

#Preview("Empty State") {
    NavigationStack {
        RaceListView(races: [])
    }
}

#Preview("Loading") {
    NavigationStack {
        RaceListView(races: [], isLoading: true)
    }
}
