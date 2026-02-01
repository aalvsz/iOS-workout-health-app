import SwiftUI

struct TodaysPriorityCard: View {
    let priority: TodaysPriority
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Priority content
            HStack(spacing: 16) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(priority.color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: priority.icon)
                        .font(.title2)
                        .foregroundStyle(priority.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S PRIORITY")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    Text(priority.title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(priority.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()

            // Action button
            if let actionText = priority.actionText {
                Button(action: onAction) {
                    HStack {
                        Text(actionText)
                            .font(.subheadline.bold())

                        Image(systemName: "arrow.right")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(priority.color)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Priority Model
struct TodaysPriority {
    let type: PriorityType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let actionText: String?
    let action: PriorityAction?

    enum PriorityType {
        case recovery
        case workout
        case nutrition
        case hydration
        case celebration
    }

    enum PriorityAction {
        case startWorkout
        case logMeal
        case logWater
        case rest
        case viewDetails
    }

    // Smart priority generation based on user data
    static func generate(
        recoveryScore: Double?,
        todayWorkouts: Int,
        weeklyWorkoutGoal: Int,
        weeklyWorkoutsCompleted: Int,
        caloriesConsumed: Double,
        calorieTarget: Double,
        proteinConsumed: Double,
        proteinTarget: Double,
        hydrationProgress: Double,
        lastWorkoutDate: Date?
    ) -> TodaysPriority {

        // Check recovery first - if low, prioritize rest
        if let recovery = recoveryScore, recovery < 40 {
            return TodaysPriority(
                type: .recovery,
                title: "Rest & Recover",
                subtitle: "Your body needs recovery. Take it easy today.",
                icon: "bed.double.fill",
                color: .purple,
                actionText: nil,
                action: .rest
            )
        }

        // Check hydration - quick win
        if hydrationProgress < 0.3 {
            return TodaysPriority(
                type: .hydration,
                title: "Hydrate Now",
                subtitle: "You're behind on water. Drink a glass to boost energy.",
                icon: "drop.fill",
                color: .cyan,
                actionText: "Log Water",
                action: .logWater
            )
        }

        // Check if it's a good day for a workout
        if let recovery = recoveryScore, recovery > 70, todayWorkouts == 0 {
            let remaining = weeklyWorkoutGoal - weeklyWorkoutsCompleted
            if remaining > 0 {
                return TodaysPriority(
                    type: .workout,
                    title: "Great Day to Train",
                    subtitle: "Recovery is optimal. \(remaining) workout\(remaining == 1 ? "" : "s") left this week.",
                    icon: "flame.fill",
                    color: .orange,
                    actionText: "Start Workout",
                    action: .startWorkout
                )
            }
        }

        // Check protein intake
        let proteinRemaining = proteinTarget - proteinConsumed
        if proteinRemaining > 30 {
            return TodaysPriority(
                type: .nutrition,
                title: "Protein Boost Needed",
                subtitle: "\(Int(proteinRemaining))g protein left today. Time for a protein-rich meal.",
                icon: "fork.knife",
                color: .green,
                actionText: "Log Meal",
                action: .logMeal
            )
        }

        // Celebration - user is doing well!
        if hydrationProgress >= 0.8 && (caloriesConsumed / calorieTarget) > 0.7 {
            return TodaysPriority(
                type: .celebration,
                title: "You're Crushing It!",
                subtitle: "Nutrition and hydration on point. Keep the momentum going.",
                icon: "star.fill",
                color: .yellow,
                actionText: nil,
                action: nil
            )
        }

        // Default - balanced day
        return TodaysPriority(
            type: .nutrition,
            title: "Stay on Track",
            subtitle: "Log your meals to hit your nutrition targets.",
            icon: "chart.line.uptrend.xyaxis",
            color: .blue,
            actionText: "Log Meal",
            action: .logMeal
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        TodaysPriorityCard(
            priority: TodaysPriority(
                type: .workout,
                title: "Great Day to Train",
                subtitle: "Recovery is optimal. 3 workouts left this week.",
                icon: "flame.fill",
                color: .orange,
                actionText: "Start Workout",
                action: .startWorkout
            ),
            onAction: {}
        )

        TodaysPriorityCard(
            priority: TodaysPriority(
                type: .celebration,
                title: "You're Crushing It!",
                subtitle: "Nutrition and hydration on point.",
                icon: "star.fill",
                color: .yellow,
                actionText: nil,
                action: nil
            ),
            onAction: {}
        )
    }
    .padding()
}
