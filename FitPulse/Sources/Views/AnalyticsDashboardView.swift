import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    timeRangePicker

                    // PREMIUM SECTION
                    ZStack {
                        VStack(spacing: 20) {
                            summaryCards
                            workoutVolumeSection
                            nutritionAdherenceSection
                            weightProgressSection
                            recoverySection
                        }
                        .blur(radius: subscriptionManager.isPremium ? 0 : 6)
                        .allowsHitTesting(subscriptionManager.isPremium)

                        if !subscriptionManager.isPremium {
                            paywallOverlay
                        }
                    }

                    // FREE SECTION — Engagement
                    engagementSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Analytics"))
            .refreshable {
                await viewModel.loadData()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if subscriptionManager.isPremium {
                        Button {
                            showingExport = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(feature: .analytics)
            }
            .sheet(isPresented: $showingExport) {
                ExportView(viewModel: viewModel)
            }
            .onChange(of: viewModel.selectedTimeRange) { _ in
                viewModel.onTimeRangeChanged()
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker(String(localized: "Time Range"), selection: $viewModel.selectedTimeRange) {
            ForEach(AnalyticsDashboardViewModel.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)  // "30D", "60D", "90D" are technical labels, not localized
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: String(localized: "Workout Time"),
                value: "\(viewModel.totalWorkoutMinutes)",
                unit: String(localized: "min"),
                icon: "flame.fill",
                color: .orange
            )
            summaryCard(
                title: String(localized: "Nutrition"),
                value: "\(viewModel.averageNutritionAdherence)",
                unit: String(localized: "% avg"),
                icon: "fork.knife",
                color: .green
            )
            summaryCard(
                title: String(localized: "Recovery"),
                value: "\(viewModel.averageRecoveryScore)",
                unit: String(localized: "/ 100"),
                icon: "heart.fill",
                color: .red
            )
            summaryCard(
                title: String(localized: "Weight Entries"),
                value: "\(viewModel.weightData.count)",
                unit: String(localized: "logged"),
                icon: "scalemass.fill",
                color: .blue
            )
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Workout Volume

    private var workoutVolumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Workout Volume"))
                .font(.headline)

            if viewModel.workoutVolumeData.isEmpty {
                emptyChartPlaceholder(String(localized: "No workout data available"))
            } else {
                BarChartView(
                    data: viewModel.workoutVolumeData,
                    color: .orange,
                    height: 180
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Nutrition Adherence

    private var nutritionAdherenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Nutrition Adherence"))
                    .font(.headline)
                Spacer()
                Text(String(localized: "\(viewModel.averageNutritionAdherence)% avg"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.nutritionAdherenceData.isEmpty {
                emptyChartPlaceholder(String(localized: "No nutrition data available"))
            } else {
                TrendChart(
                    data: viewModel.nutritionAdherenceData,
                    color: .green,
                    showAxis: true,
                    height: 180
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Weight Progress

    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Weight Progress"))
                    .font(.headline)
                Spacer()
                if let latest = viewModel.weightData.last {
                    Text(String(localized: "\(String(format: "%.1f", latest.value)) kg"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.weightData.isEmpty {
                emptyChartPlaceholder(String(localized: "No weight data available"))
            } else {
                ComparisonChart(
                    primaryData: viewModel.weightData,
                    secondaryData: viewModel.weightMovingAverage,
                    primaryLabel: String(localized: "Weight"),
                    secondaryLabel: String(localized: "7-Day Avg"),
                    primaryColor: .blue,
                    secondaryColor: .blue.opacity(0.5),
                    height: 180
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Recovery

    private var recoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Recovery Trend"))
                    .font(.headline)
                Spacer()
                Text(String(localized: "Avg: \(viewModel.averageRecoveryScore)/100"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.recoveryData.isEmpty {
                emptyChartPlaceholder(String(localized: "No recovery data available"))
            } else {
                TrendChart(
                    data: viewModel.recoveryData,
                    color: .red,
                    showAxis: true,
                    height: 180
                )
            }

            // LLM Recovery Insight
            recoveryInsightCard
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var recoveryInsightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                Text(String(localized: "AI Recovery Insight"))
                    .font(.subheadline.bold())
                Spacer()

                if viewModel.recoveryInsight == nil && !viewModel.isLoadingInsight {
                    Button(String(localized: "Generate")) {
                        Task {
                            await viewModel.generateRecoveryInsight()
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                }
            }

            if viewModel.isLoadingInsight {
                HStack {
                    ProgressView()
                    Text(String(localized: "Analyzing your recovery data..."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let insight = viewModel.recoveryInsight {
                Text(insight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Paywall Overlay

    private var paywallOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text(String(localized: "Premium Analytics"))
                .font(.title3.bold())

            Text(String(localized: "Unlock detailed charts, trends, and AI-powered recovery insights"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text(String(localized: "Upgrade to Premium"))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.blue)
                .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Engagement (Free)

    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "Progress & Engagement"))
                    .font(.headline)
                Spacer()
                Text(String(localized: "Free"))
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            }

            EngagementView()
                .frame(minHeight: 400)
        }
    }

    // MARK: - Helpers

    private func emptyChartPlaceholder(_ message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }
}

// MARK: - Export View (Share Sheet Wrapper)

struct ExportView: View {
    let viewModel: AnalyticsDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "doc.richtext")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text(String(localized: "Export Progress Report"))
                    .font(.title2.bold())

                Text(String(localized: "Generate a PDF report with your workout, nutrition, weight, and recovery data."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let error = exportError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    generateAndShare()
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isGenerating ? String(localized: "Generating...") : String(localized: "Generate PDF"))
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isGenerating)
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }

    private func generateAndShare() {
        isGenerating = true
        exportError = nil

        Task {
            do {
                let pdfData = try ReportGenerator.shared.generateReport(from: viewModel)
                isGenerating = false

                // Save to temp and share
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("FitPulse_Report.pdf")
                try pdfData.write(to: url)

                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                    dismiss()
                }
            } catch {
                exportError = error.localizedDescription
                isGenerating = false
            }
        }
    }
}

#Preview {
    AnalyticsDashboardView()
        .environmentObject(SubscriptionManager.shared)
}
