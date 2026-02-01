import SwiftUI

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let prediction: GoalPrediction?
    let currentWeight: Double
    let targetWeight: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: prediction?.goalType.icon ?? "target")
                    .font(.title2)
                    .foregroundStyle(trendColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight Goal")
                        .font(.subheadline.bold())

                    if let prediction = prediction {
                        HStack(spacing: 4) {
                            Image(systemName: prediction.trendDirection.icon)
                            Text(prediction.trendDirection.rawValue)
                        }
                        .font(.caption)
                        .foregroundStyle(trendColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f kg", currentWeight))
                        .font(.title3.bold())

                    Text("of \(String(format: "%.1f", targetWeight)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress arc
            GoalProgressArc(
                current: currentWeight,
                target: targetWeight,
                trendDirection: prediction?.trendDirection ?? .steady
            )
            .frame(height: 100)

            // Prediction message
            if let prediction = prediction {
                VStack(spacing: 8) {
                    if let date = prediction.formattedPrediction {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(trendColor)

                            Text("On track to reach your goal by")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(date)
                                .font(.caption.bold())
                                .foregroundStyle(trendColor)
                        }
                    }

                    // Weekly change
                    let weeklyChange = prediction.weeklyChange
                    HStack {
                        Image(systemName: weeklyChange < 0 ? "arrow.down.right" : "arrow.up.right")
                        Text(String(format: "%.2f kg/week", abs(weeklyChange)))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Log more weight entries to see your prediction")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var trendColor: Color {
        guard let prediction = prediction else { return .blue }

        switch prediction.trendDirection {
        case .improving: return .green
        case .steady: return .blue
        case .declining: return .orange
        }
    }
}

// MARK: - Goal Progress Arc

struct GoalProgressArc: View {
    let current: Double
    let target: Double
    let trendDirection: TrendDirection

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
            let radius = min(geo.size.width / 2, geo.size.height) - 10

            ZStack {
                // Background arc
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // Progress arc
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(180 + (180 * animatedProgress)),
                        clockwise: false
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )

                // Center content
                VStack(spacing: 2) {
                    Text(remainingText)
                        .font(.title2.bold())

                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .offset(y: -10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = calculateProgress()
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = calculateProgress()
            }
        }
    }

    private func calculateProgress() -> Double {
        let diff = abs(target - current)
        let startDiff = max(diff, 10) // Assume 10kg as reasonable starting diff
        return max(0, min(1, 1 - (diff / startDiff)))
    }

    private var remainingText: String {
        let remaining = abs(target - current)
        return String(format: "%.1f kg", remaining)
    }

    private var gradientColors: [Color] {
        switch trendDirection {
        case .improving: return [.green, .mint]
        case .steady: return [.blue, .cyan]
        case .declining: return [.orange, .yellow]
        }
    }
}

// MARK: - Compact Goal Progress (for HomeView)

struct CompactGoalProgress: View {
    let prediction: GoalPrediction?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with trend indicator
                ZStack {
                    Circle()
                        .fill(trendColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: prediction?.trendDirection.icon ?? "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(trendColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal Progress")
                        .font(.subheadline.bold())

                    if let prediction = prediction {
                        Text(prediction.trendDirection.rawValue)
                            .font(.caption)
                            .foregroundStyle(trendColor)
                    } else {
                        Text("Tracking...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let prediction = prediction, let weeks = prediction.weeksRemaining {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(weeks)")
                            .font(.title3.bold())
                            .foregroundStyle(trendColor)
                        Text("weeks")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var trendColor: Color {
        guard let prediction = prediction else { return .blue }

        switch prediction.trendDirection {
        case .improving: return .green
        case .steady: return .blue
        case .declining: return .orange
        }
    }
}

// MARK: - Weight Trend Chart

struct GoalWeightTrendChart: View {
    let entries: [WeightEntry]
    let targetWeight: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)

            GeometryReader { geo in
                let minWeight = min(entries.map { $0.weightKg }.min() ?? targetWeight, targetWeight) - 2
                let maxWeight = max(entries.map { $0.weightKg }.max() ?? targetWeight, targetWeight) + 2
                let range = maxWeight - minWeight

                ZStack {
                    // Target line
                    let targetY = geo.size.height * (1 - (targetWeight - minWeight) / range)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: targetY))
                        path.addLine(to: CGPoint(x: geo.size.width, y: targetY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.green.opacity(0.5))

                    // Weight line
                    if entries.count >= 2 {
                        Path { path in
                            for (index, entry) in entries.enumerated() {
                                let x = geo.size.width * Double(index) / Double(entries.count - 1)
                                let y = geo.size.height * (1 - (entry.weightKg - minWeight) / range)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }

                    // Data points
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let x = entries.count > 1
                            ? geo.size.width * Double(index) / Double(entries.count - 1)
                            : geo.size.width / 2
                        let y = geo.size.height * (1 - (entry.weightKg - minWeight) / range)

                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 120)

            // Labels
            HStack {
                Text("Target: \(String(format: "%.1f", targetWeight)) kg")
                    .font(.caption)
                    .foregroundStyle(.green)

                Spacer()

                if let latest = entries.last {
                    Text("Current: \(String(format: "%.1f", latest.weightKg)) kg")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            GoalProgressCard(
                prediction: GoalPrediction(
                    goalType: .weightLoss,
                    currentValue: 85.0,
                    targetValue: 75.0,
                    predictedCompletionDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                    trendDirection: .improving,
                    weeklyChange: -0.5,
                    confidenceLevel: 0.75
                ),
                currentWeight: 85.0,
                targetWeight: 75.0
            )
            .padding()

            CompactGoalProgress(
                prediction: GoalPrediction(
                    goalType: .weightLoss,
                    currentValue: 85.0,
                    targetValue: 75.0,
                    trendDirection: .improving,
                    weeklyChange: -0.5
                )
            ) { }
            .padding()
        }
    }
}
