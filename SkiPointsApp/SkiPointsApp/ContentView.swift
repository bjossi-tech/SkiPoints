import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Races Tab
            NavigationStack {
                RaceListView(favoritesManager: favoritesManager)
            }
            .tabItem {
                Label("Races", systemImage: "figure.skiing.downhill")
            }
            .tag(0)

            // Search Tab
            NavigationStack {
                AthleteSearchView(favoritesManager: favoritesManager)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            // Favorites Tab
            NavigationStack {
                FavoritesView(favoritesManager: favoritesManager)
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
            .tag(2)

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
