import Foundation
import CoreGraphics

public protocol YCImageEditingService: Sendable {
    func applyFilter(to imageURL: URL, filter: YCImageFilter, intensity: Double) async throws -> URL
    func applyAdjustments(to imageURL: URL, adjustments: YCImageAdjustments) async throws -> URL
    func rotate(imageURL: URL, angle: YCImageRotation) async throws -> URL
    func crop(imageURL: URL, cropRect: CGRect) async throws -> URL
}
