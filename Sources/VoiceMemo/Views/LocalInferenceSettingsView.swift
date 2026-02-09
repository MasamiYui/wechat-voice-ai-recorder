import SwiftUI

struct LocalInferenceSettingsView: View {
    @ObservedObject var modelManager = WhisperModelManager.shared
    @ObservedObject var settings: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Local Whisper Models")
                .font(.headline)
            
            Text("Models are downloaded automatically when selected. Larger models are more accurate but slower.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(modelManager.availableModels, id: \.self) { modelName in
                HStack {
                    VStack(alignment: .leading) {
                        Text(modelName)
                            .fontWeight(settings.whisperModel == modelName ? .bold : .regular)
                    }
                    
                    Spacer()
                    
                    if modelManager.isModelLoading && settings.whisperModel == modelName {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if settings.whisperModel == modelName {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Select") {
                            settings.whisperModel = modelName
                            Task {
                                try? await modelManager.loadModel(modelName)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
            
            if let error = modelManager.loadingError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
