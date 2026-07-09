import Foundation

public struct YCVideoExportConfiguration: Codable, Hashable, Sendable {
    public var preset: YCVideoExportPreset
    public var keepsAudio: Bool
    public var outputFileType: YCVideoOutputFileType

    public init(
        preset: YCVideoExportPreset = .original,
        keepsAudio: Bool = true,
        outputFileType: YCVideoOutputFileType = .mp4
    ) {
        self.preset = preset
        self.keepsAudio = keepsAudio
        self.outputFileType = outputFileType
    }

    public static let `default` = YCVideoExportConfiguration()
}

public enum YCVideoExportPreset: String, Codable, CaseIterable, Sendable {
    case original
    case hd1080
    case hd720

    public var avAssetPresetName: String {
        switch self {
        case .original:
            return "AVAssetExportPresetPassthrough"
        case .hd1080:
            return "AVAssetExportPreset1920x1080"
        case .hd720:
            return "AVAssetExportPreset1280x720"
        }
    }
}

public enum YCVideoOutputFileType: String, Codable, CaseIterable, Sendable {
    case mp4
    case mov

    public var fileExtension: String {
        switch self {
        case .mp4: return "mp4"
        case .mov: return "mov"
        }
    }
}
