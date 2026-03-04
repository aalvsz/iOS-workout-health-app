import SwiftUI

struct WorkoutTemplatesView: View {
    @StateObject private var viewModel = WorkoutTemplatesViewModel()

    var body: some View {
        Group {
            if viewModel.templates.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 50))
                        .foregroundStyle(.teal)
                    VStack(spacing: 8) {
                        Text(String(localized: "No Templates Yet"))
                            .font(.title2.bold())
                        Text(String(localized: "Create a workout template to reuse your favorite routines."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: { viewModel.startEditing() }) {
                        Label(String(localized: "Create Template"), systemImage: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.teal)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.templates) { template in
                        TemplateRow(
                            template: template,
                            onEdit: { viewModel.startEditing(template) }
                        )
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.deleteTemplate(viewModel.templates[$0]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(String(localized: "My Templates"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.startEditing() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            if let template = viewModel.editingTemplate {
                TemplateEditorView(template: template) { saved in
                    viewModel.saveTemplate(saved)
                    viewModel.isEditing = false
                }
            }
        }
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: WorkoutTemplate
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Text(String(localized: "~\(template.estimatedDurationMinutes) min"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(String(localized: "\(template.exercises.count) exercises"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !template.exercises.isEmpty {
                Text(template.exercises.prefix(3).map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Button(String(localized: "Edit"), action: onEdit)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Template Editor
struct TemplateEditorView: View {
    @State private var template: WorkoutTemplate
    let onSave: (WorkoutTemplate) -> Void

    @State private var showingExercisePicker = false
    @Environment(\.dismiss) var dismiss

    init(template: WorkoutTemplate, onSave: @escaping (WorkoutTemplate) -> Void) {
        self._template = State(initialValue: template)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Template Name")) {
                    TextField(String(localized: "e.g. Push Day A"), text: $template.name)
                }

                Section(String(localized: "Exercises (\(template.exercises.count))")) {
                    ForEach($template.exercises) { $exercise in
                        TemplateExerciseRow(exercise: $exercise)
                    }
                    .onDelete { template.exercises.remove(atOffsets: $0) }
                    .onMove { template.exercises.move(fromOffsets: $0, toOffset: $1) }

                    Button(action: { showingExercisePicker = true }) {
                        Label(String(localized: "Add Exercise"), systemImage: "plus.circle")
                    }
                }

                Section(String(localized: "Notes")) {
                    TextField(String(localized: "Optional notes"), text: Binding(
                        get: { template.notes ?? "" },
                        set: { template.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }

                if !template.exercises.isEmpty {
                    Section(String(localized: "Summary")) {
                        LabeledContent(String(localized: "Total Exercises"), value: "\(template.exercises.count)")
                        LabeledContent(String(localized: "Total Sets"), value: "\(template.exercises.reduce(0) { $0 + $1.targetSets })")
                        LabeledContent(String(localized: "Est. Duration"), value: String(localized: "~\(template.estimatedDurationMinutes) min"))
                    }
                }
            }
            .navigationTitle(template.name.isEmpty ? String(localized: "New Template") : template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) { onSave(template) }
                        .disabled(template.name.isEmpty || template.exercises.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { selected in
                    template.exercises.append(
                        TemplateExercise(name: selected.name)
                    )
                    showingExercisePicker = false
                }
            }
        }
    }
}

// MARK: - Template Exercise Row
struct TemplateExerciseRow: View {
    @Binding var exercise: TemplateExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.subheadline.bold())

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(String(localized: "Sets:"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper("\(exercise.targetSets)", value: $exercise.targetSets, in: 1...10)
                        .labelsHidden()
                    Text("\(exercise.targetSets)")
                        .font(.caption.bold())
                        .frame(width: 20)
                }

                HStack(spacing: 4) {
                    Text(String(localized: "Reps:"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("8-10", text: $exercise.targetReps)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Exercise Picker
struct ExercisePickerView: View {
    let onSelect: (ExerciseLibraryItem) -> Void

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @Environment(\.dismiss) var dismiss

    private var filtered: [ExerciseLibraryItem] {
        var result = ExerciseLibrary.allExercises
        if let group = selectedGroup {
            result = ExerciseLibrary.exercises(for: group)
        }
        if !searchText.isEmpty {
            result = ExerciseLibrary.search(query: searchText)
        }
        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: String(localized: "All"), isSelected: selectedGroup == nil) {
                            selectedGroup = nil
                        }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            FilterChip(label: group.displayName, isSelected: selectedGroup == group) {
                                selectedGroup = selectedGroup == group ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List(filtered) { exercise in
                    Button(action: {
                        onSelect(exercise)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: String(localized: "Search exercises"))
            }
            .navigationTitle(String(localized: "Add Exercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }
}
