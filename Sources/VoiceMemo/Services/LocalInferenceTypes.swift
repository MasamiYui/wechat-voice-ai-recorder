import Foundation

struct SpeakerSegment: Codable, Equatable {
    let start: Double
    let end: Double
    let speakerId: String
}

struct TranscriptSegment: Codable, Equatable {
    let start: Double
    let end: Double
    let text: String
}

enum InferenceResult {
    case asr(ASRResult)
    case diarization(DiarizationResult)
}

struct ASRResult {
    let text: String
    let segments: [TranscriptSegment]
}

struct DiarizationResult {
    let segments: [SpeakerSegment]
}

struct FusedResult {
    let text: String
    let segments: [FusedSegment]
}

struct FusedSegment {
    let start: Double
    let end: Double
    let text: String
    let speaker: String
}

enum InferenceError: Error, LocalizedError {
    case partialFailure
    case modelNotLoaded
    case processingFailed
    case emptyAudio
    case transcriptionEmpty
    
    var errorDescription: String? {
        switch self {
        case .partialFailure: return "Inference failed partially"
        case .modelNotLoaded: return "Whisper model not loaded"
        case .processingFailed: return "Audio preprocessing failed"
        case .emptyAudio: return "Audio file is empty or too short"
        case .transcriptionEmpty: return "Transcription returned no text"
        }
    }
}
