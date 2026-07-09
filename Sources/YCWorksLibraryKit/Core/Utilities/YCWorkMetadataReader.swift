import Foundation
import AVFoundation
@preconcurrency import UIKit

public enum YCWorkMetadataReader {
    public static func item(for url: URL, isEdited: Bool = false, isExported: Bool = false) async -> YCWorkItem? {
        let ext = url.pathExtension.lowercased()
        let title = url.deletingPathExtension().lastPathComponent
        let fileSize = YCFileUtility.fileSize(for: url)
        let createdAt = YCFileUtility.creationDate(for: url) ?? Date()
        let updatedAt = YCFileUtility.modificationDate(for: url) ?? createdAt

        if ["jpg", "jpeg", "png", "heic", "heif", "tiff", "webp"].contains(ext) {
            var width: Int?
            var height: Int?
            if let image = UIImage(contentsOfFile: url.path) {
                width = Int(image.size.width * image.scale)
                height = Int(image.size.height * image.scale)
            }
            return YCWorkItem(
                id: url.absoluteString,
                title: title,
                mediaType: .image,
                fileURL: url,
                createdAt: createdAt,
                updatedAt: updatedAt,
                fileSize: fileSize,
                width: width,
                height: height,
                isEdited: isEdited,
                isExported: isExported
            )
        }

        if ["mp4", "mov", "m4v"].contains(ext) {
            let asset = AVURLAsset(url: url)
            let durationSeconds = (try? await asset.load(.duration).seconds).flatMap { $0.isFinite ? $0 : nil }
            var width: Int?
            var height: Int?
            if let track = try? await asset.loadTracks(withMediaType: .video).first {
                if let size = try? await track.load(.naturalSize) {
                    width = Int(abs(size.width))
                    height = Int(abs(size.height))
                }
            }
            return YCWorkItem(
                id: url.absoluteString,
                title: title,
                mediaType: .video,
                fileURL: url,
                createdAt: createdAt,
                updatedAt: updatedAt,
                duration: durationSeconds,
                fileSize: fileSize,
                width: width,
                height: height,
                isEdited: isEdited,
                isExported: isExported
            )
        }

        return nil
    }
}
