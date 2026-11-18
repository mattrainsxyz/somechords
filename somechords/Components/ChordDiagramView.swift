import SwiftUI

struct ChordDiagramView: View {
    let chord: Chord
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(number, format: .number.precision(.integerLength(2)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(chord.label ?? "Chord \(number)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            PianoKeyboardView(selectedNotes: .constant(Set(chord.notes)), isInteractive: false)
                .frame(height: 112)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(.quaternary, lineWidth: 1)
        }
    }
}

#Preview("Saved diagram", traits: .fixedLayout(width: 380, height: 210)) {
    ChordDiagramView(chord: Chord(label: "Opening", notes: [41, 48, 52, 55], position: 0), number: 1)
        .padding(12)
}
