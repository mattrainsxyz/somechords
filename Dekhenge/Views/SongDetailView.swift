import SwiftUI

struct SongDetailView: View {
    let song: Song

    var body: some View {
        ContentUnavailableView {
            Label("A Fresh Page", systemImage: "pianokeys")
        } description: {
            Text("This song has no chords yet. Your chord collection will live here.")
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
