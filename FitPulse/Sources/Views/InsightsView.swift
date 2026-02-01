import SwiftUI

struct InsightsView: View {
    let insights: [Insight]

    var body: some View {
        NavigationStack {
            List {
                ForEach(prioritizedInsights) { insight in
                    InsightDetailRow(insight: insight)
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var prioritizedInsights: [Insight] {
        insights.sorted { $0.priority > $1.priority }
    }
}

struct InsightDetailRow: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundStyle(priorityColor)

                Text(insight.title)
                    .font(.headline)

                Spacer()

                PriorityBadge(priority: insight.priority)
            }

            Text(insight.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if insight.actionable, let action = insight.action {
                Button(action: {
                    // Handle action
                }) {
                    Text(action)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

struct PriorityBadge: View {
    let priority: Insight.Priority

    var body: some View {
        Text(priorityText)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityText: String {
        switch priority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

#Preview {
    InsightsView(insights: [
        Insight(
            title: "Recovery Declining",
            description: "Your recovery scores have dropped 15% this week. Consider reducing training intensity.",
            type: .recovery,
            priority: .high,
            actionable: true,
            action: "View Recovery"
        ),
        Insight(
            title: "Sleep Deficit",
            description: "You've averaged 6.2 hours of sleep this week, below your 8 hour goal.",
            type: .sleep,
            priority: .medium
        ),
        Insight(
            title: "Weekly Goal Achieved",
            description: "Congratulations! You've completed 5 workouts this week.",
            type: .workout,
            priority: .low
        )
    ])
}
