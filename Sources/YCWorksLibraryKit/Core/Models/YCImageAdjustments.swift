import Foundation

public struct YCImageAdjustments: Codable, Hashable, Sendable {
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    public var exposure: Double
    public var warmth: Double
    public var sharpness: Double

    public init(
        brightness: Double = 0,
        contrast: Double = 0,
        saturation: Double = 0,
        exposure: Double = 0,
        warmth: Double = 0,
        sharpness: Double = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.exposure = exposure
        self.warmth = warmth
        self.sharpness = sharpness
    }

    public static let zero = YCImageAdjustments()
}
