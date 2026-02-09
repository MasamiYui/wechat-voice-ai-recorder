# Proposal: Integrate Local Whisper ASR

## Why

Users want the ability to perform Automatic Speech Recognition (ASR) locally on their device without relying on cloud services (Tingwu, Volcengine). This offers benefits such as:
- **Privacy**: Audio data never leaves the device.
- **Offline Capability**: Works without an internet connection.
- **Cost Savings**: No per-minute API fees.
- **Low Latency**: Potential for faster processing depending on hardware.

## What Changes

We will integrate **Whisper** (via `WhisperKit` or `SwiftWhisper`) as a new local ASR provider.

- **Dependencies**: Add `WhisperKit` (optimized for Apple Silicon) as a Swift Package dependency.
- **Architecture**:
  - Implement `LocalWhisperService` conforming to `TranscriptionService`.
  - Update `MeetingPipelineManager` to support a "Local" execution path (bypassing mandatory OSS upload for ASR).
  - Update `Settings` to allow selecting "Local Whisper" as the ASR provider.
- **UI/UX**:
  - Add a "Model Manager" in Settings to download/delete Whisper models (Tiny, Base, Small, Medium, Large) to manage disk space.
  - Display local progress (downloading model, transcribing) in the pipeline view.

## Capabilities

### New Capabilities
- `local-asr`: Core capability to run Whisper ASR locally. Includes model management and inference.

### Modified Capabilities
- `pipeline-orchestration`: Update the pipeline to handle local-only workflows (skip OSS upload requirement for ASR step).

## Impact

- **App Size**: The app binary will grow slightly due to the library, but models will be downloaded on demand (hundreds of MB to GBs).
- **Performance**: High CPU/GPU usage during transcription. Needs to be managed to avoid freezing the UI (already handled by async/await, but need careful resource management).
- **Codebase**:
  - `MeetingPipelineManager` needs to handle `file://` URLs for the local provider.
  - `TranscriptionService` protocol is async/task-based; Local Whisper is synchronous-ish but can be wrapped in an async task.

## Key Decisions
- **Library**: Use **WhisperKit** (by Argmax) for best performance on Apple Silicon (CoreML).
- **Storage**: Models stored in `Application Support` directory.
