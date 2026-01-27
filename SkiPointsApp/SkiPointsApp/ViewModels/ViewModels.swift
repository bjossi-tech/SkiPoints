import Foundation
import SwiftUI
import os

// MARK: - Race List View Model

@MainActor
class RaceListViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?
    @Published var selectedDate: Date = Date()

    private var autoRefreshTask: Task<Void, Never>?

    init() {
        AppLogger.viewModel.debug("RaceListViewModel initialized")
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    // MARK: - Load Races

    func loadRaces() async {
        guard !isLoading else {
            AppLogger.viewModel.debug("RaceListViewModel: Already loading, skipping")
            return
        }

        isLoading = true
        error = nil

        AppLogger.viewModel.info("Loading races for date: \(self.selectedDate.description)")

        do {
            let service = FISNetworkService.shared

            // Check if loading for today
            let calendar = Calendar.current
            if calendar.isDateInToday(selectedDate) {
                races = try await service.fetchTodaysRaces()
            } else {
                races = try await service.fetchEvents(from: selectedDate, to: selectedDate)
            }

            lastUpdated = Date()

            AppLogger.viewModel.info("Loaded \(self.races.count) races")

            // Log race details for debugging
            for race in races {
                AppLogger.viewModel.debug("  - \(race.location): \(race.discipline.displayName) (\(race.status.displayText))")
            }

            // Sort by priority: Live first, then by event type, then by time
            races.sort { first, second in
                if first.isLive && !second.isLive { return true }
                if !first.isLive && second.isLive { return false }
                if first.eventType.priority != second.eventType.priority {
                    return first.eventType.priority < second.eventType.priority
                }
                return first.date < second.date
            }

        } catch {
            AppLogger.viewModel.error("Error loading races: \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Load Today's Races

    /// Load races for today's date
    func loadTodaysRaces() async {
        selectedDate = Date()
        await loadRaces()
    }

    // MARK: - Refresh

    func refresh() async {
        await loadRaces()
    }

    // MARK: - Date Selection

    func selectDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadRaces()
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval = AppConstants.Timing.raceListAutoRefreshInterval) {
        stopAutoRefresh()

        AppLogger.viewModel.info("Starting auto-refresh every \(interval) seconds")

        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                guard !Task.isCancelled, let self else { break }

                // Only auto-refresh if there are live races
                let hasLiveRaces = self.races.contains { $0.isLive }
                if hasLiveRaces {
                    await self.loadRaces()
                }
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    // MARK: - Filtering

    var liveRaces: [Race] {
        races.filter { $0.isLive }
    }

    var upcomingRaces: [Race] {
        races.filter { $0.status == .scheduled }
    }

    var completedRaces: [Race] {
        races.filter { $0.isFinished }
    }
}

// MARK: - Race Detail View Model

@MainActor
class RaceDetailViewModel: ObservableObject {
    @Published var race: Race
    @Published var results: [RaceResult] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?
    @Published private(set) var isAutoRefreshing = false

    private var autoRefreshTask: Task<Void, Never>?

    init(race: Race) {
        self.race = race
        self.results = race.results
        AppLogger.viewModel.debug("RaceDetailViewModel initialized for race: \(race.id)")
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    // MARK: - Load Results

    func loadResults() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        AppLogger.viewModel.info("Loading results for race: \(self.race.id)")

        do {
            let service = FISNetworkService.shared
            results = try await service.fetchRaceResults(raceID: race.id)

            lastUpdated = Date()

            AppLogger.viewModel.info("Loaded \(self.results.count) results")

            // Update race with results
            race.results = results

            // Recalculate FIS points with penalty
            if let winnerTime = results.first(where: { $0.status == .finished })?.timeSeconds {
                calculateAllFISPoints(winnerTime: winnerTime)
            }

        } catch {
            AppLogger.viewModel.error("Error loading results: \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }

    // MARK: - FIS Points Calculation

    private func calculateAllFISPoints(winnerTime: TimeInterval) {
        let penalty = calculateRacePenalty()

        AppLogger.viewModel.debug("Calculated penalty: \(penalty)")

        for i in 0..<results.count {
            guard results[i].status == .finished,
                  let athleteTime = results[i].timeSeconds else {
                continue
            }

            let racePoints = FISPointsCalculator.calculateRacePoints(
                athleteTime: athleteTime,
                winnerTime: winnerTime,
                discipline: race.discipline
            )

            results[i].fisPoints = FISPointsCalculator.calculateFISPoints(
                racePoints: racePoints,
                penalty: penalty
            )
        }
    }

    private func calculateRacePenalty() -> Double {
        // Get FIS points of all starters
        let startersFISPoints = results
            .map { $0.athlete.points(for: race.discipline) }

        // Get race points of top 10
        let top10RacePoints = results
            .filter { $0.status == .finished }
            .prefix(10)
            .compactMap { result -> Double? in
                guard let athleteTime = result.timeSeconds,
                      let winnerTime = results.first?.timeSeconds else {
                    return nil
                }
                return FISPointsCalculator.calculateRacePoints(
                    athleteTime: athleteTime,
                    winnerTime: winnerTime,
                    discipline: race.discipline
                )
            }

        return FISPointsCalculator.calculatePenalty(
            startersFISPoints: startersFISPoints,
            top10RacePoints: Array(top10RacePoints)
        )
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        guard race.isLive else { return }

        stopAutoRefresh()

        AppLogger.viewModel.info("Starting auto-refresh for live race")
        isAutoRefreshing = true

        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(AppConstants.Timing.raceDetailAutoRefreshInterval * 1_000_000_000))

                guard !Task.isCancelled, let self else { break }

                await self.loadResults()
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
        isAutoRefreshing = false
    }

    // MARK: - Result Categories

    var podiumResults: [RaceResult] {
        results.filter { $0.status == .finished && $0.rank <= 3 }
    }

    var finishedResults: [RaceResult] {
        results.filter { $0.status == .finished }
    }

    var dnfResults: [RaceResult] {
        results.filter { $0.status == .didNotFinish }
    }

    var dnsResults: [RaceResult] {
        results.filter { $0.status == .didNotStart }
    }

    var dsqResults: [RaceResult] {
        results.filter { $0.status == .disqualified }
    }
}

// MARK: - Favorites Manager

@MainActor
class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: Set<String> = []
    @Published private(set) var favoriteAthletes: [Athlete] = []

    private let favoritesKey = "favoriteAthletes"
    private let athletesDataKey = "favoriteAthletesData"

    init() {
        loadFavorites()
    }

    // MARK: - Favorite Management

    func isFavorite(_ athlete: Athlete) -> Bool {
        favorites.contains(athlete.fisCode)
    }

    func toggleFavorite(_ athlete: Athlete) {
        if favorites.contains(athlete.fisCode) {
            favorites.remove(athlete.fisCode)
            favoriteAthletes.removeAll { $0.fisCode == athlete.fisCode }
        } else {
            favorites.insert(athlete.fisCode)
            favoriteAthletes.append(athlete)
        }
        saveFavorites()
    }

    func addFavorite(_ athlete: Athlete) {
        guard !favorites.contains(athlete.fisCode) else { return }
        favorites.insert(athlete.fisCode)
        favoriteAthletes.append(athlete)
        saveFavorites()
    }

    func removeFavorite(_ athlete: Athlete) {
        favorites.remove(athlete.fisCode)
        favoriteAthletes.removeAll { $0.fisCode == athlete.fisCode }
        saveFavorites()
    }

    // MARK: - Persistence

    private func loadFavorites() {
        // Load FIS codes
        if let savedCodes = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favorites = Set(savedCodes)
        }

        // Load athlete data
        if let data = UserDefaults.standard.data(forKey: athletesDataKey) {
            do {
                let athletes = try JSONDecoder().decode([Athlete].self, from: data)
                favoriteAthletes = athletes
                AppLogger.favorites.info("Loaded \(self.favorites.count) favorites with athlete data")
            } catch {
                AppLogger.favorites.error("Failed to decode athletes: \(error.localizedDescription)")
            }
        } else {
            AppLogger.favorites.info("Loaded \(self.favorites.count) favorites (no athlete data)")
        }
    }

    private func saveFavorites() {
        // Save FIS codes
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)

        // Save athlete data
        do {
            let data = try JSONEncoder().encode(favoriteAthletes)
            UserDefaults.standard.set(data, forKey: athletesDataKey)
            AppLogger.favorites.info("Saved \(self.favorites.count) favorites with athlete data")
        } catch {
            AppLogger.favorites.error("Failed to encode athletes: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Athlete Details

    func loadFavoriteDetails() async {
        AppLogger.favorites.info("Loading details for \(self.favorites.count) favorites")

        var athletes: [Athlete] = []
        let service = FISNetworkService.shared

        for fisCode in favorites {
            do {
                let athlete = try await service.fetchAthlete(competitorID: fisCode)
                athletes.append(athlete)
            } catch {
                AppLogger.favorites.error("Failed to load athlete \(fisCode): \(error.localizedDescription)")
            }
        }

        favoriteAthletes = athletes
        saveFavorites()  // Persist the loaded athlete data
        AppLogger.favorites.info("Loaded \(athletes.count) athlete details")
    }
}

// MARK: - Athlete Search View Model

@MainActor
class AthleteSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Athlete] = []
    @Published var isSearching = false
    @Published var error: Error?

    private var searchTask: Task<Void, Never>?

    deinit {
        searchTask?.cancel()
    }

    func search() async {
        guard searchQuery.count >= AppConstants.Search.minimumQueryLength else {
            searchResults = []
            return
        }

        searchTask?.cancel()

        isSearching = true
        error = nil

        AppLogger.viewModel.info("Searching for: \(self.searchQuery)")

        searchTask = Task { [weak self] in
            do {
                // Debounce
                try await Task.sleep(nanoseconds: AppConstants.Timing.searchDebounceNanoseconds)

                guard !Task.isCancelled, let self else { return }

                let service = FISNetworkService.shared
                let results = try await service.searchAthletes(query: self.searchQuery)

                guard !Task.isCancelled else { return }

                self.searchResults = results
                AppLogger.viewModel.info("Found \(results.count) athletes")

            } catch {
                if !Task.isCancelled, let self {
                    AppLogger.viewModel.error("Search error: \(error.localizedDescription)")
                    self.error = error
                }
            }

            if let self {
                self.isSearching = false
            }
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchTask?.cancel()
    }
}
