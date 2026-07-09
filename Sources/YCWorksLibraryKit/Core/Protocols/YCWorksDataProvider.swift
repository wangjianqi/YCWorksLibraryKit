import Foundation

public protocol YCWorksDataProvider: Sendable {
    func loadWorks() async throws -> [YCWorkItem]
    func deleteWorks(_ items: [YCWorkItem]) async throws
    func updateWork(_ item: YCWorkItem) async throws
    func duplicateWork(_ item: YCWorkItem) async throws -> YCWorkItem
    func saveEditedImage(original: YCWorkItem, imageURL: URL) async throws -> YCWorkItem
    func saveEditedVideo(original: YCWorkItem, videoURL: URL) async throws -> YCWorkItem
}
