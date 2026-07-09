import Foundation

public actor YCLocalDemoWorksDataProvider: YCWorksDataProvider {
    public let directoryURL: URL

    public init(directoryURL: URL? = nil) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("YCWorksLibraryDemo", isDirectory: true)
        }
    }

    public func loadWorks() async throws -> [YCWorkItem] {
        try ensureDirectory()
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        var items: [YCWorkItem] = []
        for url in urls {
            if let item = await YCWorkMetadataReader.item(for: url) {
                items.append(item)
            }
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    public func deleteWorks(_ items: [YCWorkItem]) async throws {
        for item in items {
            if FileManager.default.fileExists(atPath: item.fileURL.path) {
                try FileManager.default.removeItem(at: item.fileURL)
            }
        }
    }

    public func updateWork(_ item: YCWorkItem) async throws {
        // Demo provider intentionally keeps metadata in memory at caller side.
        // Production apps should persist favorite/title/export flags in SwiftData, SQLite, or their own store.
    }

    public func duplicateWork(_ item: YCWorkItem) async throws -> YCWorkItem {
        try ensureDirectory()
        let output = uniqueDestinationURL(baseName: item.title + " Copy", extension: item.fileURL.pathExtension)
        try FileManager.default.copyItem(at: item.fileURL, to: output)
        guard var duplicated = await YCWorkMetadataReader.item(for: output) else {
            throw YCWorksLibraryError.unsupportedMedia
        }
        duplicated.isEdited = item.isEdited
        duplicated.isExported = item.isExported
        return duplicated
    }

    public func saveEditedImage(original: YCWorkItem, imageURL: URL) async throws -> YCWorkItem {
        try ensureDirectory()
        let output = uniqueDestinationURL(baseName: original.title + " Edited", extension: imageURL.pathExtension.isEmpty ? "jpg" : imageURL.pathExtension)
        if FileManager.default.fileExists(atPath: output.path) {
            try FileManager.default.removeItem(at: output)
        }
        try FileManager.default.copyItem(at: imageURL, to: output)
        guard var item = await YCWorkMetadataReader.item(for: output, isEdited: true, isExported: false) else {
            throw YCWorksLibraryError.unsupportedMedia
        }
        item.title = output.deletingPathExtension().lastPathComponent
        return item
    }

    public func saveEditedVideo(original: YCWorkItem, videoURL: URL) async throws -> YCWorkItem {
        try ensureDirectory()
        let output = uniqueDestinationURL(baseName: original.title + " Edited", extension: videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension)
        if FileManager.default.fileExists(atPath: output.path) {
            try FileManager.default.removeItem(at: output)
        }
        try FileManager.default.copyItem(at: videoURL, to: output)
        guard var item = await YCWorkMetadataReader.item(for: output, isEdited: true, isExported: false) else {
            throw YCWorksLibraryError.unsupportedMedia
        }
        item.title = output.deletingPathExtension().lastPathComponent
        return item
    }

    private func ensureDirectory() throws {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    private func uniqueDestinationURL(baseName: String, extension ext: String) -> URL {
        let safeBaseName = baseName.replacingOccurrences(of: "/", with: "-")
        var candidate = directoryURL.appendingPathComponent(safeBaseName).appendingPathExtension(ext)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(safeBaseName) \(index)").appendingPathExtension(ext)
            index += 1
        }
        return candidate
    }
}
