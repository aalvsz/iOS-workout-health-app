import SwiftUI

struct RecoveryIndicator: View {
    let score: Double
    let status: RecoveryStatus
    let showDetails: Bool

    init(score: Double, status: RecoveryStatus, showDetails: Bool = true) {
        self.score = score
        self.status = status
        self.showDetails = showDetails
    }

    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.recoveryColor(for: status).opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        Color.recoveryColor(for: status),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: score)

                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text(status.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            if showDetails {
                // Status Icon and Recommendation
                HStack(spacing: 8) {
                    Image(systemName: status.icon)
                        .font(.title3)
                        .foregroundStyle(Color.recoveryColor(for: status))

                    Text(status.recommendation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.recoveryColor(for: status).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Compact Recovery Badge
struct RecoveryBadge: View {
    let score: Double
    let status: RecoveryStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.caption)

            Text("\(Int(score))")
                .font(.caption.bold())

            Text(status.rawValue)
                .font(.caption2)
        }
        .foregroundStyle(Color.recoveryColor(for: status))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.recoveryColor(for: status).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Recovery Factor Card
struct RecoveryFactorCard: View {
    let factor: RecoveryFactor

    var body: some View {
        HStack(spacing: 12) {
            // Impact indicator
            Circle()
                .fill(impactColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.name)
                    .font(.subheadline.bold())

                Text(formattedValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Deviation indicator
            HStack(spacing: 4) {
                Image(systemName: deviationIcon)
                    .font(.caption)

                Text(deviationText)
                    .font(.caption)
            }
            .foregroundStyle(impactColor)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var impactColor: Color {
        switch factor.impact {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        }
    }

    private var formattedValue: String {
        switch factor.name {
        case "HRV": return "\(Int(factor.value)) ms"
        case "Resting HR": return "\(Int(factor.value)) bpm"
        case "Sleep": return "\(factor.value.formatted1)h"
        default: return "\(factor.value.formatted1)"
        }
    }

    private var deviationIcon: String {
        if factor.deviation > 0.5 {
            return "arrow.up"
        } else if factor.deviation < -0.5 {
            return "arrow.down"
        } else {
            return "equal"
        }
    }

    private var deviationText: String {
        let absDeviation = abs(factor.deviation)
        if absDeviation < 0.5 {
            return "Normal"
        } else if absDeviation < 1.5 {
            return factor.deviation > 0 ? "Above avg" : "Below avg"
        } else {
            return factor.deviation > 0 ? "High" : "Low"
        }
    }
}

// MARK: - Recovery Timeline
struct RecoveryTimeline: View {
    let analyses: [RecoveryAnalysis]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Recovery")
                .font(.headline)

            HStack(spacing: 4) {
                ForEach(analyses.suffix(7)) { analysis in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.recoveryColor(for: analysis.status))
                            .frame(width: 36, height: 60 * (analysis.score / 100))

                        Text(analysis.date.shortDayOfWeek)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Anomaly Alert
struct AnomalyAlert: View {
    let analysis: RecoveryAnalysis

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Unusual Pattern Detected")
                    .font(.subheadline.bold())

                if let reason = analysis.anomalyReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recovery Readiness Meter
struct ReadinessMeter: View {
    let score: Double

    private var segments: [(Color, Double)] {
        [
            (.red, 0.2),
            (.orange, 0.2),
            (.yellow, 0.2),
            (.mint, 0.2),
            (.green, 0.2)
        ]
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background segments
                    HStack(spacing: 2) {
                        ForEach(segments.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(segments[index].0.opacity(0.3))
                        }
                    }

                    // Indicator
                    let position = geometry.size.width * (score / 100)
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 2)
                        .offset(x: min(max(position - 8, 0), geometry.size.width - 16))
                        .animation(.spring(response: 0.6), value: score)
                }
            }
            .frame(height: 16)

            HStack {
                Text("Low")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Optimal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            RecoveryIndicator(
                score: 78,
                status: .good
            )

            RecoveryBadge(score: 85, status: .optimal)

            RecoveryFactorCard(
                factor: RecoveryFactor(
                    name: "HRV",
                    value: 45,
                    deviation: 0.8,
                    impact: .positive
                )
            )

            ReadinessMeter(score: 72)
                .padding(.horizontal)
        }
        .padding()
    }
}
