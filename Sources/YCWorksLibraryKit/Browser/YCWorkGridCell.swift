import SwiftUI
@preconcurrency import UIKit

internal struct YCWorkGridCell: View {
    let item: YCWorkItem
    let isSelectionMode: Bool
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            YCAsyncThumbnailView(item: item)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .background(Color.secondary.opacity(0.12))

            LinearGradient(
                colors: [.black.opacity(0.42), .clear],
                startPoint: .top,
                endPoint: .center
            )

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }

                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? .blue : .white)
                            .shadow(radius: 2)
                    }
                }
                Spacer()
            }
            .padding(7)

            VStack {
                Spacer()
                HStack(spacing: 4) {
                    if item.mediaType == .video {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text(YCDurationFormatter.string(from: item.duration))
                            .font(.caption2.monospacedDigit())
                    }
                    Spacer()
                    if item.isEdited {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(.black.opacity(0.35))
            }
        }
    }
}

internal struct YCAsyncThumbnailView: View {
    let item: YCWorkItem
    var targetSize: CGSize = CGSize(width: 240, height: 240)

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(.secondary.opacity(0.12))
                    Image(systemName: item.mediaType == .image ? "photo" : "video")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: item.id) {
            image = await YCThumbnailGenerator.shared.thumbnail(for: item, targetSize: targetSize)
        }
    }
}
