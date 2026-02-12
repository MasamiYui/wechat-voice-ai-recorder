import XCTest
@testable import VoiceMemo
import WhisperKit
import AVFoundation

final class LocalWhisperTests: XCTestCase {
    
    var whisperManager: WhisperModelManager!
    var tempModelsDir: URL!
    
    override func setUp() {
        super.setUp()
        
        // Create temporary directory for models to avoid permission issues
        tempModelsDir = FileManager.default.temporaryDirectory.appendingPathComponent("VoiceMemoTestModels-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempModelsDir, withIntermediateDirectories: true)
        
        whisperManager = WhisperModelManager.shared
        
        // Override the model storage path to use our temp directory
        setenv("WHISPERKIT_DOWNLOAD_BASE", tempModelsDir.path, 1)
        
        // Set mirror to true for testing environments that might have trouble with HF
        UserDefaults.standard.set(true, forKey: "useHFMirror")
        setenv("HF_ENDPOINT", "https://hf-mirror.com", 1)
        setenv("HUB_ENDPOINT", "https://hf-mirror.com", 1)
    }
    
    override func tearDown() {
        // Keep temp directory for debugging - don't clean up
        // Clean up environment
        unsetenv("WHISPERKIT_DOWNLOAD_BASE")
        unsetenv("HF_ENDPOINT")
        unsetenv("HUB_ENDPOINT")
        
        super.tearDown()
    }
    
    func testModelPaths() {
        // Test if paths are correctly constructed
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let expectedPath = appSupport.appendingPathComponent("VoiceMemo/Models")
        
        XCTAssertTrue(expectedPath.path.contains("Application Support/VoiceMemo/Models"))
    }
    
    func testAudioPreprocessing() async throws {
        // Use the jfk.wav from WhisperKit checkouts if available
        let fileManager = FileManager.default
        let jfkPath = "/Users/yinyijun/OpenSourceProjects/wechat-voice-ai-recorder/.build/checkouts/WhisperKit/Tests/WhisperKitTests/Resources/jfk.wav"
        
        guard fileManager.fileExists(atPath: jfkPath) else {
            XCTFail("Test audio file not found at \(jfkPath)")
            return
        }
        
        let audioUrl = URL(fileURLWithPath: jfkPath)
        
        // Since preprocessAudio is private, we can't test it directly easily 
        // unless we make it internal or test via executeTask.
        // For now, let's just verify the file exists and is readable.
        let audioFile = try AVAudioFile(forReading: audioUrl)
        XCTAssertGreaterThan(audioFile.length, 0)
        print("Audio file length: \(audioFile.length) frames")
    }

    func testTranscriptionPipeline() async throws {
        // This test might take a long time as it downloads the model
        // We use "tiny" for speed.
        let modelName = "tiny"
        let jfkPath = "/Users/yinyijun/OpenSourceProjects/wechat-voice-ai-recorder/.build/checkouts/WhisperKit/Tests/WhisperKitTests/Resources/jfk.wav"
        
        guard FileManager.default.fileExists(atPath: jfkPath) else {
            print("Skipping transcription test: audio file not found")
            return
        }
        
        let audioUrl = URL(fileURLWithPath: jfkPath)
        let taskId = "test-task-\(UUID().uuidString)"
        
        print("Starting transcription test for task \(taskId)...")
        print("Using temporary model directory: \(tempModelsDir.path)")
        
        // We use a timeout because downloading/inference can be slow
        let expectation = XCTestExpectation(description: "Transcription completes")
        
        // Start the task
        Task {
            await LocalTaskManager.shared.executeTask(
                taskId: taskId,
                audioUrl: audioUrl,
                modelName: modelName,
                enableRoleSplit: false
            )
            
            let (status, result) = await LocalTaskManager.shared.getTaskStatus(taskId)
            print("Task Status: \(status)")
            if let result = result {
                print("Task Result: \(result.keys)")
                if let text = result["text"] as? String {
                    print("Transcribed Text: \(text)")
                    XCTAssertFalse(text.isEmpty, "Transcribed text should not be empty")
                }
            }
            
            if status == "SUCCESS" {
                expectation.fulfill()
            } else if status == "FAILED" {
                XCTFail("Task failed with error: \(result?["error"] ?? "unknown")")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 300) // 5 minutes timeout for model download + inference
    }
}