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
        let editingSongID = try createChordSequence(at: url)
        try verifyChordEditingAndDeletion(at: url, id: editingSongID)
        try verifyEditedSequenceReopened(at: url, id: editingSongID)
        print("PASS: create, disk reopen, title trimming, rename, rollback, normalized MIDI notes, positions, cascade deletion, unrelated data preservation, draft cancellation, empty selection rejection, chord create/edit/delete, labels, append positions, cross-song isolation.")
    }

    @MainActor
    static func createAndSave(at url: URL) throws -> UUID {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let song = Song(title: "  My First Song\n")
        context.insert(song)
        context.insert(Song(title: "Unrelated Song"))
        let first = Chord(notes: [59, 48, 52, 48, 41, 42, 40, 60], position: 0, song: song)
        let second = Chord(notes: [57, 50, 53], position: 1, song: song)
        context.insert(first)
        context.insert(second)
        try context.save()
        precondition(song.title == "My First Song")
        precondition(first.notes == [41, 42, 48, 52, 59])
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
        precondition(song.orderedChords.map(\.notes) == [[41, 42, 48, 52, 59], [50, 53, 57]])
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

    @MainActor
    static func createChordSequence(at url: URL) throws -> UUID {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let song = Song(title: "Chord Editing")
        context.insert(song)
        try context.save()
        try song.saveChord(ChordDraft(label: "  Opening  ", notes: [41, 48, 52]), editing: nil, in: context)
        try song.saveChord(ChordDraft(notes: [43, 50, 53]), editing: nil, in: context)
        precondition(song.orderedChords.map(\.position) == [0, 1])
        let first = song.orderedChords[0]
        precondition(first.label == "Opening" && first.notes == [41, 48, 52])
        precondition(song.orderedChords[1].label == nil)
        let firstID = first.id
        let firstPosition = first.position

        var canceledDraft = ChordDraft(chord: first)
        canceledDraft.notes.remove(41)
        canceledDraft.notes.insert(59)
        canceledDraft.label = "Unsaved"
        precondition(first.label == "Opening" && first.notes == [41, 48, 52])
        precondition(!context.hasChanges)

        do {
            try song.saveChord(ChordDraft(notes: [0, 60, 99]), editing: first, in: context)
            preconditionFailure("Empty selections must be rejected")
        } catch Song.ChordEditingError.emptySelection { }
        precondition(song.chords.count == 2 && first.notes == [41, 48, 52])
        let edit = ChordDraft(label: "   ", notes: [42, 49, 59])
        try song.saveChord(edit, editing: first, in: context)
        precondition(first.id == firstID && first.position == firstPosition)
        precondition(first.label == nil && first.notes == [42, 49, 59])
        return song.id
    }

    @MainActor
    static func verifyChordEditingAndDeletion(at url: URL, id: UUID) throws {
        let container = try NotebookStore.makeContainer(at: url)
        let context = container.mainContext
        let songs = try context.fetch(FetchDescriptor<Song>())
        let song = songs.first { $0.id == id }!
        let unrelated = songs.first { $0.id != id }!
        precondition(song.orderedChords.map(\.notes) == [[42, 49, 59], [43, 50, 53]])
        precondition(song.orderedChords[0].label == nil)
        try unrelated.saveChord(ChordDraft(label: "Keep", notes: [47, 55]), editing: nil, in: context)
        let unrelatedChord = unrelated.orderedChords[0]
        do {
            try song.saveChord(ChordDraft(notes: [41]), editing: unrelatedChord, in: context)
            preconditionFailure("Must not edit another song's chord")
        } catch Song.ChordEditingError.wrongSong { }
        do {
            try song.deleteChord(unrelatedChord, in: context)
            preconditionFailure("Must not delete another song's chord")
        } catch Song.ChordEditingError.wrongSong { }
        try song.deleteChord(song.orderedChords[0], in: context)
        precondition(song.orderedChords.map(\.notes) == [[43, 50, 53]])
        try song.saveChord(ChordDraft(label: "Ending", notes: [45, 52, 59]), editing: nil, in: context)
        precondition(song.orderedChords.map(\.position) == [1, 2])
        precondition(unrelatedChord.notes == [47, 55] && unrelatedChord.label == "Keep")
    }

    @MainActor
    static func verifyEditedSequenceReopened(at url: URL, id: UUID) throws {
        let container = try NotebookStore.makeContainer(at: url)
        let songs = try container.mainContext.fetch(FetchDescriptor<Song>())
        let song = songs.first { $0.id == id }!
        precondition(song.orderedChords.map(\.notes) == [[43, 50, 53], [45, 52, 59]])
        precondition(song.orderedChords.map(\.position) == [1, 2])
        precondition(song.orderedChords[1].label == "Ending")
        let unrelated = songs.first { $0.id != id }!
        precondition(unrelated.chords.count == 1 && unrelated.chords[0].label == "Keep")
    }

}
