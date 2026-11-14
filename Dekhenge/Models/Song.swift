import Foundation
import SwiftData

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Chord.song)
    var chords: [Chord] = []

    init(title: String, now: Date = .now) {
        id = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        createdAt = now
        updatedAt = now
    }

    var orderedChords: [Chord] {
        chords.sorted { $0.position < $1.position }
    }
}
