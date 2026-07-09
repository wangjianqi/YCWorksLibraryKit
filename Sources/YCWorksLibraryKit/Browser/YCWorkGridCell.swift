import SwiftUI
@preconcurrency import UIKit

internal struct YCWorkGridCell: View {
    let item: YCWorkItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let sideLength: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            YCAsyncThumbnailView(
                item: item,
                targetSize: CGSize(width: max(64, sideLength * 2.2), height: max(64, sideLength * 2.2))
            )
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .background(Color.secondary.opacity(0.12))

            if sideLength >= 42 {
                LinearGradient(
                    colors: [.black.opacity(0.42), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    if item.isFavorite, sideLength >= 38 {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }

                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(sideLength < 38 ? .caption : .title3)
                            .foregroundStyle(isSelected ? .blue : .white)
                            .shadow(radius: 2)
                    }
                }
                Spacer()
            }
            .padding(sideLength < 42 ? 3 : 7)

            if sideLength >= 46 {
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
            } else if item.mediaType == .video {
                Image(systemName: "play.fill")
                    .font(.system(size: max(7, sideLength * 0.22), weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .clipped()
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
        .task(id: thumbnailTaskID) {
            image = await YCThumbnailGenerator.shared.thumbnail(for: item, targetSize: targetSize)
        }
    }

    private var thumbnailTaskID: String {
        "\(item.id)-\(Int(targetSize.width))-\(Int(targetSize.height))"
    }
}
