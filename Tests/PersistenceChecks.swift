import Foundation
import SwiftData

@main
struct PersistenceChecks {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DekhengeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notebook.store")
        let songID = try createAndSave(at: url)
        try verifyReopenAndRename(at: url, id: songID)
        try verifyRenameAndDelete(at: url, id: songID)
        try verifyDeletionPersisted(at: url)
        print("PASS: create, disk reopen, title trimming, rename, rollback, normalized MIDI notes, positions, cascade deletion, unrelated data preservation.")
    }

    @MainActor
    static func createAndSave(at url: URL) throws -> UUID {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let song = Song(title: "  My First Song\n")
        context.insert(song)
        context.insert(Song(title: "Unrelated Song"))
        let first = Chord(notes: [67, 60, 64, 60, 47, 72], position: 0, song: song)
        let second = Chord(notes: [69, 62, 65], position: 1, song: song)
        context.insert(first)
        context.insert(second)
        try context.save()
        precondition(song.title == "My First Song")
        precondition(first.notes == [60, 64, 67])
        precondition(song.chords.count == 2)
        return song.id
    }

    @MainActor
    static func verifyReopenAndRename(at url: URL, id: UUID) throws {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let songs = try context.fetch(FetchDescriptor<Song>())
        precondition(songs.count == 2)
        let song = songs.first { $0.id == id }!
        precondition(song.title == "My First Song")
        precondition(song.orderedChords.map(\.notes) == [[60, 64, 67], [62, 65, 69]])
        precondition(song.chords.allSatisfy { $0.song?.id == id })
        song.title = "Discarded edit"
        context.processPendingChanges()
        context.rollback()
        precondition(!context.hasChanges)
        let independentContext = ModelContext(container)
        let persistedSong = try independentContext.fetch(FetchDescriptor<Song>()).first { $0.id == id }!
        precondition(persistedSong.title == "My First Song")
        // Restore observed values explicitly, matching the UI's failed-rename recovery.
        song.title = "My First Song"
        song.title = "Renamed Song"
        song.updatedAt = song.createdAt.addingTimeInterval(60)
        try context.save()
    }

    @MainActor
    static func verifyRenameAndDelete(at url: URL, id: UUID) throws {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let song = try context.fetch(FetchDescriptor<Song>()).first { $0.id == id }!
        precondition(song.title == "Renamed Song")
        precondition(song.updatedAt > song.createdAt)
        context.delete(song)
        try context.save()
        precondition(tryCountChords(context) == 0)
    }

    @MainActor
    static func tryCountChords(_ context: ModelContext) -> Int {
        // A thrown fetch must fail this test rather than appear to be an empty store.
        try! context.fetchCount(FetchDescriptor<Chord>())
    }

    @MainActor
    static func verifyDeletionPersisted(at url: URL) throws {
        let container = try NotebookStore.makeContainer(at: url)
        let songs = try container.mainContext.fetch(FetchDescriptor<Song>())
        precondition(songs.count == 1 && songs[0].title == "Unrelated Song")
        precondition(tryCountChords(container.mainContext) == 0)
    }
}
