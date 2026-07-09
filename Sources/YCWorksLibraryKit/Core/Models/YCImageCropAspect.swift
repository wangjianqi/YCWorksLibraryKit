import Foundation

public enum YCImageCropAspect: String, CaseIterable, Identifiable, Codable, Sendable {
    case original
    case free
    case square
    case portrait4x3
    case landscape4x3
    case portrait16x9
    case landscape16x9

    public var id: String { rawValue }

    public var ratio: Double? {
        switch self {
        case .original, .free:
            return nil
        case .square:
            return 1
        case .portrait4x3:
            return 3.0 / 4.0
        case .landscape4x3:
            return 4.0 / 3.0
        case .portrait16x9:
            return 9.0 / 16.0
        case .landscape16x9:
            return 16.0 / 9.0
        }
    }
}
