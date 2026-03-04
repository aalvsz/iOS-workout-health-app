import SwiftUI
import Charts

struct WeeklyProgressView: View {
    let summaries: [DailyHealthSummary]
    let profile: UserProfile

    private var weekDays: [DailyHealthSummary] {
        let calendar = Calendar.current
        let startOfWeek = Date().startOfWeek

        return (0..<7).compactMap { offset -> DailyHealthSummary? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }

            return summaries.first { calendar.isDate($0.date, inSameDayAs: date) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Overview
                    WeeklyOverviewCard(summaries: weekDays, profile: profile)

                    // Steps Chart
                    WeeklyMetricChart(
                        title: String(localized: "Steps"),
                        data: weekDays.map { ($0.date.shortDayOfWeek, Double($0.steps)) },
                        target: Double(profile.dailyStepsGoal),
                        color: .green,
                        unit: ""
                    )

                    // Calories Chart
                    WeeklyMetricChart(
                        title: String(localized: "Active Calories"),
                        data: weekDays.map { ($0.date.shortDayOfWeek, $0.activeCalories) },
                        target: nil,
                        color: .orange,
                        unit: "kcal"
                    )

                    // Sleep Chart
                    WeeklyMetricChart(
                        title: String(localized: "Sleep"),
                        data: weekDays.map { ($0.date.shortDayOfWeek, $0.sleepHours) },
                        target: profile.sleepGoalHours,
                        color: .indigo,
                        unit: "h"
                    )

                    // HRV Chart
                    WeeklyMetricChart(
                        title: String(localized: "HRV"),
                        data: weekDays.map { ($0.date.shortDayOfWeek, $0.hrvMs) },
                        target: nil,
                        color: .green,
                        unit: "ms"
                    )
                }
                .padding()
            }
            .navigationTitle(String(localized: "Weekly Progress"))
        }
    }
}

// MARK: - Weekly Overview Card
struct WeeklyOverviewCard: View {
    let summaries: [DailyHealthSummary]
    let profile: UserProfile

    private var totalSteps: Int {
        summaries.reduce(0) { $0 + $1.steps }
    }

    private var totalCalories: Double {
        summaries.reduce(0) { $0 + $1.activeCalories }
    }

    private var averageSleep: Double {
        let sleepValues = summaries.map(\.sleepHours).filter { $0 > 0 }
        guard !sleepValues.isEmpty else { return 0 }
        return sleepValues.reduce(0, +) / Double(sleepValues.count)
    }

    private var workoutDays: Int {
        summaries.filter { $0.workoutCount > 0 }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "This Week"))
                    .font(.headline)

                Spacer()

                Text(Date().startOfWeek.monthDay + " - " + Date().monthDay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                WeeklyStatBlock(
                    value: totalSteps.compact,
                    label: String(localized: "Steps"),
                    icon: "figure.walk"
                )

                Divider()
                    .frame(height: 50)

                WeeklyStatBlock(
                    value: totalCalories.compact,
                    label: String(localized: "Calories"),
                    icon: "flame.fill"
                )

                Divider()
                    .frame(height: 50)

                WeeklyStatBlock(
                    value: averageSleep.formatted1 + "h",
                    label: String(localized: "Avg Sleep"),
                    icon: "bed.double.fill"
                )

                Divider()
                    .frame(height: 50)

                WeeklyStatBlock(
                    value: "\(workoutDays)",
                    label: String(localized: "Workouts"),
                    icon: "figure.run"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct WeeklyStatBlock: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Metric Chart
struct WeeklyMetricChart: View {
    let title: String
    let data: [(String, Double)]
    let target: Double?
    let color: Color
    let unit: String

    private var average: Double {
        let values = data.map(\.1).filter { $0 > 0 }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Avg: \(average, specifier: "%.0f")\(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let target = target {
                        Text("Goal: \(target, specifier: "%.0f")\(unit)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Chart {
                ForEach(data.indices, id: \.self) { index in
                    BarMark(
                        x: .value("Day", data[index].0),
                        y: .value("Value", data[index].1)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(4)
                }

                if let target = target {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 3]))
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    WeeklyProgressView(
        summaries: (0..<7).map { i in
            DailyHealthSummary(
                date: Date().adding(days: -6 + i),
                activeCalories: Double.random(in: 200...600),
                basalCalories: 1800,
                steps: Int.random(in: 5000...15000),
                distanceKm: Double.random(in: 3...10),
                sleepHours: Double.random(in: 5...9),
                hrvMs: Double.random(in: 30...60),
                restingHeartRate: Double.random(in: 55...70),
                workoutCount: Int.random(in: 0...2),
                workoutMinutes: Double.random(in: 0...90),
                workoutCalories: Double.random(in: 0...500)
            )
        },
        profile: UserProfile()
    )
}
