import SwiftUI

/// Binding holds only draft selection. Read-only mode never writes to it.
struct PianoKeyboardView: View {
    @Binding var selectedNotes: Set<Int>
    var isInteractive = true

    private let keyboardHeight: CGFloat = 210

    var body: some View {
        GeometryReader { geometry in
            let layout = PianoKeyboardLayout(availableWidth: geometry.size.width)
            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    ForEach(PianoNote.whiteKeys) { note in
                        key(note, layout: layout)
                    }
                    ForEach(PianoNote.blackKeys) { note in
                        key(note, layout: layout)
                    }
                }
                .frame(width: layout.width, height: keyboardHeight)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityElement(children: isInteractive ? .contain : .ignore)
            .accessibilityLabel(isInteractive ? "Piano keyboard, C3 through B4" : "Piano diagram, C3 through B4")
            .accessibilityValue(isInteractive ? "" : selectionDescription)
        }
        // Space below the keys keeps the scroll indicator clear of their labels.
        .frame(height: keyboardHeight + 16)
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
                    PianoKeyFace(note: note, selected: selected)
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
                PianoKeyFace(note: note, selected: selected)
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
                VStack(spacing: 7) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(note.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(foreground)
                .padding(.bottom, 12)
            }
            .accessibilityHidden(true)
    }
}

#Preview("Interactive") {
    @Previewable @State var notes: Set<Int> = [60, 64, 67]
    PianoKeyboardView(selectedNotes: $notes).padding()
}

#Preview("Read only") {
    PianoKeyboardView(selectedNotes: .constant([49, 60, 71]), isInteractive: false).padding()
}
