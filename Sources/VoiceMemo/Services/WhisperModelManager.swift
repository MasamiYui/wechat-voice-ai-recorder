import Foundation
import WhisperKit
import Combine

class WhisperModelManager: ObservableObject {
    static let shared = WhisperModelManager()
    
    @Published var currentModelName: String = "base"
    @Published var isModelLoading: Bool = false
    @Published var loadingError: String?
    @Published var availableModels: [String] = [
        "tiny", "base", "small", "medium", "large-v3", "distil-large-v3"
    ]
    
    var pipe: WhisperKit?
    
    private init() {}
    
    func loadModel(_ name: String) async throws {
        // If we already have a pipe and the model matches, reuse it.
        // Note: We might want to add a check if the pipe is actually valid/ready.
        if let _ = pipe, currentModelName == name {
            return
        }
        
        await MainActor.run {
            self.isModelLoading = true
            self.loadingError = nil
            self.currentModelName = name
        }
        
        do {
            print("[WhisperModelManager] Loading model: \(name)")
            let config = WhisperKitConfig(model: name)
            // This initializer will download the model if needed.
            let newPipe = try await WhisperKit(config)
            
            await MainActor.run {
                self.pipe = newPipe
                self.isModelLoading = false
            }
            print("[WhisperModelManager] Model loaded successfully")
        } catch {
            print("[WhisperModelManager] Failed to load model: \(error)")
            await MainActor.run {
                self.loadingError = error.localizedDescription
                self.isModelLoading = false
            }
            throw error
        }
    }
    
    /// Pre-check if model is available locally (if API allows).
    /// For now, we rely on loadModel to handle checks.
    func isModelLoaded(_ name: String) -> Bool {
        return pipe != nil && currentModelName == name
    }
}
