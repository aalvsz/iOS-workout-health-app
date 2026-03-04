import Foundation

@MainActor
class WorkoutTemplatesViewModel: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []
    @Published var editingTemplate: WorkoutTemplate?
    @Published var isEditing = false

    private let persistence = PersistenceController.shared

    init() {
        loadTemplates()
    }

    func loadTemplates() {
        templates = persistence.loadWorkoutTemplates()
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveTemplate(_ template: WorkoutTemplate) {
        var updated = template
        updated.updatedAt = Date()
        persistence.saveWorkoutTemplate(updated)
        loadTemplates()
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        persistence.deleteWorkoutTemplate(template)
        loadTemplates()
    }

    func startEditing(_ template: WorkoutTemplate? = nil) {
        editingTemplate = template ?? WorkoutTemplate(name: "")
        isEditing = true
    }
}
