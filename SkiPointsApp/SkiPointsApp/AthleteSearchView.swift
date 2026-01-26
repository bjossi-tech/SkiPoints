import SwiftUI

struct AthleteSearchView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @StateObject private var viewModel = AthleteSearchViewModel()

    var body: some View {
        Group {
            if viewModel.searchResults.isEmpty && viewModel.searchQuery.isEmpty {
                ContentUnavailableView {
                    Label("Search Athletes", systemImage: "magnifyingglass")
                } description: {
                    Text("Search for athletes by name to view their FIS points and add them to favorites.")
                }
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                ContentUnavailableView {
                    Label("No Results", systemImage: "person.slash")
                } description: {
                    Text("No athletes found matching \"\(viewModel.searchQuery)\"")
                }
            } else {
                searchResultsList
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by athlete name"
        )
        .onChange(of: viewModel.searchQuery) { _, _ in
            Task {
                await viewModel.search()
            }
        }
        .overlay {
            if viewModel.isSearching {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var searchResultsList: some View {
        List(viewModel.searchResults) { athlete in
            AthleteSearchRow(
                athlete: athlete,
                isFavorite: favoritesManager.isFavorite(athlete),
                onToggleFavorite: {
                    favoritesManager.toggleFavorite(athlete)
                }
            )
        }
    }
}

// MARK: - Athlete Search Row

struct AthleteSearchRow: View {
    let athlete: Athlete
    let isFavorite: Bool
    var onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                Text(String(athlete.firstName.prefix(1)) + String(athlete.lastName.prefix(1)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(athlete.flagEmoji)
                    Text(athlete.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(athlete.nation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // FIS Points
            if let points = athlete.currentFISPoints {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", points))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text("FIS Pts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Favorite button
            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AthleteSearchView(favoritesManager: FavoritesManager())
    }
}
