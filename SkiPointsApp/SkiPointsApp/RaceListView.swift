import SwiftUI

struct RaceListView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @StateObject private var viewModel = RaceListViewModel()
    @State private var selectedRace: Race?
    @State private var selectedDiscipline: Discipline?
    @State private var selectedGender: Gender?

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
            RaceDetailView(race: race, favoritesManager: favoritesManager)
        }
        .task {
            await viewModel.loadTodaysRaces()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
    }

    // MARK: - Filtered Races

    private var filteredRaces: [Race] {
        viewModel.races.filter { race in
            let disciplineMatch = selectedDiscipline == nil || race.discipline == selectedDiscipline
            let genderMatch = selectedGender == nil || race.gender == selectedGender
            return disciplineMatch && genderMatch
        }
    }

    private var filteredLiveRaces: [Race] {
        filteredRaces.filter { $0.isLive }
    }

    private var filteredCompletedRaces: [Race] {
        filteredRaces.filter { $0.isFinished }
    }

    private var filteredUpcomingRaces: [Race] {
        filteredRaces.filter { $0.status == .scheduled }
    }

    private var hasActiveFilters: Bool {
        selectedDiscipline != nil || selectedGender != nil
    }

    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let discipline = selectedDiscipline {
                    FilterChip(
                        title: discipline.displayName,
                        systemImage: discipline.iconName
                    ) {
                        selectedDiscipline = nil
                    }
                }

                if let gender = selectedGender {
                    FilterChip(
                        title: gender.displayName,
                        systemImage: "person"
                    ) {
                        selectedGender = nil
                    }
                }
            }
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Discipline filter
            Menu {
                Button {
                    selectedDiscipline = nil
                } label: {
                    Label("All Disciplines", systemImage: selectedDiscipline == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(Discipline.allCases, id: \.self) { discipline in
                    Button {
                        selectedDiscipline = discipline
                    } label: {
                        Label(discipline.displayName, systemImage: selectedDiscipline == discipline ? "checkmark" : "")
                    }
                }
            } label: {
                Label(selectedDiscipline?.displayName ?? "Discipline", systemImage: "figure.skiing.downhill")
            }

            // Gender filter
            Menu {
                Button {
                    selectedGender = nil
                } label: {
                    Label("All", systemImage: selectedGender == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(Gender.allCases, id: \.self) { gender in
                    Button {
                        selectedGender = gender
                    } label: {
                        Label(gender.displayName, systemImage: selectedGender == gender ? "checkmark" : "")
                    }
                }
            } label: {
                Label(selectedGender?.displayName ?? "Gender", systemImage: "person.2")
            }

            if hasActiveFilters {
                Divider()

                Button(role: .destructive) {
                    selectedDiscipline = nil
                    selectedGender = nil
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(hasActiveFilters ? .blue : .primary)
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
                
                // Active filters indicator
                if hasActiveFilters {
                    activeFiltersView
                }

                if !filteredLiveRaces.isEmpty {
                    raceSection(title: "Live Now", races: filteredLiveRaces, showPulse: true)
                }
                if !filteredCompletedRaces.isEmpty {
                    raceSection(title: "Completed", races: filteredCompletedRaces, showPulse: false)
                }
                if !filteredUpcomingRaces.isEmpty {
                    raceSection(title: "Upcoming", races: filteredUpcomingRaces, showPulse: false)
                }

                if filteredRaces.isEmpty && !viewModel.races.isEmpty {
                    ContentUnavailableView {
                        Label("No Matching Races", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try adjusting your filters.")
                    } actions: {
                        Button("Clear Filters") {
                            selectedDiscipline = nil
                            selectedGender = nil
                        }
                    }
                    .padding(.top, 40)
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
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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
        case .postponed: return .purple
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let systemImage: String
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(.blue.opacity(0.15)))
        .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationStack {
        RaceListView(favoritesManager: FavoritesManager())
    }
}
