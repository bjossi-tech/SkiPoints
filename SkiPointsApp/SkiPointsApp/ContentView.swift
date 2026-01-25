import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var favoriteAthletes: Set<String> = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Races Tab
            NavigationStack {
                RaceListView(favoriteAthletes: $favoriteAthletes)
            }
            .tabItem {
                Label("Races", systemImage: "figure.skiing.downhill")
            }
            .tag(0)
            
            // Favorites Tab
            NavigationStack {
                FavoritesView(favoriteAthletes: $favoriteAthletes)
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
            .tag(1)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
