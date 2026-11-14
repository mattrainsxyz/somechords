import Foundation
import CoreGraphics

@main
struct KeyboardChecks {
    static func main() {
        precondition(PianoNote.all.map(\.midi) == Array(41...59))
        precondition(PianoNote.whiteKeys.count == 11)
        precondition(PianoNote.blackKeys.count == 8)
        precondition(PianoNote.blackKeys.map(\.midi) == [42, 44, 46, 49, 51, 54, 56, 58])
        precondition(PianoNote.all.map(\.name) == [
            "F2", "F♯2", "G2", "G♯2", "A2", "A♯2", "B2",
            "C3", "C♯3", "D3", "D♯3", "E3", "F3", "F♯3", "G3", "G♯3", "A3", "A♯3", "B3"
        ])
        precondition(PianoNote(midi: 41)?.name == "F2")
        precondition(PianoNote(midi: 48)?.sharpName == "C")
        precondition(PianoNote(midi: 59)?.name == "B3")
        precondition(PianoNote(midi: 49)?.accessibilityName == "C sharp 3, D flat 3")
        precondition(PianoNote(midi: 40) == nil && PianoNote(midi: 60) == nil)
        precondition(PianoNote.names(for: [59, 48, 52, 41, 60]) == "F2, C3, E3, B3")
        precondition(PianoNote.names(for: []) == "")
        let expectedNames = [(49, "C♯", "D♭"), (51, "D♯", "E♭"), (54, "F♯", "G♭"),
                             (56, "G♯", "A♭"), (58, "A♯", "B♭")]
        for (midi, sharp, flat) in expectedNames {
            let note = PianoNote(midi: midi)!
            precondition(note.sharpName == sharp && note.flatName == flat)
        }
        for note in PianoNote.all {
            precondition(!note.sharpName.contains(where: \.isNumber))
            precondition(!note.flatName.contains(where: \.isNumber))
        }

        // Include small phones, rotated phone viewports, and tablet widths.
        for viewport: CGFloat in [296, 320, 393, 544, 680, 768, 850, 1024, 1194] {
            for height: CGFloat in [160, 240, 340, 700] {
                let layout = PianoKeyboardLayout(availableWidth: viewport, height: height)
                precondition(abs(layout.width - viewport) < 0.0001)
                precondition(layout.height == height)
                for (index, note) in PianoNote.whiteKeys.enumerated() {
                    let frame = layout.frame(for: note)
                    precondition(frame.minX == CGFloat(index) * layout.whiteKeyWidth)
                    precondition(frame.maxY == height)
                    precondition(frame.minX >= 0 && frame.maxX <= viewport + 0.0001)
                }
                for note in PianoNote.blackKeys {
                    let frame = layout.frame(for: note)
                    let precedingWhite = PianoNote(midi: note.midi - 1)!
                    let followingWhite = PianoNote(midi: note.midi + 1)!
                    precondition(!precedingWhite.isBlack && !followingWhite.isBlack)
                    let boundary = layout.frame(for: precedingWhite).maxX
                    precondition(abs(frame.midX - boundary) < 0.0001)
                    precondition(frame.minX > 0 && frame.maxX < viewport)
                    precondition(frame.height < height)
                    precondition(frame.intersects(layout.frame(for: precedingWhite)))
                    precondition(frame.intersects(layout.frame(for: followingWhite)))
                }
                for midi in [47, 52] {
                    let boundary = layout.frame(for: PianoNote(midi: midi)!).maxX
                    precondition(!PianoNote.blackKeys.contains {
                        abs(layout.frame(for: $0).midX - boundary) < 0.0001
                    })
                }
            }
        }
        print("PASS: F2–B3, 19 MIDI notes, 11 white/8 black keys, sharp/flat labels without octaves, accessible octave names, all keys fit phone/tablet bounds, correct black-key boundaries.")
    }
}
