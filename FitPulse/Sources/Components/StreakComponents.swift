import SwiftUI

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Streak
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .subheadline
            case .large: return .title3
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak.type.icon)
                .font(.system(size: size.iconSize))
                .foregroundStyle(streakColor)

            Text("\(streak.currentCount)")
                .font(size.fontSize.bold())
                .foregroundStyle(streakColor)
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 2)
        .background(streakColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var streakColor: Color {
        if streak.isAtRisk {
            return .orange
        } else if streak.currentCount == 0 {
            return .gray
        }
        return .orange
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Streak
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: streak.type.icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(streak.type.displayName)
                        .font(.subheadline.bold())

                    Text(streak.type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(streak.currentCount)")
                            .font(.title2.bold())
                            .foregroundStyle(iconColor)

                        Image(systemName: "flame.fill")
                            .foregroundStyle(iconColor)
                    }

                    if streak.isAtRisk {
                        Text(String(localized: "At risk!"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Progress to next milestone
            let nextMilestone = StreakService.shared.getNextMilestone(from: streak.currentCount)
            let progress = Double(streak.currentCount) / Double(nextMilestone)

            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(iconColor)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(String(localized: "Next: \(nextMilestone) days"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let milestone = StreakService.shared.getStreakMilestone(for: nextMilestone) {
                        Text(milestone)
                            .font(.caption2)
                            .foregroundStyle(iconColor)
                    }
                }
            }

            // Longest streak
            if streak.longestCount > streak.currentCount {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)

                    Text(String(localized: "Personal best: \(streak.longestCount) days"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var iconColor: Color {
        if streak.isAtRisk {
            return .orange
        } else if streak.currentCount == 0 {
            return .gray
        }
        return .orange
    }
}

// MARK: - Streak Summary Row (Compact for HomeView)

struct StreakSummaryRow: View {
    let streaks: [Streak]
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: 16) {
                // Show active streaks
                ForEach(activeStreaks.prefix(4)) { streak in
                    StreakBadge(streak: streak, size: .small)
                }

                if activeStreaks.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .foregroundStyle(.gray)
                        Text(String(localized: "Start a streak!"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // At risk indicator
                if streaks.contains(where: { $0.isAtRisk && $0.currentCount > 0 }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(String(localized: "At risk"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            StreakDetailSheet(streaks: streaks)
        }
    }

    private var activeStreaks: [Streak] {
        streaks.filter { $0.currentCount > 0 && $0.isActive }
            .sorted { $0.currentCount > $1.currentCount }
    }
}

// MARK: - Streak Detail Sheet

struct StreakDetailSheet: View {
    let streaks: [Streak]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(streaks.sorted { $0.currentCount > $1.currentCount }) { streak in
                        StreakCard(streak: streak)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Your Streaks"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Streak Celebration View

struct StreakCelebrationView: View {
    let streak: Streak
    let milestone: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 24) {
                // Animated flame
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text(String(localized: "\(streak.currentCount) Day Streak!"))
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(milestone)
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Text(String(localized: "Keep up the momentum!"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Button(action: onDismiss) {
                    Text(String(localized: "Continue"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBadge(
            streak: Streak(type: .workout, currentCount: 7, longestCount: 14),
            size: .medium
        )

        StreakCard(
            streak: Streak(type: .workout, currentCount: 12, longestCount: 14)
        )
        .padding()

        StreakSummaryRow(streaks: [
            Streak(type: .workout, currentCount: 7),
            Streak(type: .hydration, currentCount: 3),
            Streak(type: .logging, currentCount: 5)
        ])
        .padding()
    }
}
