import SwiftUI

/// Row displaying an individual race result.
///
/// Shows rank, athlete name, time, difference, and FIS points.
///
/// ## Example
/// ```swift
/// ResultRowView(
///     result: result,
///     isFavorite: true,
///     onTap: { print("Selected athlete") }
/// )
/// ```
public struct ResultRowView: View {
    let result: RaceResult
    var isFavorite: Bool = false
    var onTap: (() -> Void)?
    
    public init(
        result: RaceResult,
        isFavorite: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.result = result
        self.isFavorite = isFavorite
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Rank
                rankView
                
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
                    
                    if result.status == .finished {
                        HStack(spacing: 8) {
                            if !result.formattedDiff.isEmpty {
                                Text(result.formattedDiff)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(result.formattedFISPoints)
                                .font(.caption)
                                .foregroundStyle(.skiBlue)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var rankView: some View {
        if let medal = result.medal {
            Text(medal.emoji)
                .font(.title3)
                .frame(width: 32)
        } else if result.status == .finished {
            Text("\(result.rank)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 32)
        } else {
            Text(result.status.shortCode)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(result.status.color)
                .frame(width: 32)
        }
    }
}

// MARK: - Result Header Row

public struct ResultHeaderRow: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            Text("Rank")
                .frame(width: 32)
            Text("Athlete")
            Spacer()
            Text("Time")
            Text("FIS")
                .frame(width: 40)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }
}

// MARK: - Non-Finisher Section

public struct NonFinisherSection: View {
    let title: String
    let results: [RaceResult]
    var onAthleteTap: ((Athlete) -> Void)?
    
    public init(
        title: String,
        results: [RaceResult],
        onAthleteTap: ((Athlete) -> Void)? = nil
    ) {
        self.title = title
        self.results = results
        self.onAthleteTap = onAthleteTap
    }
    
    public var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach(results) { result in
                    Button {
                        onAthleteTap?(result.athlete)
                    } label: {
                        HStack(spacing: 12) {
                            Text(result.status.shortCode)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(result.status.color)
                                .frame(width: 32)
                            
                            HStack(spacing: 6) {
                                Text(result.athlete.flagEmoji)
                                Text(result.athlete.fullName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.5))
        }
    }
}

// MARK: - Loading Row

public struct LoadingRow: View {
    let message: String
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview("Result Rows") {
    ScrollView {
        VStack(spacing: 0) {
            ResultHeaderRow()
            Divider()
            
            ForEach(PreviewData.wengenResults) { result in
                ResultRowView(
                    result: result,
                    isFavorite: result.athlete.fisCode == "512269"
                )
                Divider()
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
