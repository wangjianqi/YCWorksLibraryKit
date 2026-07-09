import Foundation

public enum YCImageFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case original
    case vivid
    case film
    case mono
    case warm
    case cool
    case contrast
    case soft

    public var id: String { rawValue }
}
