import Foundation

/// Value state for an editing session. Changing a draft never changes saved models.
struct ChordDraft {
    var label: String = ""
    var notes: Set<Int> = []

    var normalizedNotes: [Int] {
        notes.filter { PianoNote.midiRange.contains($0) }.sorted()
    }
    var canSave: Bool { !normalizedNotes.isEmpty }
    var normalizedLabel: String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    init(label: String = "", notes: Set<Int> = []) {
        self.label = label
        self.notes = notes
    }

    init(chord: Chord?) {
        label = chord?.label ?? ""
        notes = Set(chord?.notes ?? [])
    }
}
