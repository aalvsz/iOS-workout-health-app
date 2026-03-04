import SwiftUI

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: Challenge
    let onJoin: (() -> Void)?
    let onViewDetails: (() -> Void)?

    init(challenge: Challenge, onJoin: (() -> Void)? = nil, onViewDetails: (() -> Void)? = nil) {
        self.challenge = challenge
        self.onJoin = onJoin
        self.onViewDetails = onViewDetails
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: challenge.type.icon)
                    .font(.title2)
                    .foregroundStyle(typeColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline.bold())

                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if challenge.isActive {
                    TimeRemainingBadge(timeRemaining: challenge.formattedTimeRemaining)
                } else if challenge.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: challenge.isCompleted
                                        ? [.green, .mint]
                                        : [typeColor, typeColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * challenge.progressPercentage)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(challenge.progress)")
                        .font(.subheadline.bold())
                        .foregroundStyle(typeColor)
                    +
                    Text(" / \(challenge.target) \(challenge.type.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(challenge.progressPercentage * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(typeColor)
                }
            }

            // Action buttons
            if let onJoin = onJoin, !challenge.isActive && !challenge.isCompleted {
                Button(action: onJoin) {
                    Text(String(localized: "Join Challenge"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(typeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            onViewDetails?()
        }
    }

    private var typeColor: Color {
        switch challenge.type {
        case .workout: return .orange
        case .steps: return .green
        case .calories: return .red
        case .hydration: return .cyan
        case .logging: return .purple
        }
    }
}

// MARK: - Time Remaining Badge

struct TimeRemainingBadge: View {
    let timeRemaining: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption2)

            Text(timeRemaining)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.15))
        .foregroundStyle(.orange)
        .clipShape(Capsule())
    }
}

// MARK: - Challenge Complete View (Celebration)

struct ChallengeCompleteView: View {
    let challenge: Challenge
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Simple confetti effect
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(confettiColors[index % confettiColors.count])
                    .frame(width: 8, height: 8)
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -200...200)
                    )
                    .opacity(confettiOpacity)
            }

            VStack(spacing: 32) {
                // Trophy
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(scale)
                }

                VStack(spacing: 12) {
                    Text(String(localized: "Challenge Complete!"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(typeColor)

                    Text(String(localized: "You crushed it! \(challenge.target) \(challenge.type.unit) achieved."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text(String(localized: "Continue"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(typeColor)
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

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                confettiOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 1.0)) {
                    confettiOpacity = 0
                }
            }
        }
    }

    private var typeColor: Color {
        switch challenge.type {
        case .workout: return .orange
        case .steps: return .green
        case .calories: return .red
        case .hydration: return .cyan
        case .logging: return .purple
        }
    }

    private let confettiColors: [Color] = [
        .yellow, .orange, .red, .green, .blue, .purple, .pink
    ]
}

// MARK: - Compact Challenge Card (for HomeView)

struct CompactChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: challenge.type.icon)
                        .font(.title3)
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(challenge.title)
                            .font(.subheadline.bold())

                        Spacer()

                        TimeRemainingBadge(timeRemaining: challenge.formattedTimeRemaining)
                    }

                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(typeColor)
                                .frame(width: geo.size.width * challenge.progressPercentage)
                        }
                    }
                    .frame(height: 6)

                    Text("\(challenge.progress)/\(challenge.target) \(challenge.type.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var typeColor: Color {
        switch challenge.type {
        case .workout: return .orange
        case .steps: return .green
        case .calories: return .red
        case .hydration: return .cyan
        case .logging: return .purple
        }
    }
}

// MARK: - No Active Challenge Card

struct NoActiveChallengeCard: View {
    let onJoinChallenge: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            VStack(spacing: 4) {
                Text(String(localized: "Ready for a Challenge?"))
                    .font(.headline)

                Text(String(localized: "Join this week's challenge to push your limits!"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onJoinChallenge) {
                Text(String(localized: "See This Week's Challenge"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Challenge Stats View

struct ChallengeStatsView: View {
    let stats: ChallengeStats

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Challenge Stats"))
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                StatItem(value: "\(stats.totalCompleted)", label: String(localized: "Completed"))
                StatItem(value: "\(stats.currentStreak)", label: String(localized: "Week Streak"))

                if let type = stats.mostCompletedType {
                    StatItem(value: type.displayName, label: String(localized: "Favorite"))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ChallengeCard(
                challenge: Challenge(
                    title: "Workout Week",
                    description: "Complete 5 workouts this week",
                    type: .workout,
                    target: 5,
                    progress: 3,
                    endDate: Date().addingTimeInterval(86400 * 3)
                )
            )
            .padding()

            CompactChallengeCard(
                challenge: Challenge(
                    title: "Step It Up",
                    description: "Walk 50,000 steps",
                    type: .steps,
                    target: 50000,
                    progress: 32000,
                    endDate: Date().addingTimeInterval(86400 * 2)
                )
            ) { }
            .padding()

            NoActiveChallengeCard { }
                .padding()
        }
    }
}
