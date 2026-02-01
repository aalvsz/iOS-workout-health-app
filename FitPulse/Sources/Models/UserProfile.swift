import Foundation
import SwiftUI

// MARK: - User Profile
class UserProfile: ObservableObject, Codable {
    @Published var id: UUID
    @Published var name: String
    @Published var weightKg: Double
    @Published var heightCm: Double
    @Published var age: Int
    @Published var sex: Sex
    @Published var activityLevel: ActivityLevel
    @Published var fitnessGoal: FitnessGoal
    @Published var deficitPercentage: Double
    @Published var proteinPerKg: Double
    @Published var fatPerKg: Double
    @Published var hasCompletedOnboarding: Bool
    @Published var prefersDarkMode: Bool
    @Published var notificationsEnabled: Bool
    @Published var weeklyWorkoutGoal: Int
    @Published var dailyStepsGoal: Int
    @Published var sleepGoalHours: Double
    @Published var targetWeightKg: Double?

    enum Sex: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"

        var bmrConstant: Double {
            switch self {
            case .male: return 5
            case .female: return -161
            }
        }
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extraActive = "Extra Active"

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extraActive: return 1.9
            }
        }

        var description: String {
            switch self {
            case .sedentary: return "Little to no exercise"
            case .lightlyActive: return "Light exercise 1-3 days/week"
            case .moderatelyActive: return "Moderate exercise 3-5 days/week"
            case .veryActive: return "Hard exercise 6-7 days/week"
            case .extraActive: return "Very hard exercise & physical job"
            }
        }
    }

    enum FitnessGoal: String, Codable, CaseIterable {
        case loseWeight = "Lose Weight"
        case maintain = "Maintain Weight"
        case gainMuscle = "Build Muscle"
        case recomp = "Body Recomposition"
        case performance = "Improve Performance"

        var icon: String {
            switch self {
            case .loseWeight: return "arrow.down.circle.fill"
            case .maintain: return "equal.circle.fill"
            case .gainMuscle: return "arrow.up.circle.fill"
            case .recomp: return "arrow.triangle.2.circlepath"
            case .performance: return "bolt.circle.fill"
            }
        }

        var defaultDeficit: Double {
            switch self {
            case .loseWeight: return 0.20
            case .maintain: return 0.0
            case .gainMuscle: return -0.10 // Surplus
            case .recomp: return 0.05
            case .performance: return 0.0
            }
        }

        var proteinRecommendation: ClosedRange<Double> {
            switch self {
            case .loseWeight: return 1.8...2.4
            case .maintain: return 1.4...1.8
            case .gainMuscle: return 1.8...2.2
            case .recomp: return 2.0...2.4
            case .performance: return 1.6...2.0
            }
        }
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, weightKg, heightCm, age, sex, activityLevel, fitnessGoal
        case deficitPercentage, proteinPerKg, fatPerKg, hasCompletedOnboarding
        case prefersDarkMode, notificationsEnabled, weeklyWorkoutGoal, dailyStepsGoal, sleepGoalHours
        case targetWeightKg
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        weightKg: Double = 70,
        heightCm: Double = 170,
        age: Int = 30,
        sex: Sex = .male,
        activityLevel: ActivityLevel = .moderatelyActive,
        fitnessGoal: FitnessGoal = .maintain,
        deficitPercentage: Double = 0.15,
        proteinPerKg: Double = 1.8,
        fatPerKg: Double = 0.8,
        hasCompletedOnboarding: Bool = false,
        prefersDarkMode: Bool = true,
        notificationsEnabled: Bool = true,
        weeklyWorkoutGoal: Int = 4,
        dailyStepsGoal: Int = 10000,
        sleepGoalHours: Double = 8.0,
        targetWeightKg: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.sex = sex
        self.activityLevel = activityLevel
        self.fitnessGoal = fitnessGoal
        self.deficitPercentage = deficitPercentage
        self.proteinPerKg = proteinPerKg
        self.fatPerKg = fatPerKg
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.prefersDarkMode = prefersDarkMode
        self.notificationsEnabled = notificationsEnabled
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.dailyStepsGoal = dailyStepsGoal
        self.sleepGoalHours = sleepGoalHours
        self.targetWeightKg = targetWeightKg
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        heightCm = try container.decode(Double.self, forKey: .heightCm)
        age = try container.decode(Int.self, forKey: .age)
        sex = try container.decode(Sex.self, forKey: .sex)
        activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        fitnessGoal = try container.decode(FitnessGoal.self, forKey: .fitnessGoal)
        deficitPercentage = try container.decode(Double.self, forKey: .deficitPercentage)
        proteinPerKg = try container.decode(Double.self, forKey: .proteinPerKg)
        fatPerKg = try container.decode(Double.self, forKey: .fatPerKg)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        prefersDarkMode = try container.decode(Bool.self, forKey: .prefersDarkMode)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        weeklyWorkoutGoal = try container.decode(Int.self, forKey: .weeklyWorkoutGoal)
        dailyStepsGoal = try container.decode(Int.self, forKey: .dailyStepsGoal)
        sleepGoalHours = try container.decode(Double.self, forKey: .sleepGoalHours)
        targetWeightKg = try container.decodeIfPresent(Double.self, forKey: .targetWeightKg)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(weightKg, forKey: .weightKg)
        try container.encode(heightCm, forKey: .heightCm)
        try container.encode(age, forKey: .age)
        try container.encode(sex, forKey: .sex)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(fitnessGoal, forKey: .fitnessGoal)
        try container.encode(deficitPercentage, forKey: .deficitPercentage)
        try container.encode(proteinPerKg, forKey: .proteinPerKg)
        try container.encode(fatPerKg, forKey: .fatPerKg)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(prefersDarkMode, forKey: .prefersDarkMode)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(weeklyWorkoutGoal, forKey: .weeklyWorkoutGoal)
        try container.encode(dailyStepsGoal, forKey: .dailyStepsGoal)
        try container.encode(sleepGoalHours, forKey: .sleepGoalHours)
        try container.encodeIfPresent(targetWeightKg, forKey: .targetWeightKg)
    }

    // MARK: - Computed Properties
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    var estimatedBMR: Double {
        // Mifflin-St Jeor Equation
        return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + sex.bmrConstant
    }

    var estimatedTDEE: Double {
        estimatedBMR * activityLevel.multiplier
    }

    // MARK: - Persistence
    private static let userDefaultsKey = "userProfile"

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    static func load() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile()
    }
}

// MARK: - Weight Entry
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weightKg: Double
    let note: String?

    init(id: UUID = UUID(), date: Date = Date(), weightKg: Double, note: String? = nil) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.note = note
    }
}
