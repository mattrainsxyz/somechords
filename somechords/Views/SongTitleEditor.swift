import SwiftUI

/// Draft text stays out of SwiftData until the user explicitly saves.
struct SongTitleEditor: View {
    let heading: String
    let onSave: (String) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var saveError: String?
    @FocusState private var titleIsFocused: Bool

    init(heading: String, initialTitle: String = "", onSave: @escaping (String) throws -> Void) {
        self.heading = heading
        self.onSave = onSave
        _title = State(initialValue: initialTitle)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Song title") {
                    TextField("e.g. My First Song", text: $title)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($titleIsFocused)
                        .onSubmit(save)
                        .accessibilityIdentifier("songTitleField")
                }
            }
            .navigationTitle(heading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedTitle.isEmpty)
                        .accessibilityIdentifier("saveSongButton")
                }
            }
            .alert("Couldn’t Save Song", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
            .onAppear { titleIsFocused = true }
        }
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        do {
            try onSave(trimmedTitle)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
