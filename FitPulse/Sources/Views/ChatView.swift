import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var localLLMService = LocalLLMService.shared
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if localLLMService.isLoading {
                    ModelLoadingView(progress: localLLMService.loadingProgress)
                } else if !localLLMService.isModelLoaded {
                    NoModelView(error: localLLMService.error)
                } else {
                    // Mode Picker
                    ModePicker(currentMode: $viewModel.currentMode) {
                        viewModel.switchMode(to: $0)
                    }

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading {
                                    TypingIndicator()
                                }
                            }
                            .padding()
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Quick Actions (only when empty)
                    if viewModel.messages.isEmpty {
                        QuickActionsView(
                            suggestions: viewModel.currentMode.quickActions,
                            onSelect: { action in
                                viewModel.sendMessage(action)
                            }
                        )
                    }

                    // Input
                    ChatInputView(
                        text: $viewModel.inputText,
                        placeholder: viewModel.currentMode.placeholder,
                        isLoading: viewModel.isLoading,
                        onSend: { viewModel.sendMessage(viewModel.inputText) }
                    )
                    .focused($isInputFocused)
                }
            }
            .navigationTitle(viewModel.currentMode.displayName)
            .sheet(isPresented: $viewModel.showingMealLogConfirmation) {
                if let parsed = viewModel.pendingMealLog {
                    QuickMealLogConfirmSheet(parsed: parsed) { mealType in
                        viewModel.confirmMealLog(parsed, mealType: mealType)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(localLLMService.isModelLoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(localLLMService.loadedModelName ?? String(localized: "Gemma 3 1B"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.clearChat() }) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
        }
    }
}

// MARK: - Mode Picker
struct ModePicker: View {
    @Binding var currentMode: ChatMode
    let onSwitch: (ChatMode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChatMode.allCases) { mode in
                    Button(action: { onSwitch(mode) }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.caption)
                            Text(mode.displayName)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(currentMode == mode ? Color.blue : Color.secondary.opacity(0.1))
                        .foregroundStyle(currentMode == mode ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Model Loading View
struct ModelLoadingView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text(String(localized: "Loading AI Coach"))
                    .font(.title2.bold())

                Text(String(localized: "Preparing Gemma 3 1B model..."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 200)

                Text(String(localized: "\(Int(progress * 100))%"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - No Model View
struct NoModelView: View {
    let error: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(String(localized: "AI Coach Unavailable"))
                    .font(.title2.bold())

                Text(error ?? String(localized: "No Gemma 3 1B model found. Please ensure the model file is bundled with the app."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await LocalLLMService.shared.autoLoadModel()
                }
            }) {
                Label(String(localized: "Retry"), systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(String(localized: "AI Coach"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(.init(message.content)) // Supports markdown
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color.blue : Color.secondary.opacity(0.15))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    let suggestions: [(String, String)]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.0) { suggestion in
                        Button(action: { onSelect(suggestion.0) }) {
                            HStack(spacing: 6) {
                                Image(systemName: suggestion.1)
                                    .font(.caption)
                                Text(suggestion.0)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Chat Input
struct ChatInputView: View {
    @Binding var text: String
    var placeholder: String = String(localized: "Ask about workouts, nutrition, form...")
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    if !text.isEmpty && !isLoading {
                        onSend()
                    }
                }

            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(text.isEmpty || isLoading ? .gray : .blue)
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

// MARK: - Chat ViewModel
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var currentMode: ChatMode = .generalQA
    @Published var pendingMealLog: LLMParsedMeal?
    @Published var showingMealLogConfirmation = false

    private let llmService = LLMService.shared
    private let persistence = PersistenceController.shared
    private let dataParser = HealthDataParser.shared

    var profile: UserProfile {
        persistence.loadProfile()
    }

    func switchMode(to mode: ChatMode) {
        guard mode != currentMode else { return }
        currentMode = mode
        messages = []
        llmService.clearConversation()
    }

    func sendMessage(_ content: String) {
        guard !content.isEmpty else { return }

        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // In Meal Estimator mode, route directly to meal parsing
        if currentMode == .mealEstimator {
            Task { await parseMealDirectly(content) }
        } else {
            Task { await getResponse(for: content) }
        }
    }

    private func parseMealDirectly(_ description: String) async {
        isLoading = true

        do {
            let parsed = try await llmService.parseMealFromDescription(description)
            pendingMealLog = parsed
            showingMealLogConfirmation = true

            let summary = parsed.foods.map { "\($0.name) (\($0.servingSize))" }.joined(separator: ", ")
            let aiMessage = ChatMessage(
                content: String(localized: "**\(parsed.mealName)** - \(Int(parsed.totalCalories)) kcal\n\n\(summary)\n\n\(Int(parsed.totalProtein))g P / \(Int(parsed.totalCarbs))g C / \(Int(parsed.totalFat))g F"),
                isUser: false
            )
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: String(localized: "Could not parse that meal. Try being more specific (e.g. \"200g chicken breast with 150g rice\")."),
                isUser: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    private func getResponse(for message: String) async {
        isLoading = true

        do {
            let context = buildChatContext()
            let systemPrompt = currentMode.systemPrompt(context: context)
            let response = try await llmService.chat(message: message, systemPrompt: systemPrompt)
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)

            // Check for meal logging intent in non-estimator modes
            checkForMealLoggingIntent(message)
        } catch let error as LLMError {
            let errorMessage = ChatMessage(
                content: String(localized: "**Error:** \(error.localizedDescription)"),
                isUser: false
            )
            messages.append(errorMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: String(localized: "**Error:** Could not get a response. Please try again."),
                isUser: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    private func buildChatContext() -> ChatContext {
        let recentWorkouts = dataParser.getGymWorkouts().prefix(5)
        let workoutSummary = recentWorkouts.map {
            "\($0.name) on \($0.date.shortDate) (\($0.formattedDuration))"
        }.joined(separator: ", ")

        return ChatContext(
            userGoal: profile.fitnessGoal.rawValue,
            weight: profile.weightKg,
            recentWorkoutSummary: workoutSummary
        )
    }

    func clearChat() {
        messages = []
        llmService.clearConversation()
    }

    private func checkForMealLoggingIntent(_ userMessage: String) {
        let mealKeywords = ["ate", "had for", "consumed", "just ate", "had a", "i ate", "i had",
                            "for breakfast", "for lunch", "for dinner", "for snack"]
        let lower = userMessage.lowercased()
        guard mealKeywords.contains(where: { lower.contains($0) }) else { return }

        Task {
            if let parsed = try? await llmService.parseMealFromDescription(userMessage) {
                pendingMealLog = parsed
                showingMealLogConfirmation = true
            }
        }
    }

    func confirmMealLog(_ parsed: LLMParsedMeal, mealType: Meal.MealType) {
        let foods = parsed.foods.map { f in
            Food(name: f.name, servingSize: f.servingSize,
                 calories: f.calories, protein: f.protein,
                 carbs: f.carbs, fat: f.fat)
        }
        let meal = Meal(
            name: parsed.mealName,
            mealType: mealType,
            calories: parsed.totalCalories,
            protein: parsed.totalProtein,
            carbs: parsed.totalCarbs,
            fat: parsed.totalFat,
            foods: foods
        )
        persistence.saveMeal(meal)
        showingMealLogConfirmation = false
        pendingMealLog = nil

        let confirmMsg = ChatMessage(
            content: String(localized: "Logged **\(parsed.mealName)** (\(Int(parsed.totalCalories)) kcal) to your \(mealType.rawValue.lowercased())."),
            isUser: false
        )
        messages.append(confirmMsg)
    }
}

// MARK: - Quick Meal Log Confirm Sheet
struct QuickMealLogConfirmSheet: View {
    let parsed: LLMParsedMeal
    let onConfirm: (Meal.MealType) -> Void

    @State private var selectedType: Meal.MealType = .lunch
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text(String(localized: "Log this meal?"))
                            .font(.headline)
                    }

                    Text(parsed.mealName)
                        .font(.title3.bold())

                    ForEach(parsed.foods, id: \.name) { food in
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                            Spacer()
                            Text(food.servingSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 16) {
                        Text(String(localized: "\(Int(parsed.totalCalories)) kcal"))
                            .font(.subheadline.bold())
                        Spacer()
                        Text(String(localized: "\(Int(parsed.totalProtein))g P"))
                            .font(.caption).foregroundStyle(.blue)
                        Text(String(localized: "\(Int(parsed.totalCarbs))g C"))
                            .font(.caption).foregroundStyle(.orange)
                        Text(String(localized: "\(Int(parsed.totalFat))g F"))
                            .font(.caption).foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Picker(String(localized: "Meal Type"), selection: $selectedType) {
                    ForEach(Meal.MealType.allCases, id: \.self) {
                        Text(LocalizedStringKey($0.rawValue)).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                Button(action: { onConfirm(selectedType) }) {
                    Text(String(localized: "Log Meal"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "Log Meal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

#Preview {
    ChatView()
        .environmentObject(UserProfile())
}
