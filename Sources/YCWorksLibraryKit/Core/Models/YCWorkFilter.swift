import Foundation

public enum YCWorkFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case all
    case images
    case videos
    case favorites
    case edited
    case exported

    public var id: String { rawValue }
}
