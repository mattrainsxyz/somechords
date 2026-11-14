import SwiftUI

struct ChordEditorView: View {
    let onSave: (ChordDraft) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ChordDraft
    @State private var isEditingLabel = false
    @State private var labelInput = ""
    @State private var saveError: String?

    init(chord: Chord? = nil, onSave: @escaping (ChordDraft) throws -> Void) {
        self.onSave = onSave
        _draft = State(initialValue: ChordDraft(chord: chord))
    }

    var body: some View {
        GeometryReader { geometry in
            editorScreen
                .frame(width: geometry.size.height, height: geometry.size.width)
                .rotationEffect(.degrees(90))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    private var editorScreen: some View {
        NavigationStack {
            PianoKeyboardView(selectedNotes: $draft.notes)
                .padding(12)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .accessibilityIdentifier("cancelChordButton")
                        Button("Clear") { draft.notes.removeAll() }
                            .disabled(draft.notes.isEmpty)
                            .accessibilityIdentifier("clearNotesButton")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            labelInput = draft.label
                            isEditingLabel = true
                        } label: {
                            Label("Chord Label", systemImage: draft.normalizedLabel == nil ? "tag" : "tag.fill")
                        }
                        .accessibilityValue(draft.normalizedLabel ?? "No label")
                        .accessibilityIdentifier("chordLabelButton")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save)
                            .disabled(!draft.canSave)
                            .accessibilityIdentifier("saveChordButton")
                    }
                }
                .alert("Chord Label", isPresented: $isEditingLabel) {
                    TextField("Label (optional)", text: $labelInput)
                        .textInputAutocapitalization(.words)
                    Button("Cancel", role: .cancel) { }
                    Button("Done") { draft.label = labelInput }
                } message: {
                    Text("Leave this empty for an unlabeled chord.")
                }
                .alert("Couldn’t Save Chord", isPresented: Binding(
                    get: { saveError != nil },
                    set: { if !$0 { saveError = nil } }
                )) {
                    Button("OK", role: .cancel) { saveError = nil }
                } message: {
                    Text(saveError ?? "Please try again.")
                }
        }
    }

    private func save() {
        guard draft.canSave else { return }
        do {
            try onSave(draft)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview("New chord", traits: .portrait) {
    ChordEditorView { _ in }.tint(.indigo)
}

#Preview("Edit chord · Dark", traits: .portrait) {
    ChordEditorView(chord: Chord(label: "Opening", notes: [41, 48, 52, 55], position: 0)) { _ in }
        .tint(.indigo)
        .preferredColorScheme(.dark)
}

#Preview("Larger text", traits: .portrait) {
    ChordEditorView { _ in }
        .tint(.indigo)
        .environment(\.dynamicTypeSize, .accessibility1)
}
