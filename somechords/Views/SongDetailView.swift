import SwiftUI
import SwiftData

struct SongDetailView: View {
    let song: Song
    @Environment(\.modelContext) private var modelContext
    @State private var editorRequest: EditorRequest?
    @State private var chordToDelete: Chord?
    @State private var isConfirmingDeletion = false
    @State private var operationError: String?
    @State private var editMode: EditMode = .inactive

    private struct EditorRequest: Identifiable {
        let id = UUID()
        let chord: Chord?
    }

    var body: some View {
        List {
            ForEach(Array(song.orderedChords.enumerated()), id: \.element.id) { index, chord in
                chordRow(chord, at: index)
            }
            .onMove(perform: moveChords)
            .moveDisabled(song.chords.count < 2)
        }
        .environment(\.editMode, $editMode)
        .onChange(of: song.chords.count) { _, count in
            if count < 2 { editMode = .inactive }
        }
        .listStyle(.plain)
        .contentMargins(.top, 16, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 850)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if song.chords.isEmpty {
                EmptyStateActionView(systemImage: "pianokeys", title: "New Chord") {
                    editorRequest = EditorRequest(chord: nil)
                }
            }
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if song.chords.count > 1 || editMode.isEditing {
                    Button(editMode.isEditing ? "Done" : "Reorder") {
                        withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                    }
                    .accessibilityIdentifier("reorderChordsButton")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("New Chord", systemImage: "plus") {
                    editorRequest = EditorRequest(chord: nil)
                }
                .accessibilityIdentifier("addChordButton")
            }
        }
        .fullScreenCover(item: $editorRequest) { request in
            ChordEditorView(chord: request.chord) { draft in
                try song.saveChord(draft, editing: request.chord, in: modelContext)
            }
            .tint(.blue)
        }
        .alert("Delete Chord?", isPresented: $isConfirmingDeletion, presenting: chordToDelete) { chord in
            Button("Delete Chord", role: .destructive) { deleteChord(chord) }
            Button("Cancel", role: .cancel) { chordToDelete = nil }
        } message: { _ in
            Text("This chord will be deleted from the song.")
        }
        .alert("Couldn’t Update Song", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("OK", role: .cancel) { operationError = nil }
        } message: {
            Text(operationError ?? "Please try again.")
        }
    }

    private var chordAccessibilityHint: String {
        editMode.isEditing
            ? "Use the reorder handle or the Move Earlier and Move Later actions."
            : "Double-tap to edit. More actions include moving or deleting this chord."
    }

    private func chordRow(_ chord: Chord, at index: Int) -> some View {
        Button {
            if !editMode.isEditing { editorRequest = EditorRequest(chord: chord) }
        } label: {
            ChordDiagramView(chord: chord, number: index + 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(chord.label ?? "Chord \(index + 1)"), \(index + 1) of \(song.chords.count)")
        .accessibilityHint(Text(chordAccessibilityHint))
        .accessibilityValue(PianoNote.names(for: Set(chord.notes)))
        .accessibilityIdentifier("chordDiagram_\(chord.id)")
        .listRowInsets(EdgeInsets(top: index == 0 ? 0 : 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) { requestDeletion(of: chord) }
        }
        .contextMenu {
            Button("Edit Chord", systemImage: "pencil") {
                editorRequest = EditorRequest(chord: chord)
            }
            Button("Move Earlier", systemImage: "arrow.up") { moveChord(chord, by: -1) }
                .disabled(index == 0)
            Button("Move Later", systemImage: "arrow.down") { moveChord(chord, by: 1) }
                .disabled(index == song.chords.count - 1)
            Button("Delete Chord", systemImage: "trash", role: .destructive) {
                requestDeletion(of: chord)
            }
        }
        .accessibilityActions {
            if index > 0 {
                Button("Move Earlier") { moveChord(chord, by: -1) }
            }
            if index < song.chords.count - 1 {
                Button("Move Later") { moveChord(chord, by: 1) }
            }
            Button("Edit Chord") { editorRequest = EditorRequest(chord: chord) }
            Button("Delete Chord") { requestDeletion(of: chord) }
        }
    }

    private func moveChords(from offsets: IndexSet, to destination: Int) {
        var sequence = song.orderedChords
        sequence.move(fromOffsets: offsets, toOffset: destination)
        saveOrder(sequence.map(\.id))
    }

    private func moveChord(_ chord: Chord, by direction: Int) {
        var sequence = song.orderedChords
        guard let index = sequence.firstIndex(where: { $0.id == chord.id }) else { return }
        let destination = index + direction
        guard sequence.indices.contains(destination) else { return }
        sequence.swapAt(index, destination)
        saveOrder(sequence.map(\.id))
    }

    private func saveOrder(_ ids: [UUID]) {
        do { try song.reorderChords(ids, in: modelContext) }
        catch { operationError = error.localizedDescription }
    }

    private func requestDeletion(of chord: Chord) {
        chordToDelete = chord
        isConfirmingDeletion = true
    }

    private func deleteChord(_ chord: Chord) {
        chordToDelete = nil
        do { try song.deleteChord(chord, in: modelContext) }
        catch { operationError = error.localizedDescription }
    }
}

#if DEBUG
@MainActor
private func makeSongPreview(chordCount: Int) throws -> (ModelContainer, Song) {
    let schema = Schema([Song.self, Chord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    let song = Song(title: "My First Song")
    container.mainContext.insert(song)
    let samples: [(String?, [Int])] = [("Opening", [41, 48, 52, 55]), (nil, [43, 50, 53, 57]), ("Ending", [45, 48, 52, 57])]
    for index in 0..<chordCount {
        let (label, notes) = samples[index % samples.count]
        container.mainContext.insert(Chord(label: label, notes: notes, position: index, song: song))
    }
    try container.mainContext.save()
    return (container, song)
}

#Preview("Saved song") {
    let (container, song) = try! makeSongPreview(chordCount: 3)
    NavigationStack { SongDetailView(song: song) }
        .modelContainer(container)
        .tint(.blue)
}

#Preview("Empty song") {
    let (container, song) = try! makeSongPreview(chordCount: 0)
    NavigationStack { SongDetailView(song: song) }
        .modelContainer(container)
        .tint(.blue)
}
#Preview("Long song") {
    let (container, song) = try! makeSongPreview(chordCount: 32)
    NavigationStack { SongDetailView(song: song) }
        .modelContainer(container)
        .tint(.blue)
}
#endif
