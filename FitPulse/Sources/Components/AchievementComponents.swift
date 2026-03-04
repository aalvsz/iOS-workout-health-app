import SwiftUI

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var frameSize: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 64
            case .large: return 88
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 28
            case .large: return 40
            }
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(achievement.isUnlocked ? tierGradient : lockedGradient)
                .frame(width: size.frameSize, height: size.frameSize)

            // Icon
            Image(systemName: achievement.iconName)
                .font(.system(size: size.iconSize))
                .foregroundStyle(achievement.isUnlocked ? .white : .gray)

            // Lock overlay for locked achievements
            if !achievement.isUnlocked {
                Circle()
                    .fill(.black.opacity(0.3))
                    .frame(width: size.frameSize, height: size.frameSize)

                Image(systemName: "lock.fill")
                    .font(.system(size: size.iconSize / 2))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var tierGradient: LinearGradient {
        switch achievement.tier {
        case .bronze:
            return LinearGradient(colors: [.brown, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [.gray, .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var lockedGradient: LinearGradient {
        LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 16) {
            AchievementBadge(achievement: achievement, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                    Spacer()

                    Text(achievement.tier.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tierColor.opacity(0.2))
                        .foregroundStyle(tierColor)
                        .clipShape(Capsule())
                }

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !achievement.isUnlocked {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(tierColor)
                                .frame(width: geo.size.width * achievement.progress)
                        }
                    }
                    .frame(height: 4)

                    Text("\(achievement.currentProgress)/\(achievement.targetValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let unlockedDate = achievement.unlockedDate {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(String(localized: "Unlocked \(unlockedDate.formatted(.relative(presentation: .named)))"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }

    private var tierColor: Color {
        switch achievement.tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
}

// MARK: - Achievements Grid View

struct AchievementsGridView: View {
    let achievements: [Achievement]
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(achievements) { achievement in
                VStack(spacing: 8) {
                    AchievementBadge(achievement: achievement, size: .medium)

                    Text(achievement.title)
                        .font(.caption2)
                        .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}

// MARK: - Achievement Unlock View (Celebration Modal)

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = -30
    @State private var opacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 32) {
                // Badge with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(tierColor.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    AchievementBadge(achievement: achievement, size: .large)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                }

                VStack(spacing: 12) {
                    Text(String(localized: "Achievement Unlocked!"))
                        .font(.caption)
                        .foregroundStyle(tierColor)
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(achievement.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    HStack {
                        Image(systemName: achievement.tier.icon)
                        Text(achievement.tier.displayName)
                    }
                    .font(.headline)
                    .foregroundStyle(tierColor)
                    .padding(.top, 8)
                }

                Button(action: onDismiss) {
                    Text(String(localized: "Awesome!"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tierColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                scale = 1.2
                rotation = 0
                opacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
        }
    }

    private var tierColor: Color {
        switch achievement.tier {
        case .bronze: return .orange
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
}

// MARK: - Achievement Progress Summary

struct AchievementProgressSummary: View {
    let summary: AchievementSummary

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Achievements"))
                    .font(.headline)
                Spacer()
                Text("\(summary.unlockedCount)/\(summary.totalAchievements)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * summary.progress)
                }
            }
            .frame(height: 12)

            // Tier breakdown
            HStack(spacing: 16) {
                ForEach(AchievementTier.allCases, id: \.self) { tier in
                    let count = summary.byTier[tier]?.count ?? 0
                    VStack(spacing: 4) {
                        Image(systemName: tier.icon)
                            .foregroundStyle(tierColor(tier))
                        Text("\(count)")
                            .font(.caption.bold())
                    }
                }
            }

            // Recently unlocked
            if !summary.recentlyUnlocked.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Recently Unlocked"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(summary.recentlyUnlocked) { achievement in
                                AchievementBadge(achievement: achievement, size: .small)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tierColor(_ tier: AchievementTier) -> Color {
        switch tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .purple
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AchievementBadge(
                achievement: Achievement(
                    id: "test",
                    title: "Test",
                    description: "Test description",
                    tier: .gold,
                    category: .streak,
                    targetValue: 10,
                    currentProgress: 10,
                    unlockedDate: Date()
                ),
                size: .large
            )

            AchievementCard(
                achievement: Achievement(
                    id: "test",
                    title: "Week Warrior",
                    description: "Complete a 7-day streak",
                    tier: .silver,
                    category: .streak,
                    targetValue: 7,
                    currentProgress: 5
                )
            )
            .padding()

            AchievementCard(
                achievement: Achievement(
                    id: "test2",
                    title: "First Steps",
                    description: "Complete your first workout",
                    tier: .bronze,
                    category: .workout,
                    targetValue: 1,
                    currentProgress: 1,
                    unlockedDate: Date()
                )
            )
            .padding()
        }
    }
}
