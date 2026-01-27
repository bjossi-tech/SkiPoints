import Foundation
import SwiftUI
import os.log

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
        Log.viewModel.debug("[RaceListViewModel] Initialized")
    }
    
    // MARK: - Load Races
    
    func loadRaces() async {
        guard !isLoading else {
            Log.viewModel.debug("[RaceListViewModel] Already loading, skipping")
            return
        }
        
        isLoading = true
        error = nil

        Log.viewModel.debug("[RaceListViewModel] Loading races for date: \(selectedDate)")
        
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
            
            Log.viewModel.debug("[RaceListViewModel] Loaded \(races.count) races")
            
            // Log race details for debugging
            for race in races {
                print("  - \(race.location): \(race.discipline.displayName) (\(race.status.displayText))")
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
            Log.viewModel.debug("[RaceListViewModel] Error loading races: \(error)")
            self.error = error

            // Fall back to preview data in DEBUG mode
            #if DEBUG
            Log.viewModel.debug("[RaceListViewModel] Using preview data as fallback")
            races = PreviewData.races
            #endif
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

    func startAutoRefresh(interval: TimeInterval = AppConstants.RefreshInterval.raceListSeconds) {
        stopAutoRefresh()

        Log.viewModel.debug("[RaceListViewModel] Starting auto-refresh every \(interval) seconds")

        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                guard !Task.isCancelled else { break }

                // Only auto-refresh if there are live races
                let hasLiveRaces = races.contains { $0.isLive }
                if hasLiveRaces {
                    await loadRaces()
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
        Log.viewModel.debug("[RaceDetailViewModel] Initialized for race: \(race.id)")
    }
    
    // MARK: - Load Results
    
    func loadResults() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil

        Log.viewModel.debug("[RaceDetailViewModel] Loading results for race: \(race.id)")
        
        do {
            let service = FISNetworkService.shared
            results = try await service.fetchRaceResults(raceID: race.id)
            
            lastUpdated = Date()
            
            Log.viewModel.debug("[RaceDetailViewModel] Loaded \(results.count) results")
            
            // Update race with results
            race.results = results
            
            // Recalculate FIS points with penalty
            if let winnerTime = results.first(where: { $0.status == .finished })?.timeSeconds {
                calculateAllFISPoints(winnerTime: winnerTime)
            }
            
        } catch {
            Log.viewModel.debug("[RaceDetailViewModel] Error loading results: \(error)")
            self.error = error

            #if DEBUG
            // Use preview data in debug mode
            if race.id == PreviewData.races.first?.id {
                results = PreviewData.races.first?.results ?? []
            }
            #endif
        }

        isLoading = false
    }
    
    // MARK: - FIS Points Calculation
    
    private func calculateAllFISPoints(winnerTime: TimeInterval) {
        let penalty = calculateRacePenalty()
        
        Log.viewModel.debug("[RaceDetailViewModel] Calculated penalty: \(penalty)")
        
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

        Log.viewModel.debug("[RaceDetailViewModel] Starting auto-refresh for live race")
        isAutoRefreshing = true

        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(AppConstants.RefreshInterval.liveRaceSeconds * 1_000_000_000))

                guard !Task.isCancelled else { break }

                await loadResults()
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

    private let favoritesKey = AppConstants.UserDefaultsKeys.favoriteAthletes
    private let athletesDataKey = AppConstants.UserDefaultsKeys.favoriteAthletesData

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
                Log.favorites.debug("[FavoritesManager] Loaded \(favorites.count) favorites with athlete data")
            } catch {
                Log.favorites.debug("[FavoritesManager] Failed to decode athletes: \(error)")
            }
        } else {
            Log.favorites.debug("[FavoritesManager] Loaded \(favorites.count) favorites (no athlete data)")
        }
    }

    private func saveFavorites() {
        // Save FIS codes
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)

        // Save athlete data
        do {
            let data = try JSONEncoder().encode(favoriteAthletes)
            UserDefaults.standard.set(data, forKey: athletesDataKey)
            Log.favorites.debug("[FavoritesManager] Saved \(favorites.count) favorites with athlete data")
        } catch {
            Log.favorites.debug("[FavoritesManager] Failed to encode athletes: \(error)")
        }
    }

    // MARK: - Load Athlete Details

    func loadFavoriteDetails() async {
        Log.favorites.debug("[FavoritesManager] Loading details for \(favorites.count) favorites")

        var athletes: [Athlete] = []
        let service = FISNetworkService.shared

        for fisCode in favorites {
            do {
                let athlete = try await service.fetchAthlete(competitorID: fisCode)
                athletes.append(athlete)
            } catch {
                Log.favorites.debug("[FavoritesManager] Failed to load athlete \(fisCode): \(error)")
            }
        }

        favoriteAthletes = athletes
        saveFavorites()  // Persist the loaded athlete data
        Log.favorites.debug("[FavoritesManager] Loaded \(athletes.count) athlete details")
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

    func search() async {
        guard searchQuery.count >= AppConstants.Search.minimumQueryLength else {
            searchResults = []
            return
        }

        searchTask?.cancel()

        isSearching = true
        error = nil

        Log.search.debug("[AthleteSearchViewModel] Searching for: \(searchQuery)")

        searchTask = Task {
            do {
                // Debounce
                try await Task.sleep(nanoseconds: AppConstants.RefreshInterval.searchDebounceNanoseconds)

                guard !Task.isCancelled else { return }

                let service = FISNetworkService.shared
                let results = try await service.searchAthletes(query: searchQuery)

                guard !Task.isCancelled else { return }

                searchResults = results
                Log.search.debug("[AthleteSearchViewModel] Found \(results.count) athletes")

            } catch {
                if !Task.isCancelled {
                    Log.search.debug("[AthleteSearchViewModel] Search error: \(error)")
                    self.error = error
                }
            }

            isSearching = false
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchTask?.cancel()
    }
}

