import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var healthService: HealthKitService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingWeightInput = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 70, height: 70)

                            Text(profile.name.prefix(1).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name.isEmpty ? String(localized: "Your Name") : profile.name)
                                .font(.title2.bold())

                            Text(profile.fitnessGoal.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Account
                AuthSectionView()

                // Body Stats
                Section(String(localized: "Body Stats")) {
                    HStack {
                        Text(String(localized: "Weight"))
                        Spacer()
                        Text(String(localized: "\(profile.weightKg, specifier: "%.1f") kg"))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "Height"))
                        Spacer()
                        Text(String(localized: "\(Int(profile.heightCm)) cm"))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "Age"))
                        Spacer()
                        Text(String(localized: "\(profile.age) years"))
                            .foregroundStyle(.secondary)
                    }

                    Button(String(localized: "Log Weight")) {
                        showingWeightInput = true
                    }

                    NavigationLink(destination: WeightTrendsView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.blue)
                            Text(String(localized: "Weight Trends"))
                        }
                    }
                }

                // Goals
                Section(String(localized: "Fitness Goal")) {
                    Picker(String(localized: "Goal"), selection: Binding(
                        get: { profile.fitnessGoal },
                        set: { newValue in
                            profile.fitnessGoal = newValue
                            profile.save()
                        }
                    )) {
                        ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }

                    Picker(String(localized: "Activity Level"), selection: Binding(
                        get: { profile.activityLevel },
                        set: { newValue in
                            profile.activityLevel = newValue
                            profile.save()
                        }
                    )) {
                        ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                // Nutrition Targets
                Section(String(localized: "Nutrition Targets")) {
                    LabeledContent(String(localized: "Daily Calories"), value: String(localized: "\(Int(viewModel.targetCalories)) kcal"))
                    LabeledContent(String(localized: "Protein"), value: String(localized: "\(Int(viewModel.proteinTarget))g"))
                    LabeledContent(String(localized: "Carbs"), value: String(localized: "\(Int(viewModel.carbTarget))g"))
                    LabeledContent(String(localized: "Fat"), value: String(localized: "\(Int(viewModel.fatTarget))g"))
                }

                // Settings
                Section(String(localized: "Preferences")) {
                    Stepper(String(localized: "Weekly Workouts: \(profile.weeklyWorkoutGoal)"), value: Binding(
                        get: { profile.weeklyWorkoutGoal },
                        set: { newValue in
                            profile.weeklyWorkoutGoal = newValue
                            profile.save()
                        }
                    ), in: 1...7)

                    NavigationLink(String(localized: "Nutrition Settings")) {
                        NutritionSettingsView()
                    }
                }

                // Health Data Sync
                Section(String(localized: "Health Data")) {
                    if let lastSync = healthService.lastSyncDate {
                        HStack {
                            Text(String(localized: "Last Synced"))
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Task { await healthService.syncAllHealthData() }
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text(healthService.isSyncing ? String(localized: "Syncing...") : String(localized: "Sync with Apple Health"))
                        }
                    }
                    .disabled(healthService.isSyncing)
                }

                // Data
                Section(String(localized: "Data")) {
                    Button(String(localized: "Reset Profile"), role: .destructive) {
                        viewModel.showingResetConfirmation = true
                    }
                }
            }
            .navigationTitle(String(localized: "Profile"))
            .sheet(isPresented: $showingWeightInput) {
                WeightInputSheet(
                    currentWeight: profile.weightKg,
                    onSave: { weight in
                        profile.weightKg = weight
                        profile.save()
                    }
                )
            }
            .alert(String(localized: "Reset Profile?"), isPresented: $viewModel.showingResetConfirmation) {
                Button(String(localized: "Cancel"), role: .cancel) {}
                Button(String(localized: "Reset"), role: .destructive) {
                    viewModel.resetProfile()
                }
            } message: {
                Text(String(localized: "This will reset all your settings to defaults."))
            }
            .onAppear {
                viewModel.updateTargets(for: profile)
            }
            .onChange(of: profile.fitnessGoal) { _, _ in
                viewModel.updateTargets(for: profile)
            }
            .onChange(of: profile.activityLevel) { _, _ in
                viewModel.updateTargets(for: profile)
            }
        }
    }
}

// MARK: - Profile ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var targetCalories: Double = 2000
    @Published var proteinTarget: Double = 150
    @Published var carbTarget: Double = 200
    @Published var fatTarget: Double = 70
    @Published var showingResetConfirmation = false

    private let nutritionCalculator = NutritionCalculator.shared
    private let persistence = PersistenceController.shared

    func updateTargets(for profile: UserProfile) {
        let targets = nutritionCalculator.calculateTargets(profile: profile)
        targetCalories = targets.targetCalories
        proteinTarget = targets.proteinGrams
        carbTarget = targets.carbGrams
        fatTarget = targets.fatGrams
    }

    func resetProfile() {
        let newProfile = UserProfile()
        persistence.saveProfile(newProfile)
    }
}

// MARK: - Nutrition Settings View
struct NutritionSettingsView: View {
    @EnvironmentObject var profile: UserProfile

    var body: some View {
        Form {
            Section(String(localized: "Calorie Deficit")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Deficit"))
                        Spacer()
                        Text(String(localized: "\(Int(profile.deficitPercentage * 100))%"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { profile.deficitPercentage },
                        set: { newValue in
                            profile.deficitPercentage = newValue
                            profile.save()
                        }
                    ), in: 0...0.30, step: 0.05)
                }

                Text(String(localized: "Higher deficit = faster weight loss, but harder to maintain"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Macros")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Protein"))
                        Spacer()
                        Text(String(localized: "\(profile.proteinPerKg, specifier: "%.1f") g/kg"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { profile.proteinPerKg },
                        set: { newValue in
                            profile.proteinPerKg = newValue
                            profile.save()
                        }
                    ), in: 1.2...2.5, step: 0.1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Fat"))
                        Spacer()
                        Text(String(localized: "\(profile.fatPerKg, specifier: "%.1f") g/kg"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { profile.fatPerKg },
                        set: { newValue in
                            profile.fatPerKg = newValue
                            profile.save()
                        }
                    ), in: 0.5...1.2, step: 0.1)
                }

                Text(String(localized: "Recommended protein: 1.6-2.2 g/kg for muscle building"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "Nutrition"))
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfile())
        .environmentObject(HealthKitService.shared)
}
