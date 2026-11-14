import SwiftUI
import SwiftData

struct SongLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Song.updatedAt, order: .reverse), SortDescriptor(\Song.title)])
    private var songs: [Song]
    @State private var isCreatingSong = false
    @State private var songToRename: Song?
    @State private var songToDelete: Song?
    @State private var deletionError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(songs) { song in
                        NavigationLink {
                            SongDetailView(song: song)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "music.note.list")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                                    .frame(width: 44, height: 48)
                                    .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(song.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(song.chords.count) chords")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) { songToDelete = song }
                            Button("Rename") { songToRename = song }.tint(.indigo)
                        }
                        .contextMenu {
                            Button("Rename", systemImage: "pencil") { songToRename = song }
                            Button("Delete Song", systemImage: "trash", role: .destructive) { songToDelete = song }
                        }
                    }
                } header: {
                    if !songs.isEmpty { Text("Your songs") }
                } footer: {
                    if !songs.isEmpty { Text("A little space for the music you want to remember.") }
                }
            }
            .overlay {
                if songs.isEmpty {
                    ContentUnavailableView {
                        Label("Your Notebook Awaits", systemImage: "music.note.list")
                    } description: {
                        Text("Keep your songs and their chords in one quiet place. Start with a song title.")
                    } actions: {
                        Button("Create Your First Song") { isCreatingSong = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Chord Notebook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Song", systemImage: "plus") { isCreatingSong = true }
                        .accessibilityIdentifier("newSongButton")
                }
            }
            .sheet(isPresented: $isCreatingSong) {
                SongTitleEditor(heading: "New Song") { title in
                    modelContext.insert(Song(title: title))
                    try saveChanges()
                }
            }
            .sheet(item: $songToRename) { song in
                SongTitleEditor(heading: "Rename Song", initialTitle: song.title) { title in
                    let previousTitle = song.title
                    let previousDate = song.updatedAt
                    song.title = title
                    song.updatedAt = .now
                    do {
                        try saveChanges()
                    } catch {
                        // Some SwiftData versions leave observed values stale after rollback.
                        song.title = previousTitle
                        song.updatedAt = previousDate
                        throw error
                    }
                }
            }
            .alert("Delete Song?", isPresented: Binding(
                get: { songToDelete != nil },
                set: { if !$0 { songToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { songToDelete = nil }
                Button("Delete", role: .destructive) { deleteSong() }
            } message: {
                Text("“\(songToDelete?.title ?? "This song")” and all its chords will be permanently deleted.")
            }
            .alert("Couldn’t Delete Song", isPresented: Binding(
                get: { deletionError != nil },
                set: { if !$0 { deletionError = nil } }
            )) {
                Button("OK", role: .cancel) { deletionError = nil }
            } message: {
                Text(deletionError ?? "Please try again.")
            }
        }
    }

    private func saveChanges() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.processPendingChanges()
            modelContext.rollback()
            throw error
        }
    }

    private func deleteSong() {
        guard let song = songToDelete else { return }
        songToDelete = nil
        modelContext.delete(song)
        do { try saveChanges() }
        catch { deletionError = error.localizedDescription }
    }
}
