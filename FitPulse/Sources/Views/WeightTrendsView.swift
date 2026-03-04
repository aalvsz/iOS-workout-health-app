import SwiftUI
import Charts

struct WeightTrendsView: View {
    @StateObject private var viewModel = WeightTrendsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker(String(localized: "Time Range"), selection: $viewModel.selectedRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)  // "30D", "60D", "90D" are technical labels
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedRange) { _, _ in
                        viewModel.onRangeChanged()
                    }

                    // Weight Chart Card
                    if !viewModel.chartData.isEmpty {
                        WeightChartCard(
                            chartData: viewModel.chartData,
                            movingAverageData: viewModel.movingAverageData,
                            targetWeight: viewModel.targetWeight
                        )
                    }

                    // Stats Grid
                    StatsGridSection(viewModel: viewModel)

                    // Target Weight Progress
                    if let target = viewModel.targetWeight,
                       let current = viewModel.currentWeight,
                       let progress = viewModel.progressToTarget {
                        TargetProgressCard(
                            currentWeight: current,
                            targetWeight: target,
                            progress: progress,
                            fitnessGoal: PersistenceController.shared.loadProfile().fitnessGoal
                        )
                    }

                    // Recent Entries
                    if !viewModel.entries.isEmpty {
                        RecentEntriesCard(
                            entries: Array(viewModel.entries.suffix(10).reversed())
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Weight Trends"))
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

// MARK: - Weight Chart Card

private struct WeightChartCard: View {
    let chartData: [ChartDataPoint]
    let movingAverageData: [ChartDataPoint]
    let targetWeight: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Weight"))
                .font(.headline)

            Chart {
                // Area fill + line for actual weight
                ForEach(chartData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.value),
                        series: .value("Series", "Weight")
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }

                // 7-day moving average (dashed orange)
                ForEach(movingAverageData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.value),
                        series: .value("Series", "Average")
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(dash: [5, 3]))
                }

                // Target weight rule line (dashed green)
                if let target = targetWeight {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(dash: [6, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text(String(localized: "Target: \(target, specifier: "%.1f") kg"))
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: .blue, label: String(localized: "Weight"))
                LegendDot(color: .orange, label: String(localized: "7-Day Avg"))
                if targetWeight != nil {
                    LegendDot(color: .green, label: String(localized: "Target"))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Stats Grid

private struct StatsGridSection: View {
    @ObservedObject var viewModel: WeightTrendsViewModel

    private var fitnessGoal: UserProfile.FitnessGoal {
        PersistenceController.shared.loadProfile().fitnessGoal
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Current Weight
            StatCard(
                title: String(localized: "Current"),
                value: viewModel.currentWeight.map { String(format: "%.1f", $0) } ?? "--",
                unit: String(localized: "kg"),
                icon: "scalemass.fill",
                color: .blue
            )

            // Weekly Change
            StatCard(
                title: String(localized: "Weekly"),
                value: formatChange(viewModel.weeklyChange),
                unit: String(localized: "kg"),
                icon: "calendar",
                color: changeColor(viewModel.weeklyChange, goal: fitnessGoal)
            )

            // Monthly Change
            StatCard(
                title: String(localized: "Monthly"),
                value: formatChange(viewModel.monthlyChange),
                unit: String(localized: "kg"),
                icon: "calendar.badge.clock",
                color: changeColor(viewModel.monthlyChange, goal: fitnessGoal)
            )

            // Goal Progress
            StatCard(
                title: String(localized: "Goal"),
                value: viewModel.progressToTarget.map { String(format: "%.0f%%", $0 * 100) } ?? "--",
                unit: "",
                icon: "flag.fill",
                color: .purple
            )
        }
    }

    private func formatChange(_ change: Double?) -> String {
        guard let change = change else { return "--" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))"
    }

    private func changeColor(_ change: Double?, goal: UserProfile.FitnessGoal) -> Color {
        guard let change = change else { return .secondary }

        switch goal {
        case .loseWeight:
            // Losing weight is positive for this goal
            return change < 0 ? .green : (change > 0 ? .red : .secondary)
        case .gainMuscle:
            // Gaining weight is positive for this goal
            return change > 0 ? .green : (change < 0 ? .red : .secondary)
        case .maintain, .recomp, .performance:
            // Stability is good; large swings are bad
            return abs(change) < 0.5 ? .green : .orange
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Target Progress Card

private struct TargetProgressCard: View {
    let currentWeight: Double
    let targetWeight: Double
    let progress: Double
    let fitnessGoal: UserProfile.FitnessGoal

    private var remaining: Double {
        abs(currentWeight - targetWeight)
    }

    private var directionLabel: String {
        if currentWeight > targetWeight {
            return String(localized: "to lose")
        } else if currentWeight < targetWeight {
            return String(localized: "to gain")
        } else {
            return String(localized: "on target")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "Target Progress"))
                    .font(.headline)

                Spacer()

                Text(String(localized: "\(remaining, specifier: "%.1f") kg \(directionLabel)"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)

            // Labels
            HStack {
                Text(String(localized: "Start"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(String(localized: "\(Int(progress * 100))%"))
                    .font(.caption.bold())
                    .foregroundStyle(.blue)

                Spacer()

                Text(String(localized: "\(targetWeight, specifier: "%.1f") kg"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Recent Entries Card

private struct RecentEntriesCard: View {
    let entries: [WeightEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recent Entries"))
                .font(.headline)

            ForEach(entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, style: .date)
                            .font(.subheadline)

                        if let note = entry.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Text(String(localized: "\(entry.weightKg, specifier: "%.1f") kg"))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                }
                .padding(.vertical, 4)

                if entry.id != entries.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Preview

#Preview {
    WeightTrendsView()
        .environmentObject(UserProfile())
}
