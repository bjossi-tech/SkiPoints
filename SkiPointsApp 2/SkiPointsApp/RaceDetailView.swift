import SwiftUI

struct RaceDetailView: View {
    @StateObject private var viewModel: RaceDetailViewModel
    @Binding var favoriteAthletes: Set<String>
    
    init(race: Race, favoriteAthletes: Binding<Set<String>>) {
        _viewModel = StateObject(wrappedValue: RaceDetailViewModel(race: race))
        _favoriteAthletes = favoriteAthletes
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Race header
                raceHeader
                
                // Live indicator with auto-refresh status
                if viewModel.race.isLive {
                    liveIndicator
                }
                
                // Loading state for results
                if viewModel.isLoading && viewModel.race.results.isEmpty {
                    ProgressView("Loading results...")
                        .padding(.vertical, 40)
                }
                
                // Error state
                if let error = viewModel.error, viewModel.race.results.isEmpty {
                    ErrorView(error: error) {
                        await viewModel.loadResults()
                    }
                    .padding()
                }
                
                // Podium
                if !viewModel.race.podium.isEmpty {
                    podiumView
                }
                
                // Full results
                if !viewModel.race.results.isEmpty {
                    resultsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.race.location)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadResults()
            if viewModel.race.isLive {
                viewModel.startAutoRefresh()
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.loadResults()
        }
    }
    
    // MARK: - Race Header
    
    private var raceHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.race.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(viewModel.race.flagEmoji)
                        Text(viewModel.race.fullLocation)
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.race.eventType.shortName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.orange.opacity(0.2)))
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                StatusBadge(status: viewModel.race.status)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    // MARK: - Live Indicator
    
    private var liveIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            
            Text("LIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.red)
            
            Spacer()
            
            if viewModel.isAutoRefreshing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Auto-updating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Pull to refresh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.red.opacity(0.1)))
    }
    
    // MARK: - Podium
    
    private var podiumView: some View {
        VStack(spacing: 16) {
            Text("Podium")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Silver (2nd)
                if let second = viewModel.race.podium.first(where: { $0.rank == 2 }) {
                    podiumPosition(result: second, height: 60)
                }
                
                // Gold (1st)
                if let first = viewModel.race.podium.first(where: { $0.rank == 1 }) {
                    podiumPosition(result: first, height: 80)
                }
                
                // Bronze (3rd)
                if let third = viewModel.race.podium.first(where: { $0.rank == 3 }) {
                    podiumPosition(result: third, height: 50)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    private func podiumPosition(result: RaceResult, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(result.medal?.emoji ?? "")
                .font(.title)
            
            Text(result.athlete.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(result.athlete.flagEmoji)
            
            Text(result.formattedTime)
                .font(.caption2)
                .monospacedDigit()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(podiumColor(for: result.rank))
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func podiumColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .gray
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            ForEach(viewModel.race.results) { result in
                ResultRowView(
                    result: result,
                    isFavorite: favoriteAthletes.contains(result.athlete.fisCode),
                    onToggleFavorite: {
                        if favoriteAthletes.contains(result.athlete.fisCode) {
                            favoriteAthletes.remove(result.athlete.fisCode)
                        } else {
                            favoriteAthletes.insert(result.athlete.fisCode)
                        }
                    }
                )
                
                if result.id != viewModel.race.results.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
}

// MARK: - Result Row

struct ResultRowView: View {
    let result: RaceResult
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            if let medal = result.medal {
                Text(medal.emoji)
                    .font(.title3)
                    .frame(width: 32)
            } else {
                Text("\(result.rank)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)
            }
            
            // Athlete info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(result.athlete.flagEmoji)
                    Text(result.athlete.fullName)
                        .font(.subheadline)
                        .fontWeight(result.isPodium ? .semibold : .regular)
                    
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                
                if let brand = result.athlete.skiBrand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Time and points
            VStack(alignment: .trailing, spacing: 2) {
                Text(result.formattedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                
                HStack(spacing: 8) {
                    if !result.formattedDifference.isEmpty {
                        Text(result.formattedDifference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(result.formattedFISPoints)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleFavorite?()
        }
    }
}

#Preview {
    NavigationStack {
        RaceDetailView(
            race: PreviewData.wengenSuperG,
            favoriteAthletes: .constant(["512269"])
        )
    }
}
