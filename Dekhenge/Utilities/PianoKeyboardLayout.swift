import Foundation
import CoreGraphics

/// White keys form an uninterrupted row; black keys straddle the appropriate boundaries.
struct PianoKeyboardLayout {
    let whiteKeyWidth: CGFloat
    let height: CGFloat

    init(availableWidth: CGFloat, height: CGFloat = 210) {
        // 72 * 0.62 gives black keys a touch width greater than 44 points.
        whiteKeyWidth = max(72, availableWidth / CGFloat(PianoNote.whiteKeys.count))
        self.height = height
    }

    var width: CGFloat { whiteKeyWidth * CGFloat(PianoNote.whiteKeys.count) }
    var blackKeyWidth: CGFloat { whiteKeyWidth * 0.62 }

    func frame(for note: PianoNote) -> CGRect {
        let precedingWhites = PianoNote.whiteKeys.filter { $0.midi < note.midi }.count
        if note.isBlack {
            return CGRect(
                x: CGFloat(precedingWhites) * whiteKeyWidth - blackKeyWidth / 2,
                y: 0, width: blackKeyWidth, height: height * 0.62
            )
        }
        return CGRect(x: CGFloat(precedingWhites) * whiteKeyWidth, y: 0,
                      width: whiteKeyWidth, height: height)
    }
}
