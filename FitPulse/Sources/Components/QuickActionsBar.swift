import SwiftUI
import UIKit

struct QuickActionsBar: View {
    let onLogWater: () -> Void
    let onLogMeal: () -> Void
    let onStartWorkout: () -> Void
    let onLogWeight: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            QuickActionButton(
                icon: "drop.fill",
                label: String(localized: "Water"),
                color: .cyan,
                action: onLogWater
            )

            QuickActionButton(
                icon: "fork.knife",
                label: String(localized: "Meal"),
                color: .green,
                action: onLogMeal
            )

            QuickActionButton(
                icon: "figure.run",
                label: String(localized: "Workout"),
                color: .orange,
                action: onStartWorkout
            )

            QuickActionButton(
                icon: "scalemass.fill",
                label: String(localized: "Weight"),
                color: .purple,
                action: onLogWeight
            )
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Quick Action Button
struct FloatingQuickAction: View {
    @State private var isExpanded = false

    let onLogWater: () -> Void
    let onLogMeal: () -> Void
    let onStartWorkout: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                FloatingActionItem(icon: "drop.fill", color: .cyan, action: {
                    isExpanded = false
                    onLogWater()
                })
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))

                FloatingActionItem(icon: "fork.knife", color: .green, action: {
                    isExpanded = false
                    onLogMeal()
                })
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))

                FloatingActionItem(icon: "figure.run", color: .orange, action: {
                    isExpanded = false
                    onStartWorkout()
                })
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }

            // Main FAB
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)

                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct FloatingActionItem: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.3), radius: 4, y: 2)

                Image(systemName: icon)
                    .font(.body.bold())
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()

        QuickActionsBar(
            onLogWater: {},
            onLogMeal: {},
            onStartWorkout: {},
            onLogWeight: {}
        )
        .padding()

        Spacer()

        HStack {
            Spacer()
            FloatingQuickAction(
                onLogWater: {},
                onLogMeal: {},
                onStartWorkout: {}
            )
            .padding()
        }
    }
}
