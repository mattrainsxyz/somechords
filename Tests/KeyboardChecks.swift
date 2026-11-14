import Foundation
import CoreGraphics

@main
struct KeyboardChecks {
    static func main() {
        precondition(PianoNote.all.map(\.midi) == Array(48...71))
        precondition(PianoNote.whiteKeys.count == 14)
        precondition(PianoNote.blackKeys.count == 10)
        precondition(PianoNote.blackKeys.map(\.midi) == [49, 51, 54, 56, 58, 61, 63, 66, 68, 70])
        precondition(PianoNote.all.map(\.name) == [
            "C3", "C♯3", "D3", "D♯3", "E3", "F3", "F♯3", "G3", "G♯3", "A3", "A♯3", "B3",
            "C4", "C♯4", "D4", "D♯4", "E4", "F4", "F♯4", "G4", "G♯4", "A4", "A♯4", "B4"
        ])
        precondition(PianoNote(midi: 48)?.name == "C3")
        precondition(PianoNote(midi: 60)?.name == "C4")
        precondition(PianoNote(midi: 71)?.name == "B4")
        precondition(PianoNote(midi: 61)?.accessibilityName == "C sharp 4")
        precondition(PianoNote(midi: 47) == nil && PianoNote(midi: 72) == nil)
        precondition(PianoNote.names(for: [67, 60, 64, 48, 72]) == "C3, C4, E4, G4")
        precondition(PianoNote.names(for: []) == "")

        for viewport: CGFloat in [320, 393, 768, 1024, 1194] {
            let layout = PianoKeyboardLayout(availableWidth: viewport)
            precondition(layout.whiteKeyWidth >= 44 && layout.blackKeyWidth >= 44)
            precondition(layout.width >= viewport)
            precondition(layout.width == (viewport < 1008 ? 1008 : viewport))
            for (index, note) in PianoNote.whiteKeys.enumerated() {
                let frame = layout.frame(for: note)
                precondition(frame.minX == CGFloat(index) * layout.whiteKeyWidth)
                precondition(frame.maxY == layout.height)
            }
            for note in PianoNote.blackKeys {
                let frame = layout.frame(for: note)
                let precedingWhite = PianoNote(midi: note.midi - 1)!
                let followingWhite = PianoNote(midi: note.midi + 1)!
                precondition(!precedingWhite.isBlack && !followingWhite.isBlack)
                let boundary = layout.frame(for: precedingWhite).maxX
                precondition(abs(frame.midX - boundary) < 0.0001)
                precondition(frame.minX > 0 && frame.maxX < layout.width)
                precondition(frame.height < layout.height)
                // A black key covers parts of two white frames, so it must be layered above both.
                precondition(frame.intersects(layout.frame(for: precedingWhite)))
                precondition(frame.intersects(layout.frame(for: followingWhite)))
            }
            // E/F and B/C have no black key at their shared boundary.
            for midi in [52, 59, 64] {
                let boundary = layout.frame(for: PianoNote(midi: midi)!).maxX
                precondition(!PianoNote.blackKeys.contains {
                    abs(layout.frame(for: $0).midX - boundary) < 0.0001
                })
            }
        }
        print("PASS: 24 MIDI notes, octave names, 14 white/10 black keys, selection names, touch widths, adaptive sizing, black-key boundaries, E/F and B/C gaps.")
    }
}
