import Foundation
import SwiftData

extension Song {
    enum ChordEditingError: LocalizedError {
        case emptySelection
        case wrongSong
        case invalidOrder

        var errorDescription: String? {
            switch self {
            case .emptySelection: "Select at least one note before saving."
            case .wrongSong: "This chord no longer belongs to this song."
            case .invalidOrder: "The chord sequence changed. Please try moving the chord again."
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
        let previousChords = chords
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
            // Detach a rejected insertion before rollback invalidates its backing data.
            if chord == nil { chords = previousChords }
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
        let previousPositions = previousChords.map { ($0, $0.position) }
        // Update the observed relationship immediately instead of waiting for store refresh.
        chords.removeAll { $0.id == chord.id }
        context.delete(chord)
        for (position, remaining) in orderedChords.enumerated() {
            remaining.position = position
        }
        updatedAt = .now
        do {
            try context.save()
        } catch {
            context.processPendingChanges()
            context.rollback()
            chords = previousChords
            for (chord, position) in previousPositions { chord.position = position }
            updatedAt = previousDate
            throw error
        }
    }

    /// Save a complete permutation so a stale or partial UI request cannot drop chords.
    @MainActor
    func reorderChords(_ orderedIDs: [UUID], in context: ModelContext) throws {
        let current = orderedChords
        guard orderedIDs.count == current.count,
              Set(orderedIDs).count == orderedIDs.count,
              Set(orderedIDs) == Set(current.map(\.id)) else {
            throw ChordEditingError.invalidOrder
        }
        guard orderedIDs != current.map(\.id) || current.enumerated().contains(where: {
            $0.element.position != $0.offset
        }) else { return }
        let byID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        let previousPositions = current.map { ($0, $0.position) }
        let previousDate = updatedAt
        for (position, id) in orderedIDs.enumerated() {
            byID[id]?.position = position
        }
        updatedAt = .now
        do {
            try context.save()
        } catch {
            context.processPendingChanges()
            context.rollback()
            for (chord, position) in previousPositions { chord.position = position }
            updatedAt = previousDate
            throw error
        }
    }

}
