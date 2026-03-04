import Foundation

// MARK: - Template Exercise

struct TemplateExercise: Identifiable, Codable {
    let id: UUID
    let name: String
    var targetSets: Int
    var targetReps: String
    var targetWeightKg: Double?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        targetSets: Int = 3,
        targetReps: String = "8-10",
        targetWeightKg: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.notes = notes
    }
}

// MARK: - Workout Template

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [TemplateExercise]
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [TemplateExercise] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var estimatedDurationMinutes: Int {
        exercises.reduce(0) { $0 + ($1.targetSets * 3) } + 5
    }
}
