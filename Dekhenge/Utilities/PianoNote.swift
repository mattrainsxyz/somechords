import Foundation

/// Uses the convention C4 = MIDI 60. The fixed keyboard is F2 through B4.
struct PianoNote: Identifiable, Hashable {
    static let midiRange = 41...71
    static let all = midiRange.map { PianoNote(midi: $0)! }
    static let whiteKeys = all.filter { !$0.isBlack }
    static let blackKeys = all.filter(\.isBlack)

    let midi: Int
    var id: Int { midi }
    var octave: Int { midi / 12 - 1 }
    var pitchClass: Int { midi % 12 }
    var isBlack: Bool { [1, 3, 6, 8, 10].contains(pitchClass) }
    var sharpName: String {
        ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"][pitchClass]
    }
    var flatName: String {
        ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"][pitchClass]
    }
    /// Octaves remain available for data summaries and accessibility, but not key labels.
    var name: String { sharpName + String(octave) }
    var accessibilityName: String {
        let sharp = sharpName.replacingOccurrences(of: "♯", with: " sharp")
        if isBlack {
            let flat = flatName.replacingOccurrences(of: "♭", with: " flat")
            return "\(sharp) \(octave), \(flat) \(octave)"
        }
        return "\(sharp) \(octave)"
    }

    init?(midi: Int) {
        guard Self.midiRange.contains(midi) else { return nil }
        self.midi = midi
    }

    static func names(for selection: Set<Int>) -> String {
        all.filter { selection.contains($0.midi) }.map(\.name).joined(separator: ", ")
    }
}
