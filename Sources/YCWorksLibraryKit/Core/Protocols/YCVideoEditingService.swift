import Foundation

public protocol YCVideoEditingService: Sendable {
    func trim(videoURL: URL, startTime: TimeInterval, endTime: TimeInterval) async throws -> URL
    func mute(videoURL: URL) async throws -> URL
    func rotate(videoURL: URL, rotation: YCVideoRotation) async throws -> URL
    func export(videoURL: URL, configuration: YCVideoExportConfiguration) async throws -> URL
    func generateThumbnail(videoURL: URL, at time: TimeInterval) async throws -> URL
}
