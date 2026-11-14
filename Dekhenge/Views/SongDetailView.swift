import SwiftUI

struct SongDetailView: View {
    let song: Song
    @State private var isShowingKeyboard = false

    var body: some View {
        ContentUnavailableView {
            Label("A Fresh Page", systemImage: "pianokeys")
        } description: {
            Text("This song has no chords yet. Your chord collection will live here.")
        } actions: {
            Button("Try the Keyboard", systemImage: "pianokeys") {
                isShowingKeyboard = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("tryKeyboardButton")
        }
        .fullScreenCover(isPresented: $isShowingKeyboard) {
            KeyboardSelectionView()
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
