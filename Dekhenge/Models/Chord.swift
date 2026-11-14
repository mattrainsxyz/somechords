import Foundation
import SwiftData

@Model
final class Chord {
    @Attribute(.unique) var id: UUID
    var label: String?
    private(set) var notes: [Int]
    var position: Int
    var song: Song?

    init(label: String? = nil, notes: [Int], position: Int, song: Song? = nil) {
        id = UUID()
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.label = trimmed?.isEmpty == false ? trimmed : nil
        self.notes = Self.normalized(notes)
        self.position = position
        self.song = song
    }

    func replaceNotes(with notes: [Int]) {
        self.notes = Self.normalized(notes)
    }

    private static func normalized(_ notes: [Int]) -> [Int] {
        Array(Set(notes.filter { (48...71).contains($0) })).sorted()
    }
}
