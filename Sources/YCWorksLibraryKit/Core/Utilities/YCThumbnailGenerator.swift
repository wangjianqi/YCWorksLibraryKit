import Foundation
import AVFoundation
@preconcurrency import UIKit

public final class YCThumbnailGenerator: @unchecked Sendable {
    public static let shared = YCThumbnailGenerator()

    private let cache = NSCache<NSString, UIImage>()

    public init() {}

    public func thumbnail(for item: YCWorkItem, targetSize: CGSize = CGSize(width: 240, height: 240)) async -> UIImage? {
        let key = "\(item.id)-\(Int(targetSize.width))-\(Int(targetSize.height))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image: UIImage?
        switch item.mediaType {
        case .image:
            image = await Task.detached(priority: .utility) {
                guard let original = UIImage(contentsOfFile: item.fileURL.path) else { return nil }
                return original.yc_resizedAspectFill(to: targetSize)
            }.value
        case .video:
            image = await generateVideoThumbnail(url: item.fileURL, targetSize: targetSize)
        }

        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }

    public func generateVideoThumbnail(url: URL, targetSize: CGSize = CGSize(width: 240, height: 240), at seconds: TimeInterval = 0) async -> UIImage? {
        await Task.detached(priority: .utility) {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = targetSize
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage).yc_resizedAspectFill(to: targetSize)
            } catch {
                return nil
            }
        }.value
    }
}

extension UIImage {
    func yc_resizedAspectFill(to targetSize: CGSize) -> UIImage {
        guard size.width > 0, size.height > 0, targetSize.width > 0, targetSize.height > 0 else { return self }
        let scale = max(targetSize.width / size.width, targetSize.height / size.height)
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }
}
