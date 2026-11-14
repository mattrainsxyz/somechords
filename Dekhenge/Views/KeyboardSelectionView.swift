import SwiftUI

/// Phase 2's selection surface. Phase 3 will reuse the keyboard in the chord editor.
struct KeyboardSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNotes: Set<Int> = []

    var body: some View {
        GeometryReader { geometry in
            keyboardScreen
                // Lay out using the rotated dimensions before transforming the screen.
                .frame(width: geometry.size.height, height: geometry.size.width)
                .rotationEffect(.degrees(90))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    private var keyboardScreen: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find your notes")
                            .font(.title2.bold())
                        Text("Tap any combination of keys. Tap again to deselect. Swipe across the keyboard to reach both octaves.")
                            .foregroundStyle(.secondary)
                    }
                    PianoKeyboardView(selectedNotes: $selectedNotes)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Selected notes").font(.headline)
                            Spacer()
                            Button("Clear") { selectedNotes.removeAll() }
                                .disabled(selectedNotes.isEmpty)
                                .accessibilityIdentifier("clearNotesButton")
                        }
                        Text(selectedNotes.isEmpty ? "No notes selected" : PianoNote.names(for: selectedNotes))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(selectedNotes.isEmpty ? .secondary : .primary)
                            .accessibilityIdentifier("selectedNoteNames")
                        Text("C3–B4 · Middle C is C4")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text("This is a space to try note selections. Selections are temporary and are cleared when you close it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Piano Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Keyboard screen", traits: .portrait) {
    KeyboardSelectionView()
        .tint(.indigo)
}

#Preview("Dark appearance", traits: .portrait) {
    KeyboardSelectionView()
        .tint(.indigo)
        .preferredColorScheme(.dark)
}

#Preview("Landscape", traits: .landscapeRight) {
    KeyboardSelectionView()
        .tint(.indigo)
}

#Preview("Larger text", traits: .portrait) {
    KeyboardSelectionView()
        .tint(.indigo)
        .environment(\.dynamicTypeSize, .accessibility1)
}
