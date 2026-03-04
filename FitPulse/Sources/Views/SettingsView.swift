import SwiftUI
import Charts

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                ProfileSection(viewModel: viewModel)
                GoalsSection(viewModel: viewModel)
                NutritionSection(viewModel: viewModel)
                TargetsSection(viewModel: viewModel)
                HealthSection(viewModel: viewModel)
                AppearanceSection(viewModel: viewModel)
                DataSection(viewModel: viewModel, showingDeleteConfirmation: $showingDeleteConfirmation)
                AboutSection()
            }
            .navigationTitle(String(localized: "Settings"))
            .sheet(isPresented: $viewModel.showingWeightInput) {
                WeightInputSheet(
                    currentWeight: viewModel.profile.weightKg,
                    onSave: { weight in
                        Task {
                            await viewModel.updateWeight(weight)
                        }
                    }
                )
            }
            .alert(String(localized: "Clear All Data?"), isPresented: $showingDeleteConfirmation) {
                Button(String(localized: "Cancel"), role: .cancel) {}
                Button(String(localized: "Clear"), role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text(String(localized: "This will delete all your saved meals, weight history, and preferences. This cannot be undone."))
            }
        }
    }
}

// MARK: - Profile Section
struct ProfileSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Profile")) {
            HStack {
                Text(String(localized: "Name"))
                Spacer()
                TextField(String(localized: "Your name"), text: $viewModel.profile.name)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: viewModel.profile.name) { _, _ in
                        viewModel.saveProfile()
                    }
            }

            Picker(String(localized: "Sex"), selection: $viewModel.profile.sex) {
                ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                    Text(sex.displayName).tag(sex)
                }
            }
            .onChange(of: viewModel.profile.sex) { _, _ in
                viewModel.saveProfile()
            }

            Stepper(String(localized: "Age: \(viewModel.profile.age)"), value: $viewModel.profile.age, in: 13...120)
                .onChange(of: viewModel.profile.age) { _, _ in
                    viewModel.saveProfile()
                }

            HStack {
                Text(String(localized: "Height"))
                Spacer()
                TextField(String(localized: "cm"), value: $viewModel.profile.heightCm, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: viewModel.profile.heightCm) { _, _ in
                        viewModel.saveProfile()
                    }
                Text(String(localized: "cm"))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(String(localized: "Weight"))
                Spacer()
                TextField(String(localized: "kg"), value: $viewModel.profile.weightKg, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: viewModel.profile.weightKg) { _, _ in
                        viewModel.saveProfile()
                    }
                Text(String(localized: "kg"))
                    .foregroundStyle(.secondary)
            }

            Button(String(localized: "Log New Weight")) {
                viewModel.showingWeightInput = true
            }
        }
    }
}

// MARK: - Goals Section
struct GoalsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Fitness Goals")) {
            Picker(String(localized: "Goal"), selection: $viewModel.profile.fitnessGoal) {
                ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                    Label(goal.displayName, systemImage: goal.icon).tag(goal)
                }
            }
            .onChange(of: viewModel.profile.fitnessGoal) { _, _ in
                viewModel.updateGoalSettings()
            }

            Picker(String(localized: "Activity Level"), selection: $viewModel.profile.activityLevel) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .onChange(of: viewModel.profile.activityLevel) { _, _ in
                viewModel.saveProfile()
            }

            Stepper(String(localized: "Weekly Workouts: \(viewModel.profile.weeklyWorkoutGoal)"), value: $viewModel.profile.weeklyWorkoutGoal, in: 1...7)
                .onChange(of: viewModel.profile.weeklyWorkoutGoal) { _, _ in
                    viewModel.saveProfile()
                }

            Stepper(String(localized: "Daily Steps: \(viewModel.profile.dailyStepsGoal.formattedSteps)"), value: $viewModel.profile.dailyStepsGoal, in: 1000...30000, step: 1000)
                .onChange(of: viewModel.profile.dailyStepsGoal) { _, _ in
                    viewModel.saveProfile()
                }

            VStack(alignment: .leading) {
                HStack {
                    Text(String(localized: "Sleep Goal"))
                    Spacer()
                    Text(String(localized: "\(viewModel.profile.sleepGoalHours, specifier: "%.1f") hours"))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.profile.sleepGoalHours, in: 5...10, step: 0.5)
                    .onChange(of: viewModel.profile.sleepGoalHours) { _, _ in
                        viewModel.saveProfile()
                    }
            }
        }
    }
}

