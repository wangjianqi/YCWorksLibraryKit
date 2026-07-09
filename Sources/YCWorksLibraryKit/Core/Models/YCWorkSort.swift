import Foundation

public enum YCWorkSort: String, CaseIterable, Identifiable, Codable, Sendable {
    case createdAtDescending
    case createdAtAscending
    case updatedAtDescending
    case fileSizeDescending
    case titleAscending

    public var id: String { rawValue }
}
