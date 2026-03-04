import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                ProfileSetupPage(viewModel: viewModel)
                    .tag(1)

                GoalsPage(viewModel: viewModel)
                    .tag(2)

                NutritionSetupPage(viewModel: viewModel)
                    .tag(3)

                HealthKitPage(viewModel: viewModel)
                    .tag(4)

                CompletionPage(viewModel: viewModel, onComplete: {
                    viewModel.saveProfile()
                    onComplete()
                })
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 20)

            // Navigation Buttons
            HStack {
                if currentPage > 0 {
                    Button(String(localized: "Back")) {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentPage < 5 {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text(String(localized: "Continue"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Onboarding ViewModel
class OnboardingViewModel: ObservableObject {
    @Published var name = ""
    @Published var sex: UserProfile.Sex = .male
    @Published var age = 30
    @Published var weightKg = 70.0
    @Published var heightCm = 170.0
    @Published var fitnessGoal: UserProfile.FitnessGoal = .maintain
    @Published var activityLevel: UserProfile.ActivityLevel = .moderatelyActive
    @Published var deficitPercentage = 0.15
    @Published var proteinPerKg = 1.8
    @Published var healthKitAuthorized = false

    @MainActor private var healthService: HealthKitService { HealthKitService.shared }
    private let persistence = PersistenceController.shared

    var estimatedBMR: Double {
        let s = sex == .male ? 5.0 : -161.0
        return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + s
    }

    var estimatedTDEE: Double {
        estimatedBMR * activityLevel.multiplier
    }

    var targetCalories: Double {
        estimatedTDEE * (1 - deficitPercentage)
    }

    func requestHealthKit() async {
        do {
            try await healthService.requestAuthorization()
            await MainActor.run {
                healthKitAuthorized = true
            }

            // Try to fetch latest weight
            if let weight = try await healthService.fetchLatestWeight() {
                await MainActor.run {
                    self.weightKg = weight
                }
            }
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    func saveProfile() {
        let profile = UserProfile(
            name: name,
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: sex,
            activityLevel: activityLevel,
            fitnessGoal: fitnessGoal,
            deficitPercentage: deficitPercentage,
            proteinPerKg: proteinPerKg,
            fatPerKg: 0.8,
            hasCompletedOnboarding: true
        )
        persistence.saveProfile(profile)
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text(String(localized: "Welcome to FitPulse"))
                .font(.largeTitle.bold())

            Text(String(localized: "Your intelligent fitness companion that adapts to your body's signals"))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(icon: "heart.fill", title: String(localized: "Recovery Tracking"), description: String(localized: "Know when to push and when to rest"))
                FeatureRow(icon: "fork.knife", title: String(localized: "Smart Nutrition"), description: String(localized: "Personalized meal plans based on your activity"))
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: String(localized: "Insights"), description: String(localized: "Understand your body's patterns"))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Profile Setup Page
struct ProfileSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(String(localized: "About You"))
                .font(.largeTitle.bold())

            Text(String(localized: "Let's personalize your experience"))
                .foregroundStyle(.secondary)

            VStack(spacing: 20) {
                TextField(String(localized: "Your name"), text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                Picker(String(localized: "Sex"), selection: $viewModel.sex) {
                    Text(UserProfile.Sex.male.displayName).tag(UserProfile.Sex.male)
                    Text(UserProfile.Sex.female.displayName).tag(UserProfile.Sex.female)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text(String(localized: "Age: \(viewModel.age)"))
                        .font(.headline)
                    Slider(value: Binding(
                        get: { Double(viewModel.age) },
                        set: { viewModel.age = Int($0) }
                    ), in: 13...100, step: 1)
                }

                VStack(alignment: .leading) {
                    Text(String(localized: "Weight: \(viewModel.weightKg, specifier: "%.1f") kg"))
                        .font(.headline)
                    Slider(value: $viewModel.weightKg, in: 30...200, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text(String(localized: "Height: \(Int(viewModel.heightCm)) cm"))
                        .font(.headline)
                    Slider(value: $viewModel.heightCm, in: 100...220, step: 1)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Goals Page
struct GoalsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(String(localized: "Your Goal"))
                .font(.largeTitle.bold())

            Text(String(localized: "What do you want to achieve?"))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: viewModel.fitnessGoal == goal,
                        onSelect: { viewModel.fitnessGoal = goal }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(alignment: .leading) {
                Text(String(localized: "Activity Level"))
                    .font(.headline)

                Picker(String(localized: "Activity Level"), selection: $viewModel.activityLevel) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct GoalOptionCard: View {
    let goal: UserProfile.FitnessGoal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 40)

                Text(goal.displayName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Nutrition Setup Page
struct NutritionSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(String(localized: "Nutrition Setup"))
                .font(.largeTitle.bold())

            Text(String(localized: "Fine-tune your targets"))
                .foregroundStyle(.secondary)

            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Caloric Deficit"))
                            .font(.headline)
                        Spacer()
                        Text(String(localized: "\(Int(viewModel.deficitPercentage * 100))%"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.deficitPercentage, in: 0...0.30, step: 0.05)

                    Text(deficitDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Protein"))
                            .font(.headline)
                        Spacer()
                        Text(String(localized: "\(viewModel.proteinPerKg, specifier: "%.1f") g/kg"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.proteinPerKg, in: 1.2...2.5, step: 0.1)

                    Text(String(localized: "Recommended: \(viewModel.fitnessGoal.proteinRecommendation.lowerBound, specifier: "%.1f")-\(viewModel.fitnessGoal.proteinRecommendation.upperBound, specifier: "%.1f") g/kg for your goal"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Preview
            VStack(spacing: 8) {
                Text(String(localized: "Your Daily Targets"))
                    .font(.headline)

                HStack(spacing: 24) {
                    VStack {
                        Text("\(Int(viewModel.targetCalories))")
                            .font(.title.bold())
                        Text(String(localized: "Calories"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text(String(localized: "\(Int(viewModel.weightKg * viewModel.proteinPerKg))g"))
                            .font(.title.bold())
                            .foregroundStyle(.blue)
                        Text(String(localized: "Protein"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 40)
    }

    private var deficitDescription: String {
        switch viewModel.deficitPercentage {
        case 0: return String(localized: "Maintenance - no weight change")
        case 0.01..<0.15: return String(localized: "Mild deficit - slow, sustainable loss")
        case 0.15..<0.25: return String(localized: "Moderate deficit - steady progress")
        default: return String(localized: "Aggressive - faster results but harder to maintain")
        }
    }
}

// MARK: - HealthKit Page
struct HealthKitPage: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            Text(String(localized: "Connect Apple Health"))
                .font(.largeTitle.bold())

            Text(String(localized: "FitPulse works best when connected to Apple Health for automatic tracking of your workouts, heart rate, sleep, and more."))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            if viewModel.healthKitAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(String(localized: "Connected!"))
                        .font(.headline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button(action: {
                    Task {
                        await viewModel.requestHealthKit()
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(String(localized: "Connect Health"))
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }

            Text(String(localized: "You can skip this step and connect later in Settings"))
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }
}

// MARK: - Completion Page
struct CompletionPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text(String(localized: "You're All Set!"))
                .font(.largeTitle.bold())

            Text(String(localized: "Welcome aboard, \(viewModel.name.isEmpty ? String(localized: "friend") : viewModel.name)!"))
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 16) {
                SummaryRow(label: String(localized: "Daily Calories"), value: String(localized: "\(Int(viewModel.targetCalories)) kcal"))
                SummaryRow(label: String(localized: "Protein Target"), value: String(localized: "\(Int(viewModel.weightKg * viewModel.proteinPerKg))g"))
                SummaryRow(label: String(localized: "Goal"), value: viewModel.fitnessGoal.displayName)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onComplete) {
                Text(String(localized: "Let's Go!"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