// MARK: - Nutrition Section
struct NutritionSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Nutrition")) {
            VStack(alignment: .leading) {
                HStack {
                    Text(String(localized: "Deficit"))
                    Spacer()
                    Text(viewModel.deficitDescription)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.profile.deficitPercentage, in: -0.15...0.30, step: 0.05)
                    .onChange(of: viewModel.profile.deficitPercentage) { _, _ in
                        viewModel.saveProfile()
                    }
            }

            if let warning = viewModel.deficitWarning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text(String(localized: "Protein"))
                    Spacer()
                    Text(String(localized: "\(viewModel.profile.proteinPerKg, specifier: "%.1f") g/kg"))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.profile.proteinPerKg, in: 1.2...2.5, step: 0.1)
                    .onChange(of: viewModel.profile.proteinPerKg) { _, _ in
                        viewModel.saveProfile()
                    }
            }

            VStack(alignment: .leading) {
                HStack {
                    Text(String(localized: "Fat"))
                    Spacer()
                    Text(String(localized: "\(viewModel.profile.fatPerKg, specifier: "%.1f") g/kg"))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.profile.fatPerKg, in: 0.5...1.2, step: 0.1)
                    .onChange(of: viewModel.profile.fatPerKg) { _, _ in
                        viewModel.saveProfile()
                    }
            }
        }
    }
}

// MARK: - Targets Section
struct TargetsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Your Targets")) {
            LabeledContent(String(localized: "BMR"), value: String(localized: "\(Int(viewModel.estimatedBMR)) kcal"))
            LabeledContent(String(localized: "TDEE"), value: String(localized: "\(Int(viewModel.estimatedTDEE)) kcal"))
            LabeledContent(String(localized: "Target Calories"), value: String(localized: "\(Int(viewModel.targetCalories)) kcal"))
            Divider()
            LabeledContent(String(localized: "Protein"), value: String(localized: "\(Int(viewModel.proteinTarget))g"))
            LabeledContent(String(localized: "Carbs"), value: String(localized: "\(Int(viewModel.carbTarget))g"))
            LabeledContent(String(localized: "Fat"), value: String(localized: "\(Int(viewModel.fatTarget))g"))

            if viewModel.profile.fitnessGoal == .loseWeight {
                Divider()
                LabeledContent(String(localized: "Expected Weekly Loss"), value: String(localized: "\(viewModel.expectedWeeklyLoss, specifier: "%.2f") kg"))
            }
        }
    }
}

// MARK: - Health Section
struct HealthSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Health Integration")) {
            Button(action: {
                Task {
                    await viewModel.requestHealthKitPermissions()
                }
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text(String(localized: "Connect Apple Health"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Appearance Section
struct AppearanceSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(String(localized: "Appearance")) {
            Toggle(String(localized: "Dark Mode"), isOn: $viewModel.profile.prefersDarkMode)
                .onChange(of: viewModel.profile.prefersDarkMode) { _, _ in
                    viewModel.saveProfile()
                }
            Toggle(String(localized: "Notifications"), isOn: $viewModel.profile.notificationsEnabled)
                .onChange(of: viewModel.profile.notificationsEnabled) { _, _ in
                    viewModel.saveProfile()
                }
        }
    }
}

// MARK: - Data Section
struct DataSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var showingDeleteConfirmation: Bool

    var body: some View {
        Section(String(localized: "Data")) {
            NavigationLink(destination: WeightHistoryView(entries: viewModel.weightHistory)) {
                Label(String(localized: "Weight History"), systemImage: "chart.line.uptrend.xyaxis")
            }

            Button(role: .destructive, action: {
                showingDeleteConfirmation = true
            }) {
                Label(String(localized: "Clear All Data"), systemImage: "trash")
            }
        }
    }
}

// MARK: - About Section
struct AboutSection: View {
    var body: some View {
        Section(String(localized: "About")) {
            LabeledContent(String(localized: "Version"), value: "1.0.0")
            LabeledContent(String(localized: "Build"), value: "1")
        }
    }
}

// MARK: - Weight History View
struct WeightHistoryView: View {
    let entries: [WeightEntry]

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Weight Data"),
                    systemImage: "scalemass",
                    description: Text(String(localized: "Log your weight to track your progress"))
                )
            } else {
                if entries.count >= 2 {
                    Section {
                        WeightTrendChart(entries: entries)
                            .frame(height: 200)
                            .listRowInsets(EdgeInsets())
                    }
                }

                Section(String(localized: "History")) {
                    ForEach(entries.reversed()) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.date.mediumDate)
                                    .font(.subheadline)

                                if let note = entry.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(entry.weightKg.formattedWeight)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Weight History"))
    }
}

struct WeightTrendChart: View {
    let entries: [WeightEntry]

    var body: some View {
        Chart(entries) { entry in
            LineMark(
                x: .value(String(localized: "Date"), entry.date),
                y: .value(String(localized: "Weight"), entry.weightKg)
            )
            .foregroundStyle(.blue)

            PointMark(
                x: .value(String(localized: "Date"), entry.date),
                y: .value(String(localized: "Weight"), entry.weightKg)
            )
            .foregroundStyle(.blue)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserProfile())
}
