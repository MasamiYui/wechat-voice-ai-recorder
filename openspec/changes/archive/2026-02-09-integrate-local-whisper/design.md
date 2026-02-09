# Design: Local Whisper Integration

## Context
The app currently relies on cloud ASR providers (Tingwu, Volcengine). Users requested a local, offline alternative using Whisper. We will use `WhisperKit` (optimized for CoreML/Apple Silicon) to implement this.

## Goals / Non-Goals

**Goals:**
- Enable offline transcription using local Whisper models.
- Support downloading and managing Whisper models (Tiny, Base, Small, Medium, Large) from within the app.
- Integrate seamlessly into the existing `TranscriptionService` pipeline.
- Provide progress feedback for both model download and transcription.

**Non-Goals:**
- Support for Intel Macs (primary focus is Apple Silicon/CoreML, though it might work via CPU fallback, we won't optimize for it explicitly yet).
- Fine-tuning models.
- Real-time streaming transcription (this design focuses on file-based transcription for recorded meetings).

## Decisions

### 1. ASR Engine: WhisperKit
We will use [WhisperKit](https://github.com/argmaxinc/WhisperKit) because:
- It uses CoreML for hardware acceleration on Apple Silicon (Neural Engine).
- It provides a Swift-native API.
- It is actively maintained by Argmax.

### 2. Service Architecture: `LocalWhisperService`
We will implement `LocalWhisperService` conforming to `TranscriptionService`.

**Task Management:**
Since `TranscriptionService` follows a polling pattern (`createTask` -> `getTaskInfo`), but Whisper runs locally:
- `LocalWhisperService` will maintain an internal thread-safe registry of running tasks (`[String: LocalTask]`).
- `createTask(fileUrl:)`:
  - Generates a UUID.
  - Starts an unstructured `Task` to run WhisperKit inference.
  - Updates the internal status to `.running`.
  - Returns the UUID.
- `getTaskInfo(taskId:)`:
  - Returns the current status from the registry.
  - If finished, returns the result JSON.

**Result Format:**
The result JSON will follow a structure compatible with our `TranscriptParser`. We will add a `LocalWhisperParser` to handle it.
Format:
```json
{
  "segments": [
    { "start": 0.0, "end": 2.5, "text": "Hello world", "speaker": "Speaker 0" }
  ],
  "language": "en"
}
```

### 3. Pipeline Integration
`MeetingPipelineManager` needs modification to support local-only flow.
- Current flow: Transcode -> Upload(OSS) -> CreateTask(OSS URL) -> Poll.
- New flow (if provider == .localWhisper): Transcode -> CreateTask(Local URL) -> Poll.
- We will modify `runPipeline` to skip `UploadNode` if the provider is local.

### 4. Model Management
We need a `ModelManager` (singleton) to:
- List available models.
- Download models (with progress reporting).
- Check if a model is installed.
- Delete models.

**UI:**
- Add "Local Inference" section in `SettingsView`.
- Show model list with "Download" / "Delete" buttons.
- Show download progress.

## Risks / Trade-offs

- **[Risk] App Size / Storage**: Models are large (GBs).
  - *Mitigation*: Models are downloaded on demand to `Application Support`. We provide UI to delete them.
- **[Risk] Performance**: Transcription can be slow and battery-intensive.
  - *Mitigation*: Use `WhisperKit`'s CoreML backend. Run in background task.
- **[Risk] App Sandbox**: Network access for downloading models.
  - *Mitigation*: Ensure `com.apple.security.network.client` entitlement is present (already is for OSS/API).

## Migration Plan
1. Add `WhisperKit` dependency.
2. Implement `ModelManager` and Settings UI.
3. Implement `LocalWhisperService`.
4. Update `MeetingPipelineManager` and `TranscriptParser`.
5. Test with a short audio file.
