import SwiftUI
import AVKit

internal struct YCWorkVideoPreviewView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: url) {
            player = AVPlayer(url: url)
        }
    }
}
