import SwiftUI

struct MomentumRing: View {
    let momentum: MomentumScore
    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background glow when momentum is high
                if momentum.score > 70 {
                    Circle()
                        .fill(momentumColor.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                pulseScale = 1.1
                            }
                        }
                }

                // Track
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [momentumColor.opacity(0.5), momentumColor],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(momentum.score))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(momentumColor)

                    Text("MOMENTUM")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                }
            }

            // Status text
            Text(momentum.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Breakdown dots
            HStack(spacing: 24) {
                MomentumDot(label: "Workouts", filled: momentum.workoutScore > 0.5, color: .orange)
                MomentumDot(label: "Nutrition", filled: momentum.nutritionScore > 0.5, color: .green)
                MomentumDot(label: "Hydration", filled: momentum.hydrationScore > 0.5, color: .cyan)
                MomentumDot(label: "Recovery", filled: momentum.recoveryScore > 0.5, color: .purple)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = momentum.score / 100
            }
        }
        .onChange(of: momentum.score) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue / 100
            }
        }
    }

    private var momentumColor: Color {
        switch momentum.score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

struct MomentumDot: View {
    let label: String
    let filled: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(filled ? color : color.opacity(0.2))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Momentum Score Model
struct MomentumScore {
    let score: Double // 0-100
    let workoutScore: Double // 0-1
    let nutritionScore: Double // 0-1
    let hydrationScore: Double // 0-1
    let recoveryScore: Double // 0-1

    var message: String {
        switch score {
        case 80...100: return "You're on fire! Keep this energy going."
        case 60..<80: return "Strong momentum. Stay consistent!"
        case 40..<60: return "Building momentum. Every action counts."
        case 20..<40: return "Time to refocus. Start with one small win."
        default: return "Let's get back on track today."
        }
    }

    static func calculate(
        weeklyWorkoutsCompleted: Int,
        weeklyWorkoutGoal: Int,
        nutritionAdherence: Double, // 0-1, how close to targets
        hydrationProgress: Double, // 0-1
        recoveryScore: Double? // 0-100
    ) -> MomentumScore {
        let workoutScore = min(1.0, Double(weeklyWorkoutsCompleted) / Double(max(1, weeklyWorkoutGoal)))
        let nutritionScore = min(1.0, nutritionAdherence)
        let hydrationScore = min(1.0, hydrationProgress)
        let recoveryNormalized = (recoveryScore ?? 70) / 100

        // Weighted average - workouts and nutrition matter most
        let score = (workoutScore * 30 + nutritionScore * 30 + hydrationScore * 20 + recoveryNormalized * 20)

        return MomentumScore(
            score: score,
            workoutScore: workoutScore,
            nutritionScore: nutritionScore,
            hydrationScore: hydrationScore,
            recoveryScore: recoveryNormalized
        )
    }
}

#Preview {
    VStack(spacing: 40) {
        MomentumRing(momentum: MomentumScore(
            score: 85,
            workoutScore: 1.0,
            nutritionScore: 0.8,
            hydrationScore: 0.9,
            recoveryScore: 0.7
        ))

        MomentumRing(momentum: MomentumScore(
            score: 45,
            workoutScore: 0.3,
            nutritionScore: 0.5,
            hydrationScore: 0.6,
            recoveryScore: 0.4
        ))
    }
}
