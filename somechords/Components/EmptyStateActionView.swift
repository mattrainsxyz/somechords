import SwiftUI

/// Shared positioning keeps empty library and song actions aligned.
struct EmptyStateActionView: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 24) {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}
