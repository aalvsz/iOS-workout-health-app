import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profile: UserProfile
    @Published var weightHistory: [WeightEntry] = []
    @Published var showingWeightInput = false
    @Published var showingDeleteConfirmation = false
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?

    // MARK: - Dependencies
    private let persistence = PersistenceController.shared
    private let healthService = HealthKitService.shared
    private let nutritionCalculator = NutritionCalculator.shared

    // MARK: - Computed Properties
    var estimatedBMR: Double {
        nutritionCalculator.calculateBMR(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            sex: profile.sex
        )
    }

    var estimatedTDEE: Double {
        nutritionCalculator.estimateTDEE(bmr: estimatedBMR, activityLevel: profile.activityLevel)
    }

    var targetCalories: Double {
        estimatedTDEE * (1 - profile.deficitPercentage)
    }

    var proteinTarget: Double {
        profile.weightKg * profile.proteinPerKg
    }

    var fatTarget: Double {
        profile.weightKg * profile.fatPerKg
    }

    var carbTarget: Double {
        let proteinCals = proteinTarget * 4
        let fatCals = fatTarget * 9
        return max(0, (targetCalories - proteinCals - fatCals) / 4)
    }

    var expectedWeeklyLoss: Double {
        let dailyDeficit = estimatedTDEE - targetCalories
        return (dailyDeficit * 7) / 7700
    }

    var latestWeight: Double? {
        weightHistory.last?.weightKg
    }

    var weightTrend: Double? {
        guard weightHistory.count >= 2 else { return nil }
        let recent = weightHistory.suffix(7)
        guard recent.count >= 2 else { return nil }
        return recent.last!.weightKg - recent.first!.weightKg
    }

    // MARK: - Initialization
    init() {
        profile = persistence.loadProfile()
        loadWeightHistory()
    }

    // MARK: - Data Loading
    func loadWeightHistory() {
        Task {
            do {
                weightHistory = try await healthService.fetchWeightHistory(days: 90)
            } catch {
                weightHistory = persistence.loadWeightHistory()
            }
        }
    }

    // MARK: - Profile Management
    func saveProfile() {
        isSaving = true
        error = nil

        persistence.saveProfile(profile)

        isSaving = false
        saveSuccess = true

        // Reset success flag after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            saveSuccess = false
        }
    }

    func updateWeight(_ newWeight: Double) async {
        do {
            try await healthService.saveWeight(newWeight)
            profile.weightKg = newWeight
            saveProfile()

            let entry = WeightEntry(weightKg: newWeight)
            persistence.saveWeightEntry(entry)
            weightHistory.append(entry)
        } catch {
            self.error = "Failed to save weight: \(error.localizedDescription)"
        }
    }

    func resetToDefaults() {
        profile = UserProfile()
        saveProfile()
    }

    func clearAllData() {
        persistence.clearAllData()
        profile = UserProfile()
        weightHistory = []
    }

    // MARK: - Goal Calculations
    func updateGoalSettings() {
        // Adjust deficit based on goal
        profile.deficitPercentage = profile.fitnessGoal.defaultDeficit

        // Adjust protein based on goal
        let proteinRange = profile.fitnessGoal.proteinRecommendation
        profile.proteinPerKg = (proteinRange.lowerBound + proteinRange.upperBound) / 2

        saveProfile()
    }

    // MARK: - Validation
    var isProfileValid: Bool {
        profile.weightKg >= 30 && profile.weightKg <= 300 &&
        profile.heightCm >= 100 && profile.heightCm <= 250 &&
        profile.age >= 13 && profile.age <= 120 &&
        !profile.name.isEmpty
    }

    func validateWeight(_ weight: Double) -> Bool {
        weight >= 30 && weight <= 300
    }

    func validateHeight(_ height: Double) -> Bool {
        height >= 100 && height <= 250
    }

    func validateAge(_ age: Int) -> Bool {
        age >= 13 && age <= 120
    }

    // MARK: - HealthKit
    func requestHealthKitPermissions() async {
        do {
            try await healthService.requestAuthorization()

            // Sync latest weight from HealthKit
            if let weight = try await healthService.fetchLatestWeight() {
                profile.weightKg = weight
                saveProfile()
            }
        } catch {
            self.error = "Failed to connect to Health: \(error.localizedDescription)"
        }
    }
}

// MARK: - Deficit Helpers
extension SettingsViewModel {
    var deficitDescription: String {
        switch profile.deficitPercentage {
        case 0:
            return "Maintenance"
        case 0.01..<0.15:
            return "Mild deficit (\(Int(profile.deficitPercentage * 100))%)"
        case 0.15..<0.25:
            return "Moderate deficit (\(Int(profile.deficitPercentage * 100))%)"
        case 0.25...:
            return "Aggressive deficit (\(Int(profile.deficitPercentage * 100))%)"
        case ..<0:
            return "Surplus (\(Int(abs(profile.deficitPercentage) * 100))%)"
        default:
            return "Custom"
        }
    }

    var deficitWarning: String? {
        if profile.deficitPercentage > 0.25 {
            return "Aggressive deficits may impact recovery and muscle retention."
        }
        if targetCalories < estimatedBMR {
            return "Target is below your BMR. Consider a smaller deficit."
        }
        return nil
    }
}
