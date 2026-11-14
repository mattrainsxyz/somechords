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
            PianoKeyboardView(selectedNotes: $selectedNotes)
                .padding(12)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear") { selectedNotes.removeAll() }
                            .disabled(selectedNotes.isEmpty)
                            .accessibilityIdentifier("clearNotesButton")
                    }
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

#Preview("Larger text", traits: .portrait) {
    KeyboardSelectionView()
        .tint(.indigo)
        .environment(\.dynamicTypeSize, .accessibility1)
}
