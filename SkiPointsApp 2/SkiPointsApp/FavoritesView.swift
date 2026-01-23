import SwiftUI

struct FavoritesView: View {
    @Binding var favoriteAthletes: Set<String>
    
    private var athletes: [Athlete] {
        PreviewData.allAthletes.filter { favoriteAthletes.contains($0.fisCode) }
    }
    
    var body: some View {
        Group {
            if athletes.isEmpty {
                ContentUnavailableView {
                    Label("No Favorites", systemImage: "star")
                } description: {
                    Text("Tap on athletes in race results to add them to your favorites.")
                }
            } else {
                List {
                    ForEach(athletes) { athlete in
                        HStack(spacing: 12) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(.blue.gradient)
                                Text(String(athlete.firstName.prefix(1)) + String(athlete.lastName.prefix(1)))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 40, height: 40)
                            
                            // Info
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(athlete.flagEmoji)
                                    Text(athlete.fullName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                if let brand = athlete.skiBrand {
                                    Text(brand)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // FIS Points
                            if let points = athlete.currentFISPoints {
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f", points))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                    Text("FIS Pts")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                favoriteAthletes.remove(athlete.fisCode)
                            } label: {
                                Label("Remove", systemImage: "star.slash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

#Preview("With Favorites") {
    NavigationStack {
        FavoritesView(favoriteAthletes: .constant(["512269", "539909"]))
    }
}

#Preview("Empty") {
    NavigationStack {
        FavoritesView(favoriteAthletes: .constant([]))
    }
}
