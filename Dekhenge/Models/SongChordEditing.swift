import Foundation
import SwiftData

extension Song {
    enum ChordEditingError: LocalizedError {
        case emptySelection
        case wrongSong

        var errorDescription: String? {
            switch self {
            case .emptySelection: "Select at least one note before saving."
            case .wrongSong: "This chord no longer belongs to this song."
            }
        }
    }

    @MainActor
    func saveChord(_ draft: ChordDraft, editing chord: Chord?, in context: ModelContext) throws {
        guard draft.canSave else { throw ChordEditingError.emptySelection }
        if let chord {
            guard chord.song?.id == id, !chord.isDeleted else { throw ChordEditingError.wrongSong }
        }
        let previousDate = updatedAt
        let previousLabel = chord?.label
        let previousNotes = chord?.notes ?? []
        if let chord {
            chord.label = draft.normalizedLabel
            chord.replaceNotes(with: draft.normalizedNotes)
        } else {
            let nextPosition = (chords.map(\.position).max() ?? -1) + 1
            let newChord = Chord(label: draft.normalizedLabel, notes: draft.normalizedNotes,
                                 position: nextPosition, song: self)
            context.insert(newChord)
        }
        updatedAt = .now
        do {
            try context.save()
        } catch {
            context.processPendingChanges()
            context.rollback()
            // Restore observed values as well as the stored transaction on affected runtimes.
            updatedAt = previousDate
            if let chord {
                chord.label = previousLabel
                chord.replaceNotes(with: previousNotes)
            }
            throw error
        }
    }

    @MainActor
    func deleteChord(_ chord: Chord, in context: ModelContext) throws {
        guard chord.song?.id == id, !chord.isDeleted else { throw ChordEditingError.wrongSong }
        let previousDate = updatedAt
        let previousChords = chords
        // Update the observed relationship immediately instead of waiting for store refresh.
        chords.removeAll { $0.id == chord.id }
        context.delete(chord)
        updatedAt = .now
        do {
            try context.save()
        } catch {
            context.processPendingChanges()
            context.rollback()
            chords = previousChords
            updatedAt = previousDate
            throw error
        }
    }
}
