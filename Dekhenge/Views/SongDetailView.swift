import SwiftUI
import SwiftData

struct SongDetailView: View {
    let song: Song
    @Environment(\.modelContext) private var modelContext
    @State private var editorRequest: EditorRequest?
    @State private var chordToDelete: Chord?
    @State private var isConfirmingDeletion = false
    @State private var deletionError: String?

    private struct EditorRequest: Identifiable {
        let id = UUID()
        let chord: Chord?
    }

    var body: some View {
        List {
            ForEach(Array(song.orderedChords.enumerated()), id: \.element.id) { index, chord in
                Button {
                    editorRequest = EditorRequest(chord: chord)
                } label: {
                    ChordDiagramView(chord: chord, number: index + 1)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Edit \(chord.label ?? "chord \(index + 1)")")
                .accessibilityValue(PianoNote.names(for: Set(chord.notes)))
                .accessibilityIdentifier("chordDiagram_\(chord.id)")
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) { requestDeletion(of: chord) }
                }
                .contextMenu {
                    Button("Edit Chord", systemImage: "pencil") {
                        editorRequest = EditorRequest(chord: chord)
                    }
                    Button("Delete Chord", systemImage: "trash", role: .destructive) {
                        requestDeletion(of: chord)
                    }
                }
                .accessibilityAction(named: "Delete Chord") { requestDeletion(of: chord) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 850)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if song.chords.isEmpty {
                ContentUnavailableView {
                    Label("A Fresh Page", systemImage: "pianokeys")
                } description: {
                    Text("Add your first chord to start this song.")
                } actions: {
                    Button("Add Chord", systemImage: "plus") {
                        editorRequest = EditorRequest(chord: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Chord", systemImage: "plus") {
                    editorRequest = EditorRequest(chord: nil)
                }
                .accessibilityIdentifier("addChordButton")
            }
        }
        .fullScreenCover(item: $editorRequest) { request in
            ChordEditorView(chord: request.chord) { draft in
                try song.saveChord(draft, editing: request.chord, in: modelContext)
            }
            .tint(.indigo)
        }
        .alert("Delete Chord?", isPresented: $isConfirmingDeletion, presenting: chordToDelete) { chord in
            Button("Delete Chord", role: .destructive) { deleteChord(chord) }
            Button("Cancel", role: .cancel) { chordToDelete = nil }
        } message: { _ in
            Text("This chord will be permanently removed from the song.")
        }
        .alert("Couldn’t Delete Chord", isPresented: Binding(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("OK", role: .cancel) { deletionError = nil }
        } message: {
            Text(deletionError ?? "Please try again.")
        }
    }

    private func requestDeletion(of chord: Chord) {
        chordToDelete = chord
        isConfirmingDeletion = true
    }

    private func deleteChord(_ chord: Chord) {
        chordToDelete = nil
        do { try song.deleteChord(chord, in: modelContext) }
        catch { deletionError = error.localizedDescription }
    }
}

#if DEBUG
@MainActor
private func makeSongPreview(hasChords: Bool) throws -> (ModelContainer, Song) {
    let schema = Schema([Song.self, Chord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    let song = Song(title: "My First Song")
    container.mainContext.insert(song)
    if hasChords {
        try song.saveChord(ChordDraft(label: "Opening", notes: [41, 48, 52, 55]), editing: nil, in: container.mainContext)
        try song.saveChord(ChordDraft(notes: [43, 50, 53, 57]), editing: nil, in: container.mainContext)
    }
    return (container, song)
}

#Preview("Saved song") {
    let (container, song) = try! makeSongPreview(hasChords: true)
    NavigationStack { SongDetailView(song: song) }
        .modelContainer(container)
        .tint(.indigo)
}

#Preview("Empty song") {
    let (container, song) = try! makeSongPreview(hasChords: false)
    NavigationStack { SongDetailView(song: song) }
        .modelContainer(container)
        .tint(.indigo)
}
#endif
