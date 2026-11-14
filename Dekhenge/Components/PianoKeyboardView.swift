import SwiftUI

/// Binding holds only draft selection. Read-only mode never writes to it.
struct PianoKeyboardView: View {
    @Binding var selectedNotes: Set<Int>
    var isInteractive = true

    var body: some View {
        GeometryReader { geometry in
            let layout = PianoKeyboardLayout(
                availableWidth: geometry.size.width, height: geometry.size.height
            )
            ZStack(alignment: .topLeading) {
                ForEach(PianoNote.whiteKeys) { note in
                    key(note, layout: layout)
                }
                ForEach(PianoNote.blackKeys) { note in
                    key(note, layout: layout)
                }
            }
            .frame(width: layout.width, height: layout.height)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityElement(children: isInteractive ? .contain : .ignore)
            .accessibilityLabel(isInteractive ? "Piano keyboard, F2 through B4" : "Piano diagram, F2 through B4")
            .accessibilityValue(isInteractive ? "" : selectionDescription)
        }
    }

    private var selectionDescription: String {
        let names = PianoNote.names(for: selectedNotes)
        return names.isEmpty ? "No notes selected" : "Selected notes: \(names)"
    }

    @ViewBuilder
    private func key(_ note: PianoNote, layout: PianoKeyboardLayout) -> some View {
        let frame = layout.frame(for: note)
        let selected = selectedNotes.contains(note.midi)
        Group {
            if isInteractive {
                Button {
                    if selected { selectedNotes.remove(note.midi) }
                    else { selectedNotes.insert(note.midi) }
                } label: {
                    PianoKeyFace(note: note, selected: selected, keyWidth: frame.width)
                        .frame(width: frame.width, height: frame.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(note.accessibilityName)
                .accessibilityValue(selected ? "Selected" : "Not selected")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityHint("Double-tap to \(selected ? "deselect" : "select") this note.")
                .accessibilityIdentifier("pianoKey_\(note.midi)")
            } else {
                PianoKeyFace(note: note, selected: selected, keyWidth: frame.width)
                    .frame(width: frame.width, height: frame.height)
            }
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        // Black buttons are above the white buttons, including for hit testing.
        .zIndex(note.isBlack ? 1 : 0)
        .accessibilitySortPriority(Double(72 - note.midi))
    }
}

private struct PianoKeyFace: View {
    let note: PianoNote
    let selected: Bool
    let keyWidth: CGFloat

    private var foreground: Color { selected || note.isBlack ? .white : .black }
    private var fill: Color {
        if selected { return Color(red: 0.29, green: 0.22, blue: 0.75) }
        return note.isBlack ? Color(white: 0.12) : Color(white: 0.98)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: note.isBlack ? 5 : 3)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: note.isBlack ? 5 : 3)
                    .strokeBorder(note.isBlack ? .black : Color(white: 0.45), lineWidth: 1)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 4) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: min(16, max(8, keyWidth * 0.4)), weight: .semibold))
                    }
                    VStack(spacing: 2) {
                        Text(note.sharpName)
                        if note.isBlack { Text(note.flatName) }
                    }
                    .font(.system(size: min(14, max(9, keyWidth * 0.35)), weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 2)
                }
                .foregroundStyle(foreground)
                .padding(.bottom, min(12, max(3, keyWidth * 0.2)))
            }
            .accessibilityHidden(true)
    }
}

#Preview("Interactive keyboard", traits: .fixedLayout(width: 780, height: 280)) {
    @Previewable @State var notes: Set<Int> = [41, 60, 64, 67]
    PianoKeyboardView(selectedNotes: $notes).padding(12)
}

#Preview("Black keys · Dark", traits: .fixedLayout(width: 780, height: 280)) {
    @Previewable @State var notes: Set<Int> = [42, 46, 49, 54, 58, 61, 66, 70]
    PianoKeyboardView(selectedNotes: $notes)
        .padding(12)
        .preferredColorScheme(.dark)
}

#Preview("Wide layout", traits: .fixedLayout(width: 1150, height: 400)) {
    @Previewable @State var notes: Set<Int> = [41, 48, 60, 64, 67, 71]
    PianoKeyboardView(selectedNotes: $notes).padding(12)
}

#Preview("Read only", traits: .fixedLayout(width: 780, height: 280)) {
    PianoKeyboardView(selectedNotes: .constant([42, 60, 71]), isInteractive: false).padding(12)
}
