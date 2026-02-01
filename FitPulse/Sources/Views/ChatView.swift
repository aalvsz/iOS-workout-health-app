import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var localLLMService = LocalLLMService.shared
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if localLLMService.isLoading {
                    // Model is loading
                    ModelLoadingView(progress: localLLMService.loadingProgress)
                } else if !localLLMService.isModelLoaded {
                    // No model available
                    NoModelView(error: localLLMService.error)
                } else {
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
                        QuickActionsView(onSelect: { action in
                            viewModel.sendMessage(action)
                        })
                    }

                    // Input
                    ChatInputView(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        onSend: { viewModel.sendMessage(viewModel.inputText) }
                    )
                    .focused($isInputFocused)
                }
            }
            .navigationTitle("AI Coach")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(localLLMService.isModelLoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(localLLMService.loadedModelName ?? "Llama 1B")
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
                Text("Loading AI Coach")
                    .font(.title2.bold())

                Text("Preparing Llama 1B model...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 200)

                Text("\(Int(progress * 100))%")
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
                Text("AI Coach Unavailable")
                    .font(.title2.bold())

                Text(error ?? "No Llama 1B model found. Please ensure the model file is bundled with the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await LocalLLMService.shared.autoLoadLlama1BModel()
                }
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
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
                        Text("AI Coach")
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
    let onSelect: (String) -> Void

    private let suggestions = [
        ("How should I structure my workout week?", "calendar"),
        ("What should I eat before training?", "fork.knife"),
        ("How do I improve my bench press?", "figure.strengthtraining.traditional"),
        ("How much protein do I need?", "leaf.fill"),
        ("I'm feeling overtrained, what should I do?", "bed.double.fill"),
        ("Explain progressive overload", "chart.line.uptrend.xyaxis")
    ]

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Ask me anything")
                    .font(.headline)
                Text("Workouts, nutrition, recovery, form tips, and more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask about workouts, nutrition, form...", text: $text, axis: .vertical)
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

    private let llmService = LLMService.shared
    private let persistence = PersistenceController.shared
    private let dataParser = HealthDataParser.shared

    var profile: UserProfile {
        persistence.loadProfile()
    }

    func sendMessage(_ content: String) {
        guard !content.isEmpty else { return }

        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        inputText = ""

        Task {
            await getResponse(for: content)
        }
    }

    private func getResponse(for message: String) async {
        isLoading = true

        do {
            let recentWorkouts = dataParser.getGymWorkouts().prefix(5)
            let workoutSummary = recentWorkouts.map {
                "\($0.name) on \($0.date.shortDate) (\($0.formattedDuration))"
            }.joined(separator: ", ")

            let context = ChatContext(
                userGoal: profile.fitnessGoal.rawValue,
                weight: profile.weightKg,
                recentWorkoutSummary: workoutSummary
            )

            let response = try await llmService.chat(message: message, context: context)
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
        } catch let error as LLMError {
            let errorMessage = ChatMessage(
                content: "**Error:** \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: "**Connection Error:** Could not reach the AI service. Please check your internet connection and try again.",
                isUser: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    func clearChat() {
        messages = []
        llmService.clearConversation()
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
