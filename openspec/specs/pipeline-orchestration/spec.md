# Spec: Pipeline Orchestration

## Purpose
Manage the execution flow of meeting processing tasks, coordinating between audio processing, upload, and transcription steps.

## Requirements

### Requirement: Local Execution Path
The pipeline manager SHALL support a local execution path that skips OSS upload when a local ASR provider is selected.

#### Scenario: Run pipeline with Local Whisper
- **WHEN** user starts the pipeline and `Settings.asrProvider` is `localWhisper`
- **THEN** system skips the "Upload Mixed" step and passes the local file path to the transcription service.

#### Scenario: Run pipeline with Cloud Provider
- **WHEN** user starts the pipeline and `Settings.asrProvider` is `tingwu` or `volcengine`
- **THEN** system performs "Upload Mixed" step and passes the OSS URL to the transcription service.
