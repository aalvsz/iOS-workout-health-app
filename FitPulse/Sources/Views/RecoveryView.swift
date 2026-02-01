import SwiftUI
import Charts

struct RecoveryView: View {
    @StateObject private var viewModel = RecoveryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Recovery
                    if let analysis = viewModel.todayAnalysis {
                        TodayRecoveryCard(analysis: analysis)
                    }

                    // Time Range Picker
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(RecoveryViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Recovery Trend Chart
                    if !viewModel.recoveryChartData.isEmpty {
                        RecoveryTrendCard(data: viewModel.recoveryChartData)
                    }

                    // Key Metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        RecoveryMetricCard(
                            title: "HRV",
                            value: viewModel.currentHRV.formattedHRV,
                            average: "Avg: \(viewModel.averageHRV.formatted0) ms",
                            icon: "waveform.path.ecg",
                            color: .green
                        )

                        RecoveryMetricCard(
                            title: "Resting HR",
                            value: viewModel.currentRestingHR.formattedHeartRate,
                            average: "Avg: \(viewModel.averageRestingHR.formatted0) bpm",
                            icon: "heart.fill",
                            color: .red
                        )

                        RecoveryMetricCard(
                            title: "Sleep",
                            value: viewModel.currentSleep.formattedHours,
                            average: "Avg: \(viewModel.averageSleep.formatted1)h",
                            icon: "bed.double.fill",
                            color: .indigo
                        )

                        RecoveryMetricCard(
                            title: "Trend",
                            value: viewModel.recoveryTrend >= 0 ? "+" : "",
                            average: "\(viewModel.recoveryTrend.formatted1)%",
                            icon: viewModel.recoveryTrend >= 0 ? "arrow.up.right" : "arrow.down.right",
                            color: viewModel.recoveryTrend >= 0 ? .green : .red
                        )
                    }

                    // HRV Chart
                    if !viewModel.hrvChartData.isEmpty {
                        MetricTrendCard(
                            title: "Heart Rate Variability",
                            data: viewModel.hrvChartData,
                            color: .green,
                            unit: "ms"
                        )
                    }

                    // Sleep Chart
                    if !viewModel.sleepChartData.isEmpty {
                        MetricTrendCard(
                            title: "Sleep Duration",
                            data: viewModel.sleepChartData,
                            color: .indigo,
                            unit: "hours"
                        )
                    }

                    // Recovery Flags
                    if !viewModel.recentFlags.isEmpty {
                        RecoveryFlagsCard(flags: viewModel.recentFlags)
                    }

                    // Recommendations
                    RecommendationsCard(
                        workoutRec: viewModel.workoutRecommendation,
                        sleepRec: viewModel.sleepRecommendation
                    )

                    // Insights
                    if !viewModel.insights.isEmpty {
                        RecoveryInsightsCard(insights: viewModel.insights)
                    }
                }
                .padding()
            }
            .navigationTitle("Recovery")
            .refreshable {
                await viewModel.refreshData()
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

// MARK: - Today's Recovery Card
struct TodayRecoveryCard: View {
    let analysis: RecoveryAnalysis

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Recovery")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(Int(analysis.score))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))

                        VStack(alignment: .leading) {
                            Text("/ 100")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            RecoveryBadge(score: analysis.score, status: analysis.status)
                        }
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.recoveryColor(for: analysis.status).opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: analysis.score / 100)
                        .stroke(
                            Color.recoveryColor(for: analysis.status),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Image(systemName: analysis.status.icon)
                        .font(.title)
                        .foregroundStyle(Color.recoveryColor(for: analysis.status))
                }
                .frame(width: 80, height: 80)
            }

            // Readiness Meter
            ReadinessMeter(score: analysis.score)

            // Recommendation
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text(analysis.status.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Contributing Factors
            if !analysis.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contributing Factors")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ForEach(analysis.factors) { factor in
                            FactorPill(factor: factor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct FactorPill: View {
    let factor: RecoveryFactor

    private var color: Color {
        switch factor.impact {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(factor.name)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Recovery Trend Card
struct RecoveryTrendCard: View {
    let data: [ChartDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Trend")
                .font(.headline)

            Chart(data) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.3), .green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.value)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100])
            }
            .frame(height: 180)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Recovery Metric Card
struct RecoveryMetricCard: View {
    let title: String
    let value: String
    let average: String
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

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(average)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Metric Trend Card
struct MetricTrendCard: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    let unit: String

    private var latestValue: Double {
        data.last?.value ?? 0
    }

    private var average: Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0) { $0 + $1.value } / Double(data.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(latestValue, specifier: "%.1f") \(unit)")
                        .font(.subheadline.bold())

                    Text("Avg: \(average, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            TrendChart(
                data: data,
                color: color,
                showAxis: true,
                height: 120
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Recovery Flags Card
struct RecoveryFlagsCard: View {
    let flags: [RecoveryFlag]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)

                Spacer()

                Text("\(flags.count) this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(flags.prefix(5)) { flag in
                HStack(spacing: 12) {
                    Image(systemName: flag.type.icon)
                        .foregroundStyle(severityColor(flag.severity))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.type.rawValue)
                            .font(.subheadline)

                        Text(flag.date.relativeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(flag.type.recommendation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: 120)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func severityColor(_ severity: RecoveryFlag.Severity) -> Color {
        switch severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Recommendations Card
struct RecommendationsCard: View {
    let workoutRec: String
    let sleepRec: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                RecommendationRow(
                    icon: "figure.run",
                    title: "Workout",
                    text: workoutRec,
                    color: .blue
                )

                Divider()

                RecommendationRow(
                    icon: "bed.double.fill",
                    title: "Sleep",
                    text: sleepRec,
                    color: .indigo
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Recovery Insights Card
struct RecoveryInsightsCard: View {
    let insights: [Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)

            ForEach(insights.filter { $0.type == .recovery || $0.type == .sleep }) { insight in
                InsightRow(insight: insight)

                if insight.id != insights.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    RecoveryView()
        .environmentObject(UserProfile())
}
