import Foundation
import SwiftUI

// MARK: - Race List ViewModel

@MainActor
class RaceListViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?
    
    private let networkService = FISNetworkService.shared
    
    var liveRaces: [Race] {
        races.filter { $0.status.isLive }
    }
    
    var completedRaces: [Race] {
        races.filter { $0.status == .official || $0.status == .finished }
    }
    
    var upcomingRaces: [Race] {
        races.filter { $0.status == .scheduled }
    }
    
    func loadTodaysRaces() async {
        isLoading = true
        error = nil
        
        do {
            races = try await networkService.fetchTodaysRaces()
            lastUpdated = Date()
        } catch {
            self.error = error
            // Fall back to preview data in case of error (for development)
            #if DEBUG
            if races.isEmpty {
                races = PreviewData.allRaces
            }
            #endif
        }
        
        isLoading = false
    }
    
    func loadRaces(from startDate: Date, to endDate: Date) async {
        isLoading = true
        error = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            races = try await networkService.fetchRaces(
                from: formatter.string(from: startDate),
                to: formatter.string(from: endDate)
            )
            lastUpdated = Date()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadTodaysRaces()
    }
}

// MARK: - Race Detail ViewModel

@MainActor
class RaceDetailViewModel: ObservableObject {
    @Published var race: Race
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isAutoRefreshing = false
    
    private let networkService = FISNetworkService.shared
    private var refreshTask: Task<Void, Never>?
    
    init(race: Race) {
        self.race = race
    }
    
    deinit {
        refreshTask?.cancel()
    }
    
    func loadResults() async {
        isLoading = true
        error = nil
        
        do {
            let results = try await networkService.fetchRaceResults(raceID: race.id)
            race.results = results
        } catch {
            self.error = error
            // Keep existing results if fetch fails
        }
        
        isLoading = false
    }
    
    func startAutoRefresh(interval: TimeInterval = 30) {
        guard race.isLive else { return }
        
        isAutoRefreshing = true
        refreshTask?.cancel()
        
        refreshTask = Task {
            while !Task.isCancelled && race.isLive {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                if !Task.isCancelled {
                    await loadResults()
                }
            }
            
            await MainActor.run {
                isAutoRefreshing = false
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTask?.cancel()
        isAutoRefreshing = false
    }
}

// MARK: - Athlete ViewModel

@MainActor
class AthleteViewModel: ObservableObject {
    @Published var athlete: Athlete?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService = FISNetworkService.shared
    
    func loadAthlete(fisCode: String) async {
        isLoading = true
        error = nil
        
        do {
            athlete = try await networkService.fetchAthlete(fisCode: fisCode)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

// MARK: - Loading State View

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    var retryAction: (() async -> Void)?
    
    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let retry = retryAction {
                Button("Try Again") {
                    Task {
                        await retry()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Error") {
    ErrorView(error: FISNetworkError.networkError(URLError(.notConnectedToInternet)))
}
