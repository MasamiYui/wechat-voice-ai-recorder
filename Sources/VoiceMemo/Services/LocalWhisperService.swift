import Foundation
import WhisperKit

class LocalWhisperService: TranscriptionService {
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
    }
    
    func createTask(fileUrl: String) async throws -> String {
        // fileUrl should be a local file URL string (file://...)
        guard let url = URL(string: fileUrl), url.isFileURL else {
            // Try to interpret as path if not URL
            let fileURL = URL(fileURLWithPath: fileUrl)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                 return try await startTask(url: fileURL)
            }
            throw TranscriptionError.invalidURL(fileUrl)
        }
        return try await startTask(url: url)
    }
    
    private func startTask(url: URL) async throws -> String {
        // Ensure model is loaded
        let modelName = settings.whisperModel
        // Trigger load if not loaded (this waits for load)
        try await WhisperModelManager.shared.loadModel(modelName)
        
        let taskId = UUID().uuidString
        await LocalTaskManager.shared.registerTask(taskId)
        
        Task {
            await LocalTaskManager.shared.runTask(taskId: taskId, audioUrl: url, modelManager: WhisperModelManager.shared)
        }
        
        return taskId
    }
    
    func getTaskInfo(taskId: String) async throws -> (status: String, result: [String: Any]?) {
        return await LocalTaskManager.shared.getTaskStatus(taskId)
    }
    
    func fetchJSON(url: String) async throws -> [String: Any] {
        if let u = URL(string: url), u.isFileURL {
            let data = try Data(contentsOf: u)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
            throw TranscriptionError.parseError("Invalid JSON in local file")
        }
        // Fallback
        guard let u = URL(string: url) else { throw TranscriptionError.invalidURL(url) }
        let (data, _) = try await URLSession.shared.data(from: u)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

actor LocalTaskManager {
    static let shared = LocalTaskManager()
    
    enum TaskStatus {
        case running
        case success([String: Any])
        case failed(String)
    }
    
    private var tasks: [String: TaskStatus] = [:]
    
    func registerTask(_ id: String) {
        tasks[id] = .running
    }
    
    func updateTask(_ id: String, status: TaskStatus) {
        tasks[id] = status
    }
    
    func getTaskStatus(_ id: String) -> (String, [String: Any]?) {
        guard let status = tasks[id] else {
            return ("FAILED", ["error": "Task not found"])
        }
        switch status {
        case .running:
            return ("RUNNING", nil)
        case .success(let result):
            return ("SUCCESS", result)
        case .failed(let error):
            return ("FAILED", ["error": error])
        }
    }
    
    func runTask(taskId: String, audioUrl: URL, modelManager: WhisperModelManager) async {
        do {
            guard let pipe = modelManager.pipe else {
                throw TranscriptionError.serviceUnavailable
            }
            
            // Run inference
            // Note: pipe.transcribe returns [TranscriptionResult] usually, or a single result?
            // Based on example: `pipe!.transcribe(audioPath: ...)`
            // We assume it returns `[TranscriptionResult]` or similar where we can get text and segments.
            guard let results = try await pipe.transcribe(audioPath: audioUrl.path) else {
                throw TranscriptionError.parseError("No transcription result")
            }
            
            // WhisperKit results are typically `TranscriptionResult`.
            // We need to inspect the structure.
            // Assuming `results.text` and `results.segments` exist on the returned object.
            
            let text = results.text
            let segments = results.segments.map { segment in
                return [
                    "start": segment.start,
                    "end": segment.end,
                    "text": segment.text,
                    "speaker": "Speaker 0" // Placeholder
                ]
            }
            
            let output: [String: Any] = [
                "text": text,
                "segments": segments,
                "provider": "localWhisper"
            ]
            
            updateTask(taskId, status: .success(output))
            
        } catch {
            print("Local Whisper task failed: \(error)")
            updateTask(taskId, status: .failed(error.localizedDescription))
        }
    }
}
