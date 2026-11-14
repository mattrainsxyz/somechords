import SwiftUI
import SwiftData

@main
struct ChordNotebookApp: App {
    @State private var container: ModelContainer?
    @State private var storageError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    SongLibraryView()
                        .modelContainer(container)
                } else if let storageError {
                    ContentUnavailableView {
                        Label("Unable to Open Notebook", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Your saved notebook has not been replaced or erased. \(storageError)")
                    } actions: {
                        Button("Try Again", action: openNotebook)
                    }
                } else {
                    ProgressView("Opening notebook…")
                }
            }
            .tint(.indigo)
            .task { if container == nil { openNotebook() } }
        }
    }

    private func openNotebook() {
        do {
            container = try NotebookStore.makeContainer()
            storageError = nil
        } catch {
            storageError = error.localizedDescription
        }
    }
}
