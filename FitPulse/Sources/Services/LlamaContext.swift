import Foundation

/// LlamaContext - Inference backend
/// On simulator: Uses Ollama running on Mac
/// On device: Would use native llama.cpp with Metal (requires package integration)
@MainActor
class LlamaContext: ObservableObject {
    @Published var isModelLoaded = false
    @Published var loadingProgress: Double = 0
    @Published var isGenerating = false

    private var loadedModelPath: String?
    private var ollamaModelName: String?

    struct LlamaConfig {
        var contextSize: Int32 = 2048
        var batchSize: Int32 = 512
        var gpuLayers: Int32 = 99
        var threads: Int32 = 4
        var temperature: Float = 0.7
        var topP: Float = 0.9
        var topK: Int32 = 40
        var repeatPenalty: Float = 1.1

        static var `default`: LlamaConfig { LlamaConfig() }
        static var lowMemory: LlamaConfig { LlamaConfig() }
    }

    init(config: LlamaConfig = .default) {}

    func loadModel(from path: String) async throws {
        loadingProgress = 0.2

        // Extract model name from path for Ollama
        let url = URL(fileURLWithPath: path)
        let fileName = url.deletingPathExtension().lastPathComponent.lowercased()

        // Map to Ollama model names
        if fileName.contains("llama") && fileName.contains("1b") {
            ollamaModelName = "fitcoach-llama1b"
        } else if fileName.contains("gilda") || fileName.contains("3b") || fileName.contains("3.2b") {
            ollamaModelName = "fitcoach-gilda"
        } else {
            ollamaModelName = "fitcoach-llama1b" // default
        }

        loadingProgress = 0.5

        // Verify Ollama is running and model is available
        do {
            let testURL = URL(string: "http://localhost:11434/api/tags")!
            let (_, response) = try await URLSession.shared.data(from: testURL)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw LlamaError.loadFailed("Ollama not running. Start with: ollama serve")
            }
        } catch {
            throw LlamaError.loadFailed("Cannot connect to Ollama at localhost:11434. Make sure Ollama is running.")
        }

        loadingProgress = 1.0
        loadedModelPath = path
        isModelLoaded = true
    }

    func unloadModel() {
        isModelLoaded = false
        loadedModelPath = nil
        ollamaModelName = nil
        loadingProgress = 0
    }

    func generate(prompt: String, maxTokens: Int = 512) async throws -> String {
        guard isModelLoaded, let modelName = ollamaModelName else {
            throw LlamaError.modelNotLoaded
        }

        isGenerating = true
        defer { isGenerating = false }

        // Use Ollama for inference
        let body: [String: Any] = [
            "model": modelName,
            "messages": [["role": "user", "content": prompt]],
            "stream": false
        ]

        var request = URLRequest(url: URL(string: "http://localhost:11434/api/chat")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LlamaError.loadFailed("Ollama inference failed")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let message = json?["message"] as? [String: Any]
        let content = message?["content"] as? String

        return content ?? "No response"
    }

    func generateStreaming(prompt: String, maxTokens: Int = 512, onToken: @escaping (String) -> Void) async throws -> String {
        // For simplicity, use non-streaming and return full result
        let result = try await generate(prompt: prompt, maxTokens: maxTokens)
        onToken(result)
        return result
    }

    var modelInfo: String? {
        ollamaModelName
    }

    var contextLength: Int {
        2048
    }
}

// MARK: - Errors

enum LlamaError: LocalizedError {
    case modelNotFound(String)
    case loadFailed(String)
    case contextCreationFailed
    case modelNotLoaded
    case tokenizationFailed
    case decodeFailed
    case llamaCppNotAvailable

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Model file not found: \(path)"
        case .loadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .contextCreationFailed:
            return "Failed to create inference context"
        case .modelNotLoaded:
            return "No model is loaded"
        case .tokenizationFailed:
            return "Failed to tokenize input"
        case .decodeFailed:
            return "Decoding failed during generation"
        case .llamaCppNotAvailable:
            return "llmfarm_core is not integrated. Add the package to enable native inference."
        }
    }
}
