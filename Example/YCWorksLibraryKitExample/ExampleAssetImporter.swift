import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers


@MainActor
final class ExampleAssetImporter: ObservableObject {
    @Published var isImporting = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    let directoryURL: URL

    init(directoryURL: URL? = nil) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("YCWorksLibraryDemo", isDirectory: true)
        }
    }

    func importItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        isImporting = true
        statusMessage = nil
        errorMessage = nil
        defer { isImporting = false }

        do {
            try ensureDirectory()

            var importedCount = 0
            var failedCount = 0

            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        failedCount += 1
                        continue
                    }

                    let type = preferredContentType(for: item)
                    let fileExtension = preferredFileExtension(for: type)
                    let destinationURL = uniqueDestinationURL(fileExtension: fileExtension)
                    try data.write(to: destinationURL, options: [.atomic])
                    importedCount += 1
                } catch {
                    failedCount += 1
                }
            }

            if failedCount == 0 {
                statusMessage = "已导入 \(importedCount) 个测试资源。"
            } else {
                statusMessage = "已导入 \(importedCount) 个测试资源，\(failedCount) 个资源导入失败。"
            }
        } catch {
            errorMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    func clearImportedResources() async {
        statusMessage = nil
        errorMessage = nil

        do {
            if FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.removeItem(at: directoryURL)
            }
            try ensureDirectory()
            statusMessage = "已清空 Example 测试资源。"
        } catch {
            errorMessage = "清空失败：\(error.localizedDescription)"
        }
    }

    private func ensureDirectory() throws {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    private func preferredContentType(for item: PhotosPickerItem) -> UTType? {
        if let movieType = item.supportedContentTypes.first(where: { $0.conforms(to: .movie) }) {
            return movieType
        }
        if let imageType = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) {
            return imageType
        }
        return item.supportedContentTypes.first
    }

    private func preferredFileExtension(for type: UTType?) -> String {
        guard let type else { return "dat" }

        if type.conforms(to: .mpeg4Movie) { return "mp4" }
        if type.conforms(to: .quickTimeMovie) { return "mov" }
        if type.conforms(to: .movie) { return type.preferredFilenameExtension ?? "mov" }
        if type.conforms(to: .jpeg) { return "jpg" }
        if type.conforms(to: .png) { return "png" }
        if type.conforms(to: .heic) { return "heic" }
        if type.conforms(to: .image) { return type.preferredFilenameExtension ?? "jpg" }

        return type.preferredFilenameExtension ?? "dat"
    }

    private func uniqueDestinationURL(fileExtension: String) -> URL {
        let formatter = ISO8601DateFormatter()
        let baseName = "Imported-\(formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-"))"
        var candidate = directoryURL.appendingPathComponent(baseName).appendingPathExtension(fileExtension)
        var index = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(baseName)-\(index)").appendingPathExtension(fileExtension)
            index += 1
        }

        return candidate
    }
}
