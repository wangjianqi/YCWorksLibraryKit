import Foundation

public enum YCWorksLibraryError: LocalizedError, Sendable {
    case unsupportedMedia
    case imageLoadFailed
    case imageRenderFailed
    case videoTrackMissing
    case exportSessionUnavailable
    case exportFailed(String)
    case cancelled
    case fileOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedMedia:
            return "Unsupported media type."
        case .imageLoadFailed:
            return "Failed to load image."
        case .imageRenderFailed:
            return "Failed to render image."
        case .videoTrackMissing:
            return "Video track is missing."
        case .exportSessionUnavailable:
            return "Export session is unavailable."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .cancelled:
            return "Operation cancelled."
        case .fileOperationFailed(let reason):
            return "File operation failed: \(reason)"
        }
    }
}
