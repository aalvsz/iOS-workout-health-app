import Foundation
import SwiftUI

/// Native GGUF model inference service using llama.cpp
/// Provides true on-device inference with Metal GPU acceleration
///
/// Models can be:
/// 1. Bundled with the app (in Resources)
/// 2. Imported by user to Documents directory
/// 3. Downloaded from a server

@MainActor
class LocalLLMService: ObservableObject {
    static let shared = LocalLLMService()

    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    @Published var loadedModelName: String?
    @Published var availableModels: [LocalModel] = []
    @Published var error: String?
    @Published var isGenerating = false

    private var llamaContext: LlamaContext?
    private var conversationHistory: [Message] = []

    struct LocalModel: Identifiable, Codable, Hashable {
        var id: String { path }
        let name: String
        let path: String
        let sizeBytes: Int64
        let quantization: String
        let location: ModelLocation

        enum ModelLocation: String, Codable {
            case bundled = "Bundled"
            case documents = "Documents"
            case custom = "Custom"
        }

        var sizeFormatted: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: sizeBytes)
        }
    }

    struct Message {
        let role: String
        let content: String
    }

    private init() {
        scanForModels()
    }

    // MARK: - Auto-Load Llama 1B

    /// Automatically finds and loads a Llama 1B model on app startup
    func autoLoadLlama1BModel() async {
        // Don't reload if already loaded
        guard !isModelLoaded else { return }

        // Scan for models first
        scanForModels()

        // Look for Llama 1B model (prioritize by name patterns)
        let llama1BPatterns = ["llama-3.2-1b", "llama3.2-1b", "llama-1b", "1b"]

        // Find best matching model
        var bestMatch: LocalModel?
        for pattern in llama1BPatterns {
            if let model = availableModels.first(where: {
                $0.name.lowercased().contains(pattern) ||
                $0.path.lowercased().contains(pattern)
            }) {
                bestMatch = model
                break
            }
        }

        // If no Llama 1B found, try any available model (fallback)
        let modelToLoad = bestMatch ?? availableModels.first

        guard let model = modelToLoad else {
            error = "No GGUF model found. Please add a Llama model to the app."
            return
        }

        do {
            try await loadModel(model)
        } catch {
            self.error = "Failed to load model: \(error.localizedDescription)"
        }
    }

    // MARK: - Model Discovery

    func scanForModels() {
        var models: [LocalModel] = []

        // 1. Check bundled models in app resources
        if let bundlePath = Bundle.main.resourcePath {
            let bundleURL = URL(fileURLWithPath: bundlePath)
            models.append(contentsOf: findGGUFModels(in: bundleURL, location: .bundled))
        }

        // 2. Check app Documents directory (user-imported models)
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelsDir = documentsURL.appendingPathComponent("Models", isDirectory: true)

            // Create Models directory if it doesn't exist
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

            models.append(contentsOf: findGGUFModels(in: modelsDir, location: .documents))

            // Also check root documents directory
            models.append(contentsOf: findGGUFModels(in: documentsURL, location: .documents))
        }

        #if targetEnvironment(simulator)
        // For simulator/development, also check common local paths
        let devPaths = [
            "/Users/ander.alvarez/Documents/dev-code/personal/sport-and-health",
            "/Users/ander.alvarez/Library/CloudStorage/OneDrive-MultiverseComputing/models/gilda"
        ]
        for path in devPaths {
            let url = URL(fileURLWithPath: path)
            models.append(contentsOf: findGGUFModels(in: url, location: .custom))
        }
        #endif

        availableModels = models
    }

    private func findGGUFModels(in directory: URL, location: LocalModel.ModelLocation) -> [LocalModel] {
        var models: [LocalModel] = []

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "gguf" {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let size = attributes[.size] as? Int64 {
                    let name = fileURL.deletingPathExtension().lastPathComponent
                    let quantization = extractQuantization(from: name)

                    models.append(LocalModel(
                        name: formatModelName(name),
                        path: fileURL.path,
                        sizeBytes: size,
                        quantization: quantization,
                        location: location
                    ))
                }
            }
        }

        return models
    }

    private func extractQuantization(from name: String) -> String {
        let patterns = ["Q4_K_M", "Q4_K_S", "Q5_K_M", "Q5_K_S", "Q8_0", "BF16", "F16", "Q4_0", "Q4_1", "Q2_K", "Q3_K"]
        let upperName = name.uppercased()
        for pattern in patterns {
            if upperName.contains(pattern) {
                return pattern
            }
        }
        return "Unknown"
    }

    private func formatModelName(_ name: String) -> String {
        // Clean up common naming patterns
        var cleanName = name
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        // Remove quantization suffix for display
        let patterns = ["Q4 K M", "Q4 K S", "Q5 K M", "BF16", "F16", "Q4 0", "GGUF"]
        for pattern in patterns {
            cleanName = cleanName.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }

        return cleanName.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Model Loading

    func loadModel(_ model: LocalModel) async throws {
        isLoading = true
        loadingProgress = 0
        error = nil

        defer { isLoading = false }

        // Determine config based on model size
        let config: LlamaContext.LlamaConfig
        if model.sizeBytes < 2_000_000_000 { // < 2GB
            config = .default
        } else {
            config = .lowMemory
        }

        // Create new context
        let context = LlamaContext(config: config)
        llamaContext = context

        // Observe loading progress
        let task = Task { @MainActor in
            for await _ in context.$loadingProgress.values {
                self.loadingProgress = context.loadingProgress
            }
        }

        do {
            try await context.loadModel(from: model.path)
            loadedModelName = model.name
            task.cancel()
        } catch {
            self.error = error.localizedDescription
            llamaContext = nil
            task.cancel()
            throw error
        }
    }

    func loadModel(at path: String) async throws {
        guard let model = availableModels.first(where: { $0.path == path }) else {
            // Create a temporary model reference
            let url = URL(fileURLWithPath: path)
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            let size = attrs?[.size] as? Int64 ?? 0

            let tempModel = LocalModel(
                name: url.deletingPathExtension().lastPathComponent,
                path: path,
                sizeBytes: size,
                quantization: extractQuantization(from: url.lastPathComponent),
                location: .custom
            )
            try await loadModel(tempModel)
            return
        }
        try await loadModel(model)
    }

    func unloadModel() {
        llamaContext?.unloadModel()
        llamaContext = nil
        loadedModelName = nil
        conversationHistory = []
    }

    var isModelLoaded: Bool {
        llamaContext?.isModelLoaded ?? false
    }

    // MARK: - Inference

    /// Generate a response using native llama.cpp inference
    func generate(prompt: String, systemPrompt: String) async throws -> String {
        guard let context = llamaContext, context.isModelLoaded else {
            throw LocalLLMError.modelNotLoaded
        }

        isGenerating = true
        defer { isGenerating = false }

        // Add to conversation history
        conversationHistory.append(Message(role: "user", content: prompt))

        // Build full prompt with conversation history
        let fullPrompt = buildPrompt(systemPrompt: systemPrompt)

        // Generate response
        let response = try await context.generate(prompt: fullPrompt, maxTokens: 1024)

        // Clean up response
        let cleanedResponse = cleanResponse(response)

        conversationHistory.append(Message(role: "assistant", content: cleanedResponse))
        return cleanedResponse
    }

    /// Generate with streaming callback
    func generateStreaming(
        prompt: String,
        systemPrompt: String,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard let context = llamaContext, context.isModelLoaded else {
            throw LocalLLMError.modelNotLoaded
        }

        isGenerating = true
        defer { isGenerating = false }

        conversationHistory.append(Message(role: "user", content: prompt))

        let fullPrompt = buildPrompt(systemPrompt: systemPrompt)

        let response = try await context.generateStreaming(
            prompt: fullPrompt,
            maxTokens: 1024,
            onToken: onToken
        )

        let cleanedResponse = cleanResponse(response)
        conversationHistory.append(Message(role: "assistant", content: cleanedResponse))
        return cleanedResponse
    }

    private func buildPrompt(systemPrompt: String) -> String {
        var prompt = ""

        // Llama 3 chat format
        prompt += "<|begin_of_text|>"
        prompt += "<|start_header_id|>system<|end_header_id|>\n\n"
        prompt += systemPrompt
        prompt += "<|eot_id|>"

        // Add conversation history (keep last 10 messages for context window)
        let recentHistory = conversationHistory.suffix(10)
        for message in recentHistory {
            prompt += "<|start_header_id|>\(message.role)<|end_header_id|>\n\n"
            prompt += message.content
            prompt += "<|eot_id|>"
        }

        // Start assistant response
        prompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"

        return prompt
    }

    private func cleanResponse(_ response: String) -> String {
        var cleaned = response

        // Remove any trailing special tokens
        let tokensToRemove = ["<|eot_id|>", "<|end_of_text|>", "<|start_header_id|>"]
        for token in tokensToRemove {
            cleaned = cleaned.replacingOccurrences(of: token, with: "")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clearHistory() {
        conversationHistory = []
    }

    // MARK: - Model Info

    var modelInfo: String? {
        llamaContext?.modelInfo
    }

    var contextLength: Int {
        llamaContext?.contextLength ?? 0
    }
}

// MARK: - Errors

enum LocalLLMError: LocalizedError {
    case modelNotFound
    case modelNotLoaded
    case loadError(String)
    case inferenceError(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found"
        case .modelNotLoaded:
            return "No model is loaded. Please select a model in settings."
        case .loadError(let msg):
            return "Failed to load model: \(msg)"
        case .inferenceError(let msg):
            return "Inference failed: \(msg)"
        }
    }
}

// MARK: - Fitness Coach System Prompt

extension LocalLLMService {
    static func fitnessCoachSystemPrompt(userGoal: String, weight: Double, recentWorkouts: String) -> String {
        """
        You are an elite fitness coach and sports nutritionist. You provide expert advice on:

        - Strength training, hypertrophy, and exercise programming
        - Proper form and technique for all major lifts
        - Sports nutrition: macros, meal timing, supplements
        - Recovery, sleep optimization, and injury prevention

        USER CONTEXT:
        - Goal: \(userGoal)
        - Weight: \(String(format: "%.1f", weight)) kg
        - Recent Training: \(recentWorkouts.isEmpty ? "No recent data" : recentWorkouts)

        GUIDELINES:
        1. Be conversational but informative
        2. Give specific, actionable advice (sets, reps, weights when relevant)
        3. Use scientific evidence but explain it simply
        4. Consider the user's goal in all responses
        5. For exercises, include form cues
        6. For nutrition, give practical food examples
        7. Keep responses concise but thorough
        """
    }
}

// MARK: - Model Import Helper

extension LocalLLMService {
    /// Returns the Documents/Models directory URL for importing models
    var modelsDirectoryURL: URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let modelsDir = documentsURL.appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }

    /// Import a GGUF model from a URL (e.g., from Files app)
    func importModel(from sourceURL: URL) async throws -> LocalModel {
        guard let modelsDir = modelsDirectoryURL else {
            throw LocalLLMError.loadError("Cannot access Documents directory")
        }

        let destURL = modelsDir.appendingPathComponent(sourceURL.lastPathComponent)

        // Start accessing security-scoped resource
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw LocalLLMError.loadError("Cannot access file")
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        // Copy file
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destURL)

        // Refresh model list
        scanForModels()

        // Return the imported model
        guard let model = availableModels.first(where: { $0.path == destURL.path }) else {
            throw LocalLLMError.loadError("Failed to register imported model")
        }

        return model
    }

    /// Delete a model from the Documents directory
    func deleteModel(_ model: LocalModel) throws {
        guard model.location == .documents else {
            throw LocalLLMError.loadError("Cannot delete bundled models")
        }

        if loadedModelName == model.name {
            unloadModel()
        }

        try FileManager.default.removeItem(atPath: model.path)
        scanForModels()
    }
}
