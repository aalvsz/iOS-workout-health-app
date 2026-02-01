import SwiftUI

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let showLabel: Bool
    let label: String?

    init(
        progress: Double,
        color: Color = .red,
        lineWidth: CGFloat = 12,
        showLabel: Bool = false,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.label = label
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)

            // Label
            if showLabel {
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(color)

                    if let label = label {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Triple Activity Rings (Apple Watch Style)
struct TripleActivityRings: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
    let size: CGFloat

    private var ringWidth: CGFloat { size * 0.08 }
    private var ringSpacing: CGFloat { size * 0.02 }

    var body: some View {
        ZStack {
            // Move (outer)
            ActivityRing(
                progress: moveProgress,
                color: .caloriesRing,
                lineWidth: ringWidth
            )
            .frame(width: size, height: size)

            // Exercise (middle)
            ActivityRing(
                progress: exerciseProgress,
                color: .exerciseRing,
                lineWidth: ringWidth
            )
            .frame(width: size - (ringWidth + ringSpacing) * 2, height: size - (ringWidth + ringSpacing) * 2)

            // Stand (inner)
            ActivityRing(
                progress: standProgress,
                color: .standRing,
                lineWidth: ringWidth
            )
            .frame(width: size - (ringWidth + ringSpacing) * 4, height: size - (ringWidth + ringSpacing) * 4)
        }
    }
}

// MARK: - Activity Ring Legend
struct ActivityRingLegend: View {
    let items: [(String, Color, Double, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.1)
                        .frame(width: 10, height: 10)

                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(item.3)
                        .font(.caption.bold())

                    Text("\(Int(item.2 * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Progress Arc
struct ProgressArc: View {
    let progress: Double
    let total: Double
    let color: Color
    let label: String
    let value: String

    private var normalizedProgress: Double {
        guard total > 0 else { return 0 }
        return min(progress / total, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Progress
                Circle()
                    .trim(from: 0, to: normalizedProgress * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .animation(.spring(response: 0.6), value: normalizedProgress)

                // Value
                VStack(spacing: 0) {
                    Text(value)
                        .font(.system(.title2, design: .rounded).bold())

                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Semi Circle Progress
struct SemiCircleProgress: View {
    let progress: Double
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Background
                SemiCircle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(height: 50)

                // Progress
                SemiCircle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(height: 50)
                    .animation(.spring(response: 0.6), value: progress)
            }

            Text(value)
                .font(.headline.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SemiCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        ActivityRing(
            progress: 0.75,
            color: .red,
            lineWidth: 20,
            showLabel: true,
            label: "Move"
        )
        .frame(width: 120, height: 120)

        TripleActivityRings(
            moveProgress: 0.85,
            exerciseProgress: 0.65,
            standProgress: 0.92,
            size: 150
        )

        ProgressArc(
            progress: 1850,
            total: 2200,
            color: .orange,
            label: "Calories",
            value: "1,850"
        )
        .frame(width: 100, height: 100)

        SemiCircleProgress(
            progress: 0.7,
            title: "Steps",
            value: "7,000",
            color: .green
        )
        .frame(width: 100)
    }
    .padding()
}
