import SwiftUI
import ScreenCaptureKit

struct ContentView: View {
    @ObservedObject var settings: SettingsStore
    @StateObject private var recorder: AudioRecorder
    @StateObject private var historyStore = HistoryStore()
    
    // Navigation State
    @State private var selectedSidebarItem: SidebarItem? = .history
    @State private var selectedRecordingMode: RecordingModeItem?
    @State private var selectedImportMode: ImportModeItem?
    @State private var selectedSettingsCategory: SettingsCategory? = .general
    @State private var selectedTask: MeetingTask?
    
    init(settings: SettingsStore) {
        self.settings = settings
        _recorder = StateObject(wrappedValue: AudioRecorder(settings: settings))
    }
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Voice Memo")
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
        } content: {
            ZStack {
                if let item = selectedSidebarItem {
                    switch item {
                    case .recording:
                        List(RecordingModeItem.allCases, selection: $selectedRecordingMode) { mode in
                            NavigationLink(value: mode) {
                                VStack(alignment: .leading) {
                                    Label(mode.title, systemImage: mode.icon)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .navigationTitle("New Recording")
                        
                    case .importAudio:
                        List(ImportModeItem.allCases, selection: $selectedImportMode) { mode in
                            NavigationLink(value: mode) {
                                Label(mode.title, systemImage: mode.icon)
                            }
                        }
                        .navigationTitle("Import")
                        
                    case .history:
                        HistoryListView(store: historyStore, selectedTask: $selectedTask)
                            .navigationTitle("History")
                        
                    case .settings:
                        List(SettingsCategory.allCases, selection: $selectedSettingsCategory) { category in
                            NavigationLink(value: category) {
                                Label(category.title, systemImage: category.icon)
                            }
                        }
                        .navigationTitle("Settings")
                    }
                } else {
                    Text("Select an item")
                        .foregroundColor(.secondary)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
        if let item = selectedSidebarItem {
                switch item {
                case .recording:
                    if let mode = selectedRecordingMode {
                        RecordingView(recorder: recorder, settings: settings, showModeSelection: false)
                            .onAppear {
                                recorder.recordingMode = mode.mode
                            }
                            .onChange(of: mode) { newMode in
                                recorder.recordingMode = newMode.mode
                            }
                    } else {
                        Text("Select a recording mode")
                            .foregroundColor(.secondary)
                    }
                    
                case .importAudio:
                    if let mode = selectedImportMode {
                        switch mode {
                        case .file:
                            ImportView { mode, files in
                                handleImport(mode: mode, files: files)
                            }
                        }
                    } else {
                        Text("Select an import method")
                            .foregroundColor(.secondary)
                    }
                    
                case .history:
                    if let task = selectedTask {
                        ResultView(task: task, settings: settings)
                            .id(task.id)
                    } else {
                        Text("Select a meeting to view details")
                            .foregroundColor(.secondary)
                    }
                    
                case .settings:
                    if let category = selectedSettingsCategory {
                        SettingsView(settings: settings, category: category)
                    } else {
                        Text("Select a settings category")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Welcome to Voice Memo")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onChange(of: recorder.latestTask?.id) { _ in
            Task { await historyStore.refresh() }
        }
    }
    
    private func handleImport(mode: MeetingMode, files: [URL]) {
        Task {
            do {
                let newTask = try await storeImport(mode: mode, files: files)
                await MainActor.run {
                    self.selectedSidebarItem = .history
                    // Small delay to let the UI switch before selecting the task
                    // Ideally we should wait for the view to update, but this is a simple heuristic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.selectedTask = newTask
                    }
                }
            } catch {
                print("Import failed: \(error)")
            }
        }
    }
    
    private func storeImport(mode: MeetingMode, files: [URL]) async throws -> MeetingTask {
        return try await historyStore.importTask(mode: mode, files: files)
    }
}
