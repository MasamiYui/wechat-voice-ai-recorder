## ADDED Requirements

### Requirement: Manage Whisper Models
The system SHALL allow users to view available Whisper models, download them, and delete them to manage disk space.

#### Scenario: List available models
- **WHEN** user navigates to "Local Inference" settings
- **THEN** system displays list of models (Tiny, Base, Small, Medium, Large) with their status (Not Downloaded, Downloading, Installed).

#### Scenario: Download a model
- **WHEN** user clicks "Download" on a model
- **THEN** system starts downloading the model and updates the UI with progress percentage.

#### Scenario: Delete a model
- **WHEN** user clicks "Delete" on an installed model
- **THEN** system removes the model files from disk and updates status to "Not Downloaded".

### Requirement: Local Transcription
The system SHALL provide an ASR service implementation that runs Whisper locally using the installed model.

#### Scenario: Transcribe audio locally
- **WHEN** a transcription task is created with `LocalWhisperService`
- **THEN** system performs inference locally and returns the transcript.

#### Scenario: Missing model error
- **WHEN** a transcription task is created but the selected model is not installed
- **THEN** system throws a specific error prompting the user to download the model.

### Requirement: Progress Feedback
The system SHALL report progress during model downloading and transcription.

#### Scenario: Transcription progress
- **WHEN** transcription is running
- **THEN** system updates the task status (e.g. "Processing...") but detailed percentage might not be available via current `TranscriptionService` protocol (future improvement).
