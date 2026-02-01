import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: Double?
    let size: CardSize

    enum CardSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 28
            case .large: return 32
            }
        }

        var titleFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .headline
            }
        }

        var valueFont: Font {
            switch self {
            case .small: return .title3.bold()
            case .medium: return .title2.bold()
            case .large: return .title.bold()
            }
        }
    }

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = .blue,
        trend: Double? = nil,
        size: CardSize = .medium
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
        self.size = size
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
                    .foregroundStyle(iconColor)

                Spacer()

                if let trend = trend {
                    TrendBadge(value: trend)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(size.valueFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(size.titleFont)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Trend Badge
struct TrendBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2.bold())

            Text("\(abs(value), specifier: "%.1f")%")
                .font(.caption2.bold())
        }
        .foregroundStyle(value >= 0 ? .green : .red)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (value >= 0 ? Color.green : Color.red).opacity(0.15)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Compact Metric Row
struct CompactMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Large Stat Card
struct LargeStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: (() -> Void)?

    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        gradient: LinearGradient = .primaryGradient,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)

                    Spacer()

                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Steps",
                    value: "8,432",
                    subtitle: "Goal: 10,000",
                    icon: "figure.walk",
                    iconColor: .green,
                    trend: 12.5
                )

                MetricCard(
                    title: "Calories",
                    value: "2,150",
                    subtitle: "Active: 450",
                    icon: "flame.fill",
                    iconColor: .orange,
                    trend: -3.2
                )
            }

            LargeStatCard(
                title: "Recovery Score",
                value: "85",
                subtitle: "You're ready for high intensity",
                icon: "heart.fill",
                gradient: .recoveryGradient
            ) {
                print("Tapped")
            }
        }
        .padding()
    }
}
