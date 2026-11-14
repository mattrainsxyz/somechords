import Foundation
import SwiftData

/// One local store shared by every view. Tests supply a separate on-disk URL.
@MainActor
enum NotebookStore {
    static func makeContainer(at url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([Song.self, Chord.self])
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        let container = try ModelContainer(for: schema, configurations: [configuration])
        // All mutations explicitly save and report failure before dismissing the UI.
        container.mainContext.autosaveEnabled = false
        return container
    }
}
