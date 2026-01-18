import SwiftUI

/// Displays an athlete's profile with biography and recent results.
///
/// ## Example
/// ```swift
/// AthleteProfileView(
///     athlete: athlete,
///     recentResults: results,
///     isFavorite: true,
///     onToggleFavorite: { ... }
/// )
/// ```
public struct AthleteProfileView: View {
    let athlete: Athlete
    var recentResults: [RaceResult] = []
    var isFavorite: Bool = false
    var isLoading: Bool = false
    var onToggleFavorite: (() -> Void)?
    var onResultSelected: ((RaceResult) -> Void)?
    
    public init(
        athlete: Athlete,
        recentResults: [RaceResult] = [],
        isFavorite: Bool = false,
        isLoading: Bool = false,
        onToggleFavorite: (() -> Void)? = nil,
        onResultSelected: ((RaceResult) -> Void)? = nil
    ) {
        self.athlete = athlete
        self.recentResults = recentResults
        self.isFavorite = isFavorite
        self.isLoading = isLoading
        self.onToggleFavorite = onToggleFavorite
        self.onResultSelected = onResultSelected
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Profile header
                profileHeader
                
                // Stats grid
                statsSection
                
                // Quick actions
                actionButtons
                
                // Recent results
                if isLoading {
                    LoadingRow(message: "Loading results...")
                } else if !recentResults.isEmpty {
                    recentResultsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Athlete")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onToggleFavorite?()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .secondary)
                }
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            AthleteAvatar(athlete: athlete, size: 100)
            
            // Name
            VStack(spacing: 4) {
                Text(athlete.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Text(athlete.flagEmoji)
                    Text(athlete.nation)
                        .foregroundStyle(.secondary)
                    
                    if let brand = athlete.skiBrand {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(brand)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statItem(
                title: "FIS Points",
                value: athlete.currentFISPoints.map { String(format: "%.2f", $0) } ?? "—"
            )
            
            statItem(
                title: "WC Rank",
                value: athlete.worldCupRank.map { "#\($0)" } ?? "—"
            )
            
            statItem(
                title: "Age",
                value: "\(athlete.age)"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Favorite button
            Button {
                onToggleFavorite?()
            } label: {
                Label(
                    isFavorite ? "Favorited" : "Add to Favorites",
                    systemImage: isFavorite ? "star.fill" : "star"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(isFavorite ? .yellow : .secondary)
            
            // FIS Profile link
            if let url = athlete.fisProfileURL {
                Link(destination: url) {
                    Label("FIS Profile", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Recent Results
    
    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.headline)
            
            ForEach(recentResults) { result in
                Button {
                    onResultSelected?(result)
                } label: {
                    HStack {
                        // Rank
                        if let medal = result.medal {
                            Text(medal.emoji)
                                .frame(width: 32)
                        } else {
                            Text("\(result.rank)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(width: 32)
                        }
                        
                        // Race info (would need race data)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Race \(result.raceID)")
                                .font(.subheadline)
                            Text(result.formattedTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // FIS points
                        Text(result.formattedFISPoints)
                            .font(.subheadline)
                            .foregroundStyle(.skiBlue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if result.id != recentResults.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
        )
    }
}

// MARK: - Athlete Avatar

public struct AthleteAvatar: View {
    let athlete: Athlete
    var size: CGFloat = 44
    
    public init(athlete: Athlete, size: CGFloat = 44) {
        self.athlete = athlete
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.skiBlue.opacity(0.7), .skiBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(athlete.firstName.prefix(1) + athlete.lastName.prefix(1))
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Athlete Profile") {
    NavigationStack {
        AthleteProfileView(
            athlete: PreviewData.odermatt,
            recentResults: PreviewData.wengenResults.filter { $0.athlete.fisCode == "512269" },
            isFavorite: true
        )
    }
}

#Preview("Athlete Profile - Loading") {
    NavigationStack {
        AthleteProfileView(
            athlete: PreviewData.shiffrin,
            isLoading: true
        )
    }
}
