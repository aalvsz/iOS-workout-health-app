import Foundation
import llama

// MARK: - Batch Helpers

private func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

private func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    batch.token[Int(batch.n_tokens)] = id
    batch.pos[Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    for i in 0..<seq_ids.count {
        batch.seq_id[Int(batch.n_tokens)]![Int(i)] = seq_ids[i]
    }
    batch.logits[Int(batch.n_tokens)] = logits ? 1 : 0
    batch.n_tokens += 1
}

// MARK: - LlamaContext Actor

actor LlamaContext {
    private var model: OpaquePointer
    private var context: OpaquePointer
    private var vocab: OpaquePointer
    private var sampling: UnsafeMutablePointer<llama_sampler>
    private var batch: llama_batch

    private let config: LlamaConfig

    // Observable state — updated via MainActor callbacks
    private(set) var isModelLoadedInternal = true
    private(set) var isGeneratingInternal = false

    struct LlamaConfig {
        var contextSize: Int32 = 2048
        var batchSize: Int32 = 512
        var gpuLayers: Int32 = 99
        var threads: Int32 = Int32(max(1, min(8, ProcessInfo.processInfo.processorCount - 2)))
        var temperature: Float = 0.7
        var topP: Float = 0.9
        var topK: Int32 = 40
        var repeatPenalty: Float = 1.3

        static var `default`: LlamaConfig { LlamaConfig() }
        static var lowMemory: LlamaConfig {
            var config = LlamaConfig()
            config.contextSize = 1024
            config.batchSize = 256
            return config
        }
    }

    // MARK: - Initialization

    private init(model: OpaquePointer, context: OpaquePointer, config: LlamaConfig) {
        self.model = model
        self.context = context
        self.config = config
        self.batch = llama_batch_init(config.contextSize, 0, 1)
        // Force-unwrap safe: model was validated in create() factory
        let v = llama_model_get_vocab(model)!
        self.vocab = v
        self.sampling = Self.makeSampler(config: config, vocab: v, grammar: nil)
    }

    deinit {
        llama_sampler_free(sampling)
        llama_batch_free(batch)
        llama_model_free(model)
        llama_free(context)
        llama_backend_free()
    }

    // MARK: - Factory

    static func create(from path: String, config: LlamaConfig = .default) throws -> LlamaContext {
        guard FileManager.default.fileExists(atPath: path) else {
            throw LlamaError.modelNotFound(path)
        }

        llama_backend_init()

        var modelParams = llama_model_default_params()
        #if targetEnvironment(simulator)
        // Simulator Metal compute shaders don't support llama.cpp GPU inference
        modelParams.n_gpu_layers = 0
        #else
        modelParams.n_gpu_layers = config.gpuLayers
        #endif

        guard let model = llama_model_load_from_file(path, modelParams) else {
            llama_backend_free()
            throw LlamaError.loadFailed("llama_model_load_from_file returned nil for \(path)")
        }

        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(config.contextSize)
        ctxParams.n_threads = config.threads
        ctxParams.n_threads_batch = config.threads

        guard let context = llama_init_from_model(model, ctxParams) else {
            llama_model_free(model)
            llama_backend_free()
            throw LlamaError.contextCreationFailed
        }

        return LlamaContext(model: model, context: context, config: config)
    }

    // MARK: - Sampler Management

    /// Builds a sampler chain, optionally with GBNF grammar constraint.
    /// Static so it can be called from init (before all stored properties are set).
    private static func makeSampler(config: LlamaConfig, vocab: OpaquePointer, grammar: String? = nil) -> UnsafeMutablePointer<llama_sampler> {
        let sparams = llama_sampler_chain_default_params()
        // Force-unwrap is safe: llama_sampler_chain_init only fails on OOM which is unrecoverable
        let chain = llama_sampler_chain_init(sparams)!

        if let grammar = grammar {
            llama_sampler_chain_add(chain, llama_sampler_init_grammar(vocab, grammar, "root"))
        }

        llama_sampler_chain_add(chain, llama_sampler_init_penalties(64, config.repeatPenalty, 0.0, 0.0))
        llama_sampler_chain_add(chain, llama_sampler_init_temp(config.temperature))
        llama_sampler_chain_add(chain, llama_sampler_init_top_p(config.topP, 1))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

        return chain
    }

    // MARK: - Generation

    func generate(prompt: String, maxTokens: Int = 512, grammar: String? = nil) throws -> String {
        isGeneratingInternal = true
        defer { isGeneratingInternal = false }

        // Build sampler (with optional grammar constraint)
        let sampler: UnsafeMutablePointer<llama_sampler>
        if grammar != nil {
            sampler = Self.makeSampler(config: config, vocab: vocab, grammar: grammar)
        } else {
            sampler = sampling
        }
        defer { if grammar != nil { llama_sampler_free(sampler) } }

        // Tokenize
        var tokens = tokenize(text: prompt, addBos: true)
        guard !tokens.isEmpty else {
            throw LlamaError.tokenizationFailed
        }

        // Truncate if prompt exceeds context size (leave room for generation)
        let maxPromptTokens = Int(config.contextSize) - maxTokens
        if tokens.count > maxPromptTokens {
            tokens = Array(tokens.suffix(maxPromptTokens))
        }

        // Clear KV cache
        llama_memory_clear(llama_get_memory(context), true)

        // Process prompt in batches of batchSize
        let batchSize = Int(config.batchSize)
        var pos: Int32 = 0
        for chunkStart in stride(from: 0, to: tokens.count, by: batchSize) {
            let chunkEnd = min(chunkStart + batchSize, tokens.count)
            let isLastChunk = chunkEnd == tokens.count

            llama_batch_clear(&batch)
            for i in chunkStart..<chunkEnd {
                let isLastToken = isLastChunk && i == chunkEnd - 1
                llama_batch_add(&batch, tokens[i], pos, [0], isLastToken)
                pos += 1
            }

            guard llama_decode(context, batch) == 0 else {
                throw LlamaError.decodeFailed
            }
        }

        // Generate tokens
        var result = ""
        var nCur = pos
        let nMax = Int32(config.contextSize)
        var tempCChars: [CChar] = []

        for _ in 0..<maxTokens {
            let newTokenId = llama_sampler_sample(sampler, context, batch.n_tokens - 1)

            // Check for end of generation
            if llama_vocab_is_eog(vocab, newTokenId) || nCur >= nMax {
                // Flush remaining bytes
                if !tempCChars.isEmpty {
                    result += String(cString: tempCChars + [0])
                }
                break
            }

            // Convert token to text
            let piece = tokenToPiece(token: newTokenId)
            tempCChars.append(contentsOf: piece)

            if let str = String(validatingUTF8: tempCChars + [0]) {
                result += str
                tempCChars.removeAll()
            }

            // Prepare next decode
            llama_batch_clear(&batch)
            llama_batch_add(&batch, newTokenId, nCur, [0], true)
            nCur += 1

            guard llama_decode(context, batch) == 0 else {
                throw LlamaError.decodeFailed
            }
        }

        return result
    }

    func generateStreaming(prompt: String, maxTokens: Int = 512, grammar: String? = nil, onToken: @escaping @Sendable (String) -> Void) throws -> String {
        isGeneratingInternal = true
        defer { isGeneratingInternal = false }

        // Build sampler (with optional grammar constraint)
        let sampler: UnsafeMutablePointer<llama_sampler>
        if grammar != nil {
            sampler = Self.makeSampler(config: config, vocab: vocab, grammar: grammar)
        } else {
            sampler = sampling
        }
        defer { if grammar != nil { llama_sampler_free(sampler) } }

        // Tokenize
        var tokens = tokenize(text: prompt, addBos: true)
        guard !tokens.isEmpty else {
            throw LlamaError.tokenizationFailed
        }

        // Truncate if prompt exceeds context size (leave room for generation)
        let maxPromptTokens = Int(config.contextSize) - maxTokens
        if tokens.count > maxPromptTokens {
            tokens = Array(tokens.suffix(maxPromptTokens))
        }

        // Clear KV cache
        llama_memory_clear(llama_get_memory(context), true)

        // Process prompt in batches of batchSize
        let batchSize = Int(config.batchSize)
        var pos: Int32 = 0
        for chunkStart in stride(from: 0, to: tokens.count, by: batchSize) {
            let chunkEnd = min(chunkStart + batchSize, tokens.count)
            let isLastChunk = chunkEnd == tokens.count

            llama_batch_clear(&batch)
            for i in chunkStart..<chunkEnd {
                let isLastToken = isLastChunk && i == chunkEnd - 1
                llama_batch_add(&batch, tokens[i], pos, [0], isLastToken)
                pos += 1
            }

            guard llama_decode(context, batch) == 0 else {
                throw LlamaError.decodeFailed
            }
        }

        var result = ""
        var nCur = pos
        let nMax = Int32(config.contextSize)
        var tempCChars: [CChar] = []

        for _ in 0..<maxTokens {
            let newTokenId = llama_sampler_sample(sampler, context, batch.n_tokens - 1)

            if llama_vocab_is_eog(vocab, newTokenId) || nCur >= nMax {
                if !tempCChars.isEmpty {
                    let remaining = String(cString: tempCChars + [0])
                    result += remaining
                    onToken(remaining)
                }
                break
            }

            let piece = tokenToPiece(token: newTokenId)
            tempCChars.append(contentsOf: piece)

            if let str = String(validatingUTF8: tempCChars + [0]) {
                result += str
                tempCChars.removeAll()
                onToken(str)
            }

            llama_batch_clear(&batch)
            llama_batch_add(&batch, newTokenId, nCur, [0], true)
            nCur += 1

            guard llama_decode(context, batch) == 0 else {
                throw LlamaError.decodeFailed
            }
        }

        return result
    }

    // MARK: - Model Info

    var modelInfo: String? {
        let buf = UnsafeMutablePointer<CChar>.allocate(capacity: 256)
        buf.initialize(repeating: 0, count: 256)
        defer { buf.deallocate() }

        let nChars = llama_model_desc(model, buf, 256)
        guard nChars > 0 else { return nil }
        return String(cString: buf)
    }

    var contextLength: Int {
        Int(llama_n_ctx(context))
    }

    // MARK: - Private Helpers

    private func tokenize(text: String, addBos: Bool) -> [llama_token] {
        let utf8Count = text.utf8.count
        let maxTokens = utf8Count + (addBos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: maxTokens)
        defer { tokens.deallocate() }

        let count = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(maxTokens), addBos, false)
        guard count >= 0 else { return [] }

        return (0..<Int(count)).map { tokens[$0] }
    }

    private func tokenToPiece(token: llama_token) -> [CChar] {
        let initialSize = 8
        let buf = UnsafeMutablePointer<CChar>.allocate(capacity: initialSize)
        buf.initialize(repeating: 0, count: initialSize)
        defer { buf.deallocate() }

        let nTokens = llama_token_to_piece(vocab, token, buf, Int32(initialSize), 0, false)

        if nTokens < 0 {
            // Buffer too small, retry with correct size
            let needed = Int(-nTokens)
            let bigBuf = UnsafeMutablePointer<CChar>.allocate(capacity: needed)
            bigBuf.initialize(repeating: 0, count: needed)
            defer { bigBuf.deallocate() }

            let actual = llama_token_to_piece(vocab, token, bigBuf, Int32(needed), 0, false)
            return Array(UnsafeBufferPointer(start: bigBuf, count: Int(actual)))
        }

        return Array(UnsafeBufferPointer(start: buf, count: Int(nTokens)))
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
            return "llama.cpp is not available"
        }
    }
}
