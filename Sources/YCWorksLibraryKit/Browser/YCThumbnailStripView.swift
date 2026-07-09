import SwiftUI

internal struct YCThumbnailStripView: View {
    let items: [YCWorkItem]
    let currentIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ZStack(alignment: .bottomTrailing) {
                            YCAsyncThumbnailView(item: item, targetSize: CGSize(width: 64, height: 64))
                                .frame(width: index == currentIndex ? 56 : 48, height: index == currentIndex ? 56 : 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(index == currentIndex ? Color.white : Color.white.opacity(0.28), lineWidth: index == currentIndex ? 2 : 1)
                                }

                            if item.mediaType == .video {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(.black.opacity(0.55), in: Circle())
                                    .foregroundStyle(.white)
                            }
                        }
                        .id(index)
                        .onTapGesture { onSelect(index) }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
            }
            .frame(height: 62)
            .onChange(of: currentIndex) { _, newValue in
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}
