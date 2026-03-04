import Foundation

// MARK: - Muscle Group

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"

    var displayName: String {
        switch self {
        case .chest: return String(localized: "Chest")
        case .back: return String(localized: "Back")
        case .shoulders: return String(localized: "Shoulders")
        case .biceps: return String(localized: "Biceps")
        case .triceps: return String(localized: "Triceps")
        case .forearms: return String(localized: "Forearms")
        case .core: return String(localized: "Core")
        case .quads: return String(localized: "Quads")
        case .hamstrings: return String(localized: "Hamstrings")
        case .glutes: return String(localized: "Glutes")
        case .calves: return String(localized: "Calves")
        case .fullBody: return String(localized: "Full Body")
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.arms.open"
        case .triceps: return "figure.arms.open"
        case .forearms: return "hand.raised.fill"
        case .core: return "figure.core.training"
        case .quads: return "figure.run"
        case .hamstrings: return "figure.run"
        case .glutes: return "figure.strengthtraining.functional"
        case .calves: return "figure.walk"
        case .fullBody: return "figure.cross.training"
        }
    }
}

// MARK: - Equipment

enum ExerciseEquipment: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cableMachine = "Cable Machine"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case resistanceBand = "Resistance Band"
    case pullUpBar = "Pull-Up Bar"

    var displayName: String {
        switch self {
        case .barbell: return String(localized: "Barbell")
        case .dumbbell: return String(localized: "Dumbbell")
        case .cableMachine: return String(localized: "Cable Machine")
        case .machine: return String(localized: "Machine")
        case .bodyweight: return String(localized: "Bodyweight")
        case .kettlebell: return String(localized: "Kettlebell")
        case .resistanceBand: return String(localized: "Resistance Band")
        case .pullUpBar: return String(localized: "Pull-Up Bar")
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .cableMachine: return "cable.connector"
        case .machine: return "gearshape.fill"
        case .bodyweight: return "figure.stand"
        case .kettlebell: return "scalemass.fill"
        case .resistanceBand: return "line.diagonal"
        case .pullUpBar: return "figure.arms.open"
        }
    }
}

// MARK: - Difficulty

enum ExerciseDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var displayName: String {
        switch self {
        case .beginner: return String(localized: "Beginner")
        case .intermediate: return String(localized: "Intermediate")
        case .advanced: return String(localized: "Advanced")
        }
    }
}

// MARK: - Exercise Library Item

struct ExerciseLibraryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: ExerciseEquipment
    let difficulty: ExerciseDifficulty
    let instructions: [String]
    let commonMistakes: [String]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: ExerciseEquipment,
        difficulty: ExerciseDifficulty = .intermediate,
        instructions: [String] = [],
        commonMistakes: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.difficulty = difficulty
        self.instructions = instructions
        self.commonMistakes = commonMistakes
    }
}
