import SwiftUI

struct HydrationView: View {
    @StateObject private var viewModel = HydrationViewModel()
    @State private var showingCustomLog = false
    @State private var customAmount = ""
    @State private var selectedSource: HydrationSource = .water

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Main Progress Card
                    HydrationProgressCard(
                        intake: viewModel.todayIntake,
                        goal: viewModel.dailyGoal.totalMl,
                        status: viewModel.hydrationStatus
                    )

                    // Quick Add Buttons
                    QuickAddCard(
                        onGlass: { viewModel.logGlass(source: selectedSource) },
                        onBottle: { viewModel.logBottle(source: selectedSource) },
                        onCustom: { showingCustomLog = true },
                        selectedSource: $selectedSource
                    )

                    // Today's Log
                    if !viewModel.entries.isEmpty {
                        TodayLogCard(
                            entries: viewModel.entries,
                            onDelete: { entry in viewModel.deleteEntry(entry) }
                        )
                    }

                    // Weekly Progress
                    if !viewModel.weeklyProgress.isEmpty {
                        WeeklyHydrationCard(progress: viewModel.weeklyProgress)
                    }

                    // Tips Card
                    HydrationTipCard(
                        status: viewModel.hydrationStatus,
                        tip: viewModel.currentTip
                    )
                }
                .padding()
            }
            .navigationTitle("Hydration")
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingCustomLog) {
                CustomHydrationSheet(
                    selectedSource: selectedSource,
                    onLog: { amount, source in
                        viewModel.logCustom(amountMl: amount, source: source)
                    }
                )
            }
        }
    }
}

// MARK: - Hydration Progress Card
struct HydrationProgressCard: View {
    let intake: Int
    let goal: Int
    let status: HydrationStatus

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(intake) / Double(goal)
    }

    private var intakeLiters: Double {
        Double(intake) / 1000.0
    }

    private var goalLiters: Double {
        Double(goal) / 1000.0
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Hydration")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                    Text(status.rawValue)
                }
                .font(.caption)
                .foregroundStyle(statusColor)
            }

            HStack(spacing: 24) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: min(progress, 1))
                        .stroke(
                            progress > 1 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: progress)

                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text(String(format: "%.1fL", intakeLiters))
                            .font(.title.bold())

                        Text(String(format: "/ %.1fL", goalLiters))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(Int(min(progress, 1) * 100))%")
                            .font(.title2.bold())
                            .foregroundStyle(progress >= 1 ? .green : .primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        let remaining = max(0, goal - intake)
                        Text(remaining >= 1000 ? String(format: "%.1fL", Double(remaining) / 1000) : "\(remaining)ml")
                            .font(.title3.bold())
                    }
                }
            }

            Text(status.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var statusColor: Color {
        switch status {
        case .dehydrated: return .red
        case .low: return .orange
        case .adequate: return .yellow
        case .good: return .green
        case .excellent: return .blue
        }
    }
}

// MARK: - Quick Add Card
struct QuickAddCard: View {
    let onGlass: () -> Void
    let onBottle: () -> Void
    let onCustom: () -> Void
    @Binding var selectedSource: HydrationSource

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Add")
                    .font(.headline)

                Spacer()

                Picker("Source", selection: $selectedSource) {
                    ForEach(HydrationSource.allCases, id: \.self) { source in
                        HStack {
                            Image(systemName: source.icon)
                            Text(source.rawValue)
                        }
                        .tag(source)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack(spacing: 12) {
                QuickAddButton(
                    icon: "drop.fill",
                    amount: "250ml",
                    label: "Glass",
                    color: .blue,
                    action: onGlass
                )

                QuickAddButton(
                    icon: "waterbottle.fill",
                    amount: "500ml",
                    label: "Bottle",
                    color: .cyan,
                    action: onBottle
                )

                QuickAddButton(
                    icon: "plus.circle.fill",
                    amount: "Custom",
                    label: "Amount",
                    color: .purple,
                    action: onCustom
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct QuickAddButton: View {
    let icon: String
    let amount: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(amount)
                    .font(.subheadline.bold())

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today's Log Card
struct TodayLogCard: View {
    let entries: [HydrationEntry]
    let onDelete: (HydrationEntry) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Log")
                    .font(.headline)

                Spacer()

                Text("\(entries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(entries.reversed()) { entry in
                HStack(spacing: 12) {
                    Image(systemName: entry.source.icon)
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.source.rawValue)
                            .font(.subheadline)

                        Text(formatTime(entry.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(entry.amountMl)ml")
                        .font(.subheadline.bold())

                    Button(action: { onDelete(entry) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if entry.id != entries.reversed().last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Weekly Hydration Card
struct WeeklyHydrationCard: View {
    let progress: [(date: Date, intake: Int, goal: Int)]

    private var maxIntake: Int {
        progress.map { $0.intake }.max() ?? 1
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                let avgProgress = progress.reduce(0.0) { sum, day in
                    sum + (day.goal > 0 ? Double(day.intake) / Double(day.goal) : 0)
                } / Double(max(1, progress.count))

                Text("\(Int(avgProgress * 100))% avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(progress, id: \.date) { day in
                    VStack(spacing: 4) {
                        let height = maxIntake > 0 ? CGFloat(day.intake) / CGFloat(maxIntake) * 80 : 0
                        let dayProgress = day.goal > 0 ? Double(day.intake) / Double(day.goal) : 0

                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayProgress >= 1 ? Color.green : Color.blue)
                            .frame(height: max(4, height))

                        Text(dayOfWeek(day.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Hydration Tip Card
struct HydrationTipCard: View {
    let status: HydrationStatus
    let tip: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text("Tip")
                    .font(.headline)

                Spacer()
            }

            Text(tip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Custom Hydration Sheet
struct CustomHydrationSheet: View {
    let selectedSource: HydrationSource
    let onLog: (Int, HydrationSource) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double = 250
    @State private var source: HydrationSource

    init(selectedSource: HydrationSource, onLog: @escaping (Int, HydrationSource) -> Void) {
        self.selectedSource = selectedSource
        self.onLog = onLog
        _source = State(initialValue: selectedSource)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log Hydration")
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    Text("\(Int(amount))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))

                    Text("milliliters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $amount, in: 50...1000, step: 25)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    ForEach([100, 250, 500, 750], id: \.self) { preset in
                        Button("\(preset)ml") {
                            amount = Double(preset)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Picker("Source", selection: $source) {
                    ForEach(HydrationSource.allCases, id: \.self) { src in
                        HStack {
                            Image(systemName: src.icon)
                            Text(src.rawValue)
                        }
                        .tag(src)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    onLog(Int(amount), source)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Log \(Int(amount))ml")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HydrationView()
}
