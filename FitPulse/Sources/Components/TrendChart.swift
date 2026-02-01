import SwiftUI
import Charts

struct TrendChart: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    let showAxis: Bool
    let showGrid: Bool
    let height: CGFloat

    init(
        data: [ChartDataPoint],
        title: String = "",
        color: Color = .blue,
        showAxis: Bool = true,
        showGrid: Bool = true,
        height: CGFloat = 200
    ) {
        self.data = data
        self.title = title
        self.color = color
        self.showAxis = showAxis
        self.showGrid = showGrid
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(showAxis ? .automatic : .hidden)
            .chartYAxis(showAxis ? .automatic : .hidden)
            .frame(height: height)
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String?

    init(date: Date, value: Double, label: String? = nil) {
        self.date = date
        self.value = value
        self.label = label
    }
}

// MARK: - Bar Chart
struct BarChartView: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    let height: CGFloat

    init(
        data: [ChartDataPoint],
        title: String = "",
        color: Color = .blue,
        height: CGFloat = 200
    ) {
        self.data = data
        self.title = title
        self.color = color
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
            }

            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color.gradient)
                .cornerRadius(4)
            }
            .frame(height: height)
        }
    }
}

// MARK: - Comparison Chart
struct ComparisonChart: View {
    let primaryData: [ChartDataPoint]
    let secondaryData: [ChartDataPoint]
    let primaryLabel: String
    let secondaryLabel: String
    let primaryColor: Color
    let secondaryColor: Color
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Label(primaryLabel, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(primaryColor)

                Label(secondaryLabel, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
            }

            Chart {
                ForEach(primaryData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(primaryLabel, point.value),
                        series: .value("Series", primaryLabel)
                    )
                    .foregroundStyle(primaryColor)
                    .interpolationMethod(.catmullRom)
                }

                ForEach(secondaryData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(secondaryLabel, point.value),
                        series: .value("Series", secondaryLabel)
                    )
                    .foregroundStyle(secondaryColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(dash: [5, 3]))
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - Sparkline (Mini Chart)
struct Sparkline: View {
    let data: [Double]
    let color: Color
    let showDots: Bool

    init(data: [Double], color: Color = .blue, showDots: Bool = false) {
        self.data = data
        self.color = color
        self.showDots = showDots
    }

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue
            let step = geometry.size.width / CGFloat(max(data.count - 1, 1))

            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * step
                    let y = geometry.size.height - (CGFloat((value - minValue) / max(range, 1)) * geometry.size.height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            if showDots {
                ForEach(data.indices, id: \.self) { index in
                    let x = CGFloat(index) * step
                    let y = geometry.size.height - (CGFloat((data[index] - minValue) / max(range, 1)) * geometry.size.height)

                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Weekly Bar Chart
struct WeeklyBarChart: View {
    let data: [(String, Double)]
    let target: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let maxValue = max(data.map(\.1).max() ?? 1, target ?? 0)
                    let height = CGFloat(item.1 / maxValue) * 100

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.gradient)
                            .frame(width: 30, height: max(height, 4))

                        Text(item.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 120)

            if let target = target {
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(height: 1)

                    Text("Goal: \(Int(target))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            let sampleData = (0..<7).map { i in
                ChartDataPoint(
                    date: Date().adding(days: -6 + i),
                    value: Double.random(in: 50...100)
                )
            }

            TrendChart(
                data: sampleData,
                title: "Recovery Score",
                color: .green
            )

            BarChartView(
                data: sampleData,
                title: "Daily Steps",
                color: .orange
            )

            Sparkline(
                data: [65, 72, 68, 75, 80, 78, 85],
                color: .blue,
                showDots: true
            )
            .frame(height: 40)

            WeeklyBarChart(
                data: [("M", 8500), ("T", 10200), ("W", 7800), ("T", 9500), ("F", 11000), ("S", 6500), ("S", 4200)],
                target: 10000,
                color: .green
            )
        }
        .padding()
    }
}
