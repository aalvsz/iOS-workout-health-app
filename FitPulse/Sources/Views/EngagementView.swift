import SwiftUI

struct EngagementView: View {
    @StateObject private var viewModel = EngagementViewModel()
    @State private var selectedSegment = 0

    let segments = [String(localized: "Streaks"), String(localized: "Achievements"), String(localized: "Challenges"), String(localized: "Goals")]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker
                Picker(String(localized: "Section"), selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    switch selectedSegment {
                    case 0:
                        streaksSection
                    case 1:
                        achievementsSection
                    case 2:
                        challengesSection
                    case 3:
                        goalsSection
                    default:
                        EmptyView()
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationTitle(String(localized: "Progress"))
            .task {
                await viewModel.loadData()
            }
            // Celebration overlays
            .overlay {
                if viewModel.showStreakCelebration,
                   let streak = viewModel.celebratingStreak,
                   let milestone = viewModel.celebratingMilestone {
                    StreakCelebrationView(
                        streak: streak,
                        milestone: milestone,
                        onDismiss: viewModel.dismissStreakCelebration
                    )
                }
            }
            .overlay {
                if viewModel.showAchievementUnlock,
                   let achievement = viewModel.unlockedAchievement {
                    AchievementUnlockView(
                        achievement: achievement,
                        onDismiss: viewModel.dismissAchievementUnlock
                    )
                }
            }
            .overlay {
                if viewModel.showChallengeComplete,
                   let challenge = viewModel.completedChallenge {
                    ChallengeCompleteView(
                        challenge: challenge,
                        onDismiss: viewModel.dismissChallengeComplete
                    )
                }
            }
        }
    }

    // MARK: - Streaks Section

    private var streaksSection: some View {
        VStack(spacing: 16) {
            // Summary card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Your Streaks"))
                            .font(.headline)

                        Text(String(localized: "\(viewModel.streakSummary.totalActiveStreaks) active"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let best = viewModel.streakSummary.allTimeBestStreak {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(best.longestCount)")
                                    .font(.title2.bold())
                            }
                            Text(String(localized: "Personal Best"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // Individual streak cards
            ForEach(viewModel.streaks.sorted { $0.currentCount > $1.currentCount }) { streak in
                StreakCard(streak: streak)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(spacing: 20) {
            // Summary
            AchievementProgressSummary(summary: viewModel.achievementSummary)
                .padding(.horizontal)

            // Categories
            ForEach(AchievementCategory.allCases, id: \.self) { category in
                let categoryAchievements = viewModel.getAchievements(by: category)
                if !categoryAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(.blue)
                            Text(category.displayName)
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        ForEach(categoryAchievements.sorted { $0.progress > $1.progress }) { achievement in
                            AchievementCard(achievement: achievement)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Challenges Section

    private var challengesSection: some View {
        VStack(spacing: 20) {
            // Active challenge
            if let challenge = viewModel.activeChallenge {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Active Challenge"))
                        .font(.headline)
                        .padding(.horizontal)

                    ChallengeCard(challenge: challenge)
                        .padding(.horizontal)

                    Button(action: viewModel.abandonChallenge) {
                        Text(String(localized: "Abandon Challenge"))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                }
            } else {
                NoActiveChallengeCard(onJoinChallenge: viewModel.joinWeeklyChallenge)
                    .padding(.horizontal)
            }

            // Stats
            ChallengeStatsView(stats: viewModel.challengeStats)
                .padding(.horizontal)

            // Completed challenges
            let completed = viewModel.challengeStats.activeChallenge == nil
                ? ChallengeService.shared.getCompletedChallenges()
                : []

            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Completed"))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(completed.prefix(5)) { challenge in
                        HStack {
                            Image(systemName: challenge.type.icon)
                                .foregroundStyle(.green)

                            Text(challenge.title)
                                .font(.subheadline)

                            Spacer()

                            if let date = challenge.completedDate {
                                Text(date.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(spacing: 20) {
            // Goal progress card
            let profile = PersistenceController.shared.loadProfile()
            let weightHistory = PersistenceController.shared.loadWeightHistory()

            GoalProgressCard(
                prediction: viewModel.goalPrediction,
                currentWeight: weightHistory.last?.weightKg ?? profile.weightKg,
                targetWeight: profile.targetWeightKg ?? profile.weightKg
            )
            .padding(.horizontal)

            // Weight trend chart
            if weightHistory.count >= 3 {
                GoalWeightTrendChart(
                    entries: Array(weightHistory.suffix(14)),
                    targetWeight: profile.targetWeightKg ?? profile.weightKg
                )
                .padding(.horizontal)
            }

            // Tips
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Tips"))
                    .font(.headline)
                    .padding(.horizontal)

                GoalTipCard(
                    icon: "scalemass.fill",
                    title: String(localized: "Log Regularly"),
                    description: String(localized: "Log your weight at the same time each day for accurate tracking.")
                )
                .padding(.horizontal)

                GoalTipCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "Focus on Trends"),
                    description: String(localized: "Daily fluctuations are normal. Watch the weekly trend instead.")
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Goal Tip Card

struct GoalTipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    EngagementView()
}
