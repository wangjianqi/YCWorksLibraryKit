import Foundation

public struct YCWorkItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var title: String
    public let mediaType: YCWorkMediaType
    public let fileURL: URL
    public var thumbnailURL: URL?
    public var createdAt: Date
    public var updatedAt: Date
    public var duration: TimeInterval?
    public var fileSize: Int64?
    public var width: Int?
    public var height: Int?
    public var isFavorite: Bool
    public var isEdited: Bool
    public var isExported: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        mediaType: YCWorkMediaType,
        fileURL: URL,
        thumbnailURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        duration: TimeInterval? = nil,
        fileSize: Int64? = nil,
        width: Int? = nil,
        height: Int? = nil,
        isFavorite: Bool = false,
        isEdited: Bool = false,
        isExported: Bool = false
    ) {
        self.id = id
        self.title = title
        self.mediaType = mediaType
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.duration = duration
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.isFavorite = isFavorite
        self.isEdited = isEdited
        self.isExported = isExported
    }
}
