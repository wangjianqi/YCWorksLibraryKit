import Foundation
import AVFoundation
@preconcurrency import UIKit

public final class YCAVFoundationVideoEditingService: YCVideoEditingService, @unchecked Sendable {
    public init() {}

    public func trim(videoURL: URL, startTime: TimeInterval, endTime: TimeInterval) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        let range = CMTimeRange(start: start, end: end)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw YCWorksLibraryError.videoTrackMissing
        }
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionVideoTrack?.insertTimeRange(range, of: videoTrack, at: .zero)
        compositionVideoTrack?.preferredTransform = try await videoTrack.load(.preferredTransform)

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? compositionAudioTrack?.insertTimeRange(range, of: audioTrack, at: .zero)
        }

        return try await exportComposition(composition, presetName: AVAssetExportPresetPassthrough, fileType: .mov)
    }

    public func mute(videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        let duration = try await asset.load(.duration)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw YCWorksLibraryError.videoTrackMissing
        }
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: .zero)
        compositionVideoTrack?.preferredTransform = try await videoTrack.load(.preferredTransform)

        return try await exportComposition(composition, presetName: AVAssetExportPresetPassthrough, fileType: .mov)
    }

    public func rotate(videoURL: URL, rotation: YCVideoRotation) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        let duration = try await asset.load(.duration)

        guard let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw YCWorksLibraryError.videoTrackMissing
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceVideoTrack, at: .zero)

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: audioTrack, at: .zero)
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        let renderSize: CGSize
        let rotateTransform: CGAffineTransform

        switch rotation {
        case .degrees0:
            renderSize = naturalSize
            rotateTransform = preferredTransform
        case .degrees90:
            renderSize = CGSize(width: abs(naturalSize.height), height: abs(naturalSize.width))
            rotateTransform = preferredTransform
                .rotated(by: .pi / 2)
                .translatedBy(x: 0, y: -naturalSize.height)
        case .degrees180:
            renderSize = naturalSize
            rotateTransform = preferredTransform
                .rotated(by: .pi)
                .translatedBy(x: -naturalSize.width, y: -naturalSize.height)
        case .degrees270:
            renderSize = CGSize(width: abs(naturalSize.height), height: abs(naturalSize.width))
            rotateTransform = preferredTransform
                .rotated(by: -.pi / 2)
                .translatedBy(x: -naturalSize.width, y: 0)
        }

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack!)
        layerInstruction.setTransform(rotateTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.renderSize = CGSize(width: abs(renderSize.width), height: abs(renderSize.height))
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        return try await exportComposition(composition, presetName: AVAssetExportPresetHighestQuality, fileType: .mov, videoComposition: videoComposition)
    }

    public func export(videoURL: URL, configuration: YCVideoExportConfiguration) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let fileType: AVFileType = configuration.outputFileType == .mp4 ? .mp4 : .mov
        let outputURL = YCFileUtility.uniqueTemporaryURL(extension: configuration.outputFileType.fileExtension)
        let preset = avPreset(for: configuration.preset)

        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw YCWorksLibraryError.exportSessionUnavailable
        }
        session.outputURL = outputURL
        session.outputFileType = fileType
        session.shouldOptimizeForNetworkUse = true
        return try await runExport(session: session, outputURL: outputURL)
    }

    public func generateThumbnail(videoURL: URL, at time: TimeInterval) async throws -> URL {
        let image = await YCThumbnailGenerator.shared.generateVideoThumbnail(url: videoURL, targetSize: CGSize(width: 720, height: 720), at: time)
        guard let data = image?.jpegData(compressionQuality: 0.9) else {
            throw YCWorksLibraryError.imageRenderFailed
        }
        let outputURL = YCFileUtility.uniqueTemporaryURL(extension: "jpg")
        try data.write(to: outputURL, options: [.atomic])
        return outputURL
    }

    private func exportComposition(
        _ composition: AVMutableComposition,
        presetName: String,
        fileType: AVFileType,
        videoComposition: AVVideoComposition? = nil
    ) async throws -> URL {
        let outputExtension = fileType == .mp4 ? "mp4" : "mov"
        let outputURL = YCFileUtility.uniqueTemporaryURL(extension: outputExtension)
        guard let session = AVAssetExportSession(asset: composition, presetName: presetName) else {
            throw YCWorksLibraryError.exportSessionUnavailable
        }
        session.outputURL = outputURL
        session.outputFileType = fileType
        session.shouldOptimizeForNetworkUse = true
        session.videoComposition = videoComposition
        return try await runExport(session: session, outputURL: outputURL)
    }

    private func runExport(session: AVAssetExportSession, outputURL: URL) async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        continuation.resume(returning: outputURL)
                    case .cancelled:
                        continuation.resume(throwing: YCWorksLibraryError.cancelled)
                    case .failed:
                        continuation.resume(throwing: YCWorksLibraryError.exportFailed(session.error?.localizedDescription ?? "Unknown"))
                    default:
                        continuation.resume(throwing: YCWorksLibraryError.exportFailed("Unexpected export status: \(session.status.rawValue)"))
                    }
                }
            }
        } onCancel: {
            session.cancelExport()
        }
    }

    private func avPreset(for preset: YCVideoExportPreset) -> String {
        switch preset {
        case .original:
            return AVAssetExportPresetPassthrough
        case .hd1080:
            return AVAssetExportPreset1920x1080
        case .hd720:
            return AVAssetExportPreset1280x720
        }
    }
}
