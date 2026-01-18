import SwiftUI

/// Main entry point for the SkiPoints app.
@main
public struct SkiPointsApp: App {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

/// Global app state manager.
@MainActor
public class AppState: ObservableObject {
    @Published public var races: [Race] = PreviewData.allRaces
    @Published public var favoriteAthletes: Set<String> = []
    @Published public var isLoading: Bool = false
    @Published public var error: Error?
    
    public init() {}
    
    // MARK: - Actions
    
    public func refreshRaces() async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1))
        
        // In production, this would fetch from FIS
        races = PreviewData.allRaces
        
        isLoading = false
    }
    
    public func toggleFavorite(_ athlete: Athlete) {
        if favoriteAthletes.contains(athlete.fisCode) {
            favoriteAthletes.remove(athlete.fisCode)
        } else {
            favoriteAthletes.insert(athlete.fisCode)
        }
    }
    
    public func isFavorite(_ athlete: Athlete) -> Bool {
        favoriteAthletes.contains(athlete.fisCode)
    }
}

// MARK: - Content View

/// Root content view with tab navigation.
public struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        TabView {
            // Races tab
            NavigationStack {
                RacesTab()
            }
            .tabItem {
                Label("Races", systemImage: "figure.skiing.downhill")
            }
            
            // Favorites tab
            NavigationStack {
                FavoritesTab()
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
            
            // Settings tab
            NavigationStack {
                SettingsTab()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// MARK: - Races Tab

struct RacesTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedRace: Race?
    
    var body: some View {
        RaceListView(
            races: appState.races,
            isLoading: appState.isLoading,
            onRefresh: {
                await appState.refreshRaces()
            },
            onRaceSelected: { race in
                selectedRace = race
            }
        )
        .navigationDestination(item: $selectedRace) { race in
            RaceDetailView(
                race: race,
                favoriteAthletes: appState.favoriteAthletes,
                onAthleteSelected: { _ in },
                onToggleFavorite: { athlete in
                    appState.toggleFavorite(athlete)
                }
            )
        }
    }
}

// MARK: - Favorites Tab

struct FavoritesTab: View {
    @EnvironmentObject private var appState: AppState
    
    private var favoriteAthletes: [Athlete] {
        PreviewData.allAthletes.filter {
            appState.favoriteAthletes.contains($0.fisCode)
        }
    }
    
    var body: some View {
        Group {
            if favoriteAthletes.isEmpty {
                ContentUnavailableView {
                    Label("No Favorites", systemImage: "star")
                } description: {
                    Text("Add athletes to your favorites to track them here.")
                }
            } else {
                List(favoriteAthletes) { athlete in
                    NavigationLink {
                        AthleteProfileView(
                            athlete: athlete,
                            isFavorite: true,
                            onToggleFavorite: {
                                appState.toggleFavorite(athlete)
                            }
                        )
                    } label: {
                        HStack(spacing: 12) {
                            AthleteAvatar(athlete: athlete, size: 40)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(athlete.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 4) {
                                    Text(athlete.flagEmoji)
                                    Text(athlete.nation)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                            
                            Spacer()
                            
                            if let points = athlete.currentFISPoints {
                                Text(String(format: "%.2f", points))
                                    .font(.caption)
                                    .foregroundStyle(.skiBlue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("FIS Website", destination: URL(string: "https://www.fis-ski.com")!)
            }
            
            Section("Data") {
                Text("Data provided by FIS")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
