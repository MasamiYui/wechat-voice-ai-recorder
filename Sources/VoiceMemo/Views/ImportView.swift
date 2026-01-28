import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var selectedMode: MeetingMode = .mixed
    @State private var file1URL: URL?
    @State private var file2URL: URL?
    @State private var isImporting = false
    @State private var errorMessage: String?
    
    var onImport: (MeetingMode, [URL]) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Audio")
                .font(.largeTitle)
                .padding()
            
            Form {
                Section(header: Text("Configuration")) {
                    Picker("Mode", selection: $selectedMode) {
                        Text("Mixed Mode (Single File)").tag(MeetingMode.mixed)
                        Text("Separated Mode (Dual Files)").tag(MeetingMode.separated)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedMode == .mixed {
                        Text("Mixed mode uses a single audio file for the entire meeting.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Separated mode requires two files: one for Speaker 1 (Local) and one for Speaker 2 (Remote).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Files")) {
                    if selectedMode == .mixed {
                        FilePickerRow(title: "Audio File", url: $file1URL)
                    } else {
                        FilePickerRow(title: "Speaker 1 (Local)", url: $file1URL)
                        FilePickerRow(title: "Speaker 2 (Remote)", url: $file2URL)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 600)
            
            Button(action: doImport) {
                if isImporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Start Import")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canImport || isImporting)
            .frame(maxWidth: 300)
            
            Spacer()
        }
        .padding()
    }
    
    private var canImport: Bool {
        if selectedMode == .mixed {
            return file1URL != nil
        } else {
            return file1URL != nil && file2URL != nil
        }
    }
    
    private func doImport() {
        var files: [URL] = []
        if let f1 = file1URL { files.append(f1) }
        if selectedMode == .separated, let f2 = file2URL { files.append(f2) }
        
        isImporting = true
        errorMessage = nil
        
        // Slight delay to allow UI update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onImport(selectedMode, files)
            isImporting = false
            // Reset fields? Maybe not, user might want to import another.
        }
    }
}

struct FilePickerRow: View {
    let title: String
    @Binding var url: URL?
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)
            
            if let url = url {
                HStack {
                    Image(systemName: "doc.audio")
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .help(url.path)
            } else {
                Text("No file selected")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
            
            Button("Select...") {
                selectFile()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Select"
        
        panel.begin { response in
            if response == .OK {
                self.url = panel.url
            }
        }
    }
}
