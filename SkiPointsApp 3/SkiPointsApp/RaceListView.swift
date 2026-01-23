import SwiftUI

struct RaceListView: View {
    @Binding var favoriteAthletes: Set<String>
    @StateObject private var viewModel = RaceListViewModel()
    @State private var selectedRace: Race?
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.races.isEmpty {
                LoadingView(message: "Loading races...")
            } else if let error = viewModel.error, viewModel.races.isEmpty {
                ErrorView(error: error) {
                    await viewModel.refresh()
                }
            } else if viewModel.races.isEmpty {
                ContentUnavailableView {
                    Label("No Races Today", systemImage: "figure.skiing.downhill")
                } description: {
                    Text("Check back later for upcoming races.")
                }
            } else {
                raceList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Races")
        .navigationDestination(item: $selectedRace) { race in
            RaceDetailView(race: race, favoriteAthletes: $favoriteAthletes)
        }
        .task {
            await viewModel.loadTodaysRaces()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var raceList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Last updated indicator
                if let lastUpdated = viewModel.lastUpdated {
                    HStack {
                        Spacer()
                        Text("Updated \(lastUpdated, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                }
                
                if !viewModel.liveRaces.isEmpty {
                    raceSection(title: "Live Now", races: viewModel.liveRaces, showPulse: true)
                }
                if !viewModel.completedRaces.isEmpty {
                    raceSection(title: "Completed", races: viewModel.completedRaces, showPulse: false)
                }
                if !viewModel.upcomingRaces.isEmpty {
                    raceSection(title: "Upcoming", races: viewModel.upcomingRaces, showPulse: false)
                }
            }
            .padding()
        }
    }
    
    private func raceSection(title: String, races: [Race], showPulse: Bool) -> some View {
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
                    selectedRace = race
                }
            }
        }
    }
}

// MARK: - Race Row

struct RaceRowView: View {
    let race: Race
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Discipline icon
                Image(systemName: race.discipline.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.blue.opacity(0.1)))
                
                // Race info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(race.flagEmoji)
                        Text(race.location)
                            .font(.headline)
                    }
                    
                    HStack(spacing: 8) {
                        Text(race.discipline.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(race.eventType.shortName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.orange.opacity(0.2)))
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                // Status
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: race.status)
                    
                    if let winner = race.winner {
                        Text(winner.athlete.shortName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(.background))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: RaceStatus
    
    var body: some View {
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
        .background(Capsule().fill(statusColor.opacity(0.15)))
        .foregroundStyle(statusColor)
    }
    
    var statusColor: Color {
        switch status {
        case .inProgress: return .red
        case .official: return .green
        case .finished: return .orange
        case .scheduled: return .gray
        case .cancelled: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        RaceListView(favoriteAthletes: .constant([]))
    }
}
