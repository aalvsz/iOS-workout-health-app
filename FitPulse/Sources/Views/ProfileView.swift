import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profile: UserProfile
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
                            Text(profile.name.isEmpty ? "Your Name" : profile.name)
                                .font(.title2.bold())

                            Text(profile.fitnessGoal.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Body Stats
                Section("Body Stats") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(profile.weightKg, specifier: "%.1f") kg")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(profile.heightCm)) cm")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(profile.age) years")
                            .foregroundStyle(.secondary)
                    }

                    Button("Log Weight") {
                        showingWeightInput = true
                    }
                }

                // Goals
                Section("Fitness Goal") {
                    Picker("Goal", selection: Binding(
                        get: { profile.fitnessGoal },
                        set: { newValue in
                            profile.fitnessGoal = newValue
                            profile.save()
                        }
                    )) {
                        ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }

                    Picker("Activity Level", selection: Binding(
                        get: { profile.activityLevel },
                        set: { newValue in
                            profile.activityLevel = newValue
                            profile.save()
                        }
                    )) {
                        ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }

                // Nutrition Targets
                Section("Nutrition Targets") {
                    LabeledContent("Daily Calories", value: "\(Int(viewModel.targetCalories)) kcal")
                    LabeledContent("Protein", value: "\(Int(viewModel.proteinTarget))g")
                    LabeledContent("Carbs", value: "\(Int(viewModel.carbTarget))g")
                    LabeledContent("Fat", value: "\(Int(viewModel.fatTarget))g")
                }

                // Settings
                Section("Preferences") {
                    Stepper("Weekly Workouts: \(profile.weeklyWorkoutGoal)", value: Binding(
                        get: { profile.weeklyWorkoutGoal },
                        set: { newValue in
                            profile.weeklyWorkoutGoal = newValue
                            profile.save()
                        }
                    ), in: 1...7)

                    NavigationLink("Nutrition Settings") {
                        NutritionSettingsView()
                    }
                }

                // Data
                Section("Data") {
                    Button("Reset Profile", role: .destructive) {
                        viewModel.showingResetConfirmation = true
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingWeightInput) {
                WeightInputSheet(
                    currentWeight: profile.weightKg,
                    onSave: { weight in
                        profile.weightKg = weight
                        profile.save()
                    }
                )
            }
            .alert("Reset Profile?", isPresented: $viewModel.showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetProfile()
                }
            } message: {
                Text("This will reset all your settings to defaults.")
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
            Section("Calorie Deficit") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Deficit")
                        Spacer()
                        Text("\(Int(profile.deficitPercentage * 100))%")
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

                Text("Higher deficit = faster weight loss, but harder to maintain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Macros") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text("\(profile.proteinPerKg, specifier: "%.1f") g/kg")
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
                        Text("Fat")
                        Spacer()
                        Text("\(profile.fatPerKg, specifier: "%.1f") g/kg")
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

                Text("Recommended protein: 1.6-2.2 g/kg for muscle building")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nutrition")
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfile())
}
