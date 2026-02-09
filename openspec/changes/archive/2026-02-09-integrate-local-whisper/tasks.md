## 1. Dependencies & Infrastructure

- [x] 1.1 Add `WhisperKit` dependency to project (via Xcode/SPM).
- [x] 1.2 Update `SettingsStore` to include `ASRProvider.localWhisper` case.
- [x] 1.3 Create `WhisperModelManager` for downloading and managing models.

## 2. Core Service Implementation

- [x] 2.1 Create `LocalWhisperService` class implementing `TranscriptionService`.
- [x] 2.2 Implement `LocalWhisperParser` in `TranscriptParser.swift` to handle WhisperKit output.
- [x] 2.3 Connect `LocalWhisperService` to `WhisperKit` for inference.

## 3. Pipeline Integration

- [x] 3.1 Update `MeetingPipelineManager` to initialize `LocalWhisperService` when selected.
- [x] 3.2 Update `MeetingPipelineManager.runPipeline` to skip OSS upload for local provider.

## 4. UI Implementation

- [x] 4.1 Create `LocalInferenceSettingsView` for model management.
- [x] 4.2 Add "Local Inference" section to `SettingsView`.

## 5. Verification

- [x] 5.1 Verify model download functionality.
- [x] 5.2 Verify local transcription pipeline.
