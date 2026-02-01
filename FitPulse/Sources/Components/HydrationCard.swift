import SwiftUI

// MARK: - Hydration Quick Card (for Dashboard)
struct HydrationQuickCard: View {
    @StateObject private var viewModel = HydrationViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)

                    Text("Hydration")
                        .font(.headline)
                }

                Spacer()

                NavigationLink(destination: HydrationView()) {
                    Text("Details")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 16) {
                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: min(viewModel.progress, 1))
                        .stroke(
                            viewModel.progress >= 1 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.progressText)
                        .font(.subheadline.bold())

                    Text(viewModel.percentageText)
                        .font(.caption)
                        .foregroundStyle(viewModel.progress >= 1 ? .green : .secondary)
                }

                Spacer()

                // Quick add buttons
                HStack(spacing: 8) {
                    Button(action: { viewModel.logGlass() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "drop.fill")
                                .font(.caption)
                            Text("250")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(action: { viewModel.logBottle() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "waterbottle.fill")
                                .font(.caption)
                            Text("500")
                                .font(.caption2)
                        }
                        .foregroundStyle(.cyan)
                        .padding(8)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Hydration Summary Card (for Nutrition View)
struct HydrationSummaryCard: View {
    @StateObject private var viewModel = HydrationViewModel()

    private var statusColor: Color {
        switch viewModel.hydrationStatus {
        case .dehydrated: return .red
        case .low: return .orange
        case .adequate: return .yellow
        case .good: return .green
        case .excellent: return .blue
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)

                Text("Hydration")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: HydrationView()) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.hydrationStatus.icon)
                        Text(viewModel.hydrationStatus.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(statusColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.progress >= 1 ? Color.green : Color.blue)
                        .frame(width: geometry.size.width * min(viewModel.progress, 1), height: 8)
                        .animation(.spring(response: 0.5), value: viewModel.progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text(viewModel.progressText)
                    .font(.subheadline)

                Spacer()

                Text(viewModel.percentageText)
                    .font(.subheadline.bold())
                    .foregroundStyle(viewModel.progress >= 1 ? .green : .primary)
            }

            // Quick add row
            HStack(spacing: 12) {
                Button(action: { viewModel.logGlass() }) {
                    Label("Glass", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.logBottle() }) {
                    Label("Bottle", systemImage: "waterbottle.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack(spacing: 20) {
        HydrationQuickCard()
        HydrationSummaryCard()
    }
    .padding()
}
