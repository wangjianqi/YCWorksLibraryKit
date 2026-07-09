import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
@preconcurrency import UIKit

public struct YCImageRenderParameters: Sendable {
    public var filter: YCImageFilter
    public var filterIntensity: Double
    public var adjustments: YCImageAdjustments
    public var rotation: YCImageRotation
    public var isFlippedHorizontally: Bool
    public var cropAspect: YCImageCropAspect

    public init(
        filter: YCImageFilter = .original,
        filterIntensity: Double = 1,
        adjustments: YCImageAdjustments = .zero,
        rotation: YCImageRotation = .degrees0,
        isFlippedHorizontally: Bool = false,
        cropAspect: YCImageCropAspect = .original
    ) {
        self.filter = filter
        self.filterIntensity = filterIntensity
        self.adjustments = adjustments
        self.rotation = rotation
        self.isFlippedHorizontally = isFlippedHorizontally
        self.cropAspect = cropAspect
    }
}

public final class YCCoreImageEditingService: YCImageEditingService, @unchecked Sendable {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    public init() {}

    public func applyFilter(to imageURL: URL, filter: YCImageFilter, intensity: Double) async throws -> URL {
        let parameters = YCImageRenderParameters(filter: filter, filterIntensity: intensity)
        return try await renderEditedImage(imageURL: imageURL, parameters: parameters)
    }

    public func applyAdjustments(to imageURL: URL, adjustments: YCImageAdjustments) async throws -> URL {
        let parameters = YCImageRenderParameters(adjustments: adjustments)
        return try await renderEditedImage(imageURL: imageURL, parameters: parameters)
    }

    public func rotate(imageURL: URL, angle: YCImageRotation) async throws -> URL {
        let parameters = YCImageRenderParameters(rotation: angle)
        return try await renderEditedImage(imageURL: imageURL, parameters: parameters)
    }

    public func crop(imageURL: URL, cropRect: CGRect) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CIImage(contentsOf: imageURL) else { throw YCWorksLibraryError.imageLoadFailed }
            let cropped = source.cropped(to: cropRect)
            return try self.write(cropped, preferredExtension: "jpg")
        }.value
    }

    public func renderEditedImage(imageURL: URL, parameters: YCImageRenderParameters) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CIImage(contentsOf: imageURL) else { throw YCWorksLibraryError.imageLoadFailed }
            let rendered = self.renderCIImage(source, parameters: parameters)
            return try self.write(rendered, preferredExtension: "jpg")
        }.value
    }

    public func previewImage(from image: UIImage, parameters: YCImageRenderParameters, maxDimension: CGFloat) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let ciImage = CIImage(image: image) else { return image }
            let rendered = self.renderCIImage(ciImage, parameters: parameters)
            guard let cgImage = self.context.createCGImage(rendered, from: rendered.extent) else { return image }
            let uiImage = UIImage(cgImage: cgImage)
            let size = uiImage.size
            let longest = max(size.width, size.height)
            guard longest > maxDimension else { return uiImage }
            let scale = maxDimension / longest
            return uiImage.yc_resizedAspectFit(to: CGSize(width: size.width * scale, height: size.height * scale))
        }.value
    }

    private func renderCIImage(_ source: CIImage, parameters: YCImageRenderParameters) -> CIImage {
        var image = source.oriented(forExifOrientation: 1)
        image = applyCenterCropIfNeeded(image, aspect: parameters.cropAspect)
        image = applyRotationAndFlip(image, parameters: parameters)
        image = applyFilter(image, filter: parameters.filter, intensity: parameters.filterIntensity)
        image = applyAdjustments(image, adjustments: parameters.adjustments)
        return image
    }

    private func applyFilter(_ image: CIImage, filter: YCImageFilter, intensity: Double) -> CIImage {
        guard filter != .original else { return image }
        let clampedIntensity = min(max(intensity, 0), 1)
        let filtered: CIImage

        switch filter {
        case .original:
            filtered = image
        case .vivid:
            let control = CIFilter.colorControls()
            control.inputImage = image
            control.saturation = Float(1.0 + 0.35 * clampedIntensity)
            control.contrast = Float(1.0 + 0.18 * clampedIntensity)
            filtered = control.outputImage ?? image
        case .film:
            filtered = image.applyingFilter("CIPhotoEffectTransfer")
        case .mono:
            filtered = image.applyingFilter("CIPhotoEffectMono")
        case .warm:
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = image
            filter.neutral = CIVector(x: 6500, y: 0)
            filter.targetNeutral = CIVector(x: 6500 + 1400 * clampedIntensity, y: 0)
            filtered = filter.outputImage ?? image
        case .cool:
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = image
            filter.neutral = CIVector(x: 6500, y: 0)
            filter.targetNeutral = CIVector(x: 6500 - 1400 * clampedIntensity, y: 0)
            filtered = filter.outputImage ?? image
        case .contrast:
            let control = CIFilter.colorControls()
            control.inputImage = image
            control.contrast = Float(1.0 + 0.45 * clampedIntensity)
            filtered = control.outputImage ?? image
        case .soft:
            let control = CIFilter.colorControls()
            control.inputImage = image
            control.contrast = Float(1.0 - 0.18 * clampedIntensity)
            control.saturation = Float(1.0 - 0.08 * clampedIntensity)
            filtered = control.outputImage ?? image
        }

        if clampedIntensity >= 0.999 { return filtered }
        return filtered.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: image
        ])
    }

    private func applyAdjustments(_ image: CIImage, adjustments: YCImageAdjustments) -> CIImage {
        var output = image

        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.brightness = Float(adjustments.brightness * 0.35)
        controls.contrast = Float(1 + adjustments.contrast * 0.5)
        controls.saturation = Float(1 + adjustments.saturation * 0.8)
        output = controls.outputImage ?? output

        if abs(adjustments.exposure) > 0.001 {
            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = output
            exposure.ev = Float(adjustments.exposure)
            output = exposure.outputImage ?? output
        }

        if abs(adjustments.warmth) > 0.001 {
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = output
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 6500 + adjustments.warmth * 1800, y: 0)
            output = temp.outputImage ?? output
        }

        if adjustments.sharpness > 0.001 {
            let sharp = CIFilter.sharpenLuminance()
            sharp.inputImage = output
            sharp.sharpness = Float(adjustments.sharpness * 1.2)
            output = sharp.outputImage ?? output
        }

        return output
    }

    private func applyCenterCropIfNeeded(_ image: CIImage, aspect: YCImageCropAspect) -> CIImage {
        guard let ratio = aspect.ratio else { return image }
        let extent = image.extent
        let currentRatio = extent.width / extent.height
        var crop = extent

        if currentRatio > ratio {
            let width = extent.height * ratio
            crop.origin.x = extent.midX - width / 2
            crop.size.width = width
        } else {
            let height = extent.width / ratio
            crop.origin.y = extent.midY - height / 2
            crop.size.height = height
        }

        return image.cropped(to: crop)
    }

    private func applyRotationAndFlip(_ image: CIImage, parameters: YCImageRenderParameters) -> CIImage {
        var transform = CGAffineTransform.identity

        if parameters.isFlippedHorizontally {
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.translatedBy(x: -image.extent.width, y: 0)
        }

        switch parameters.rotation {
        case .degrees0:
            break
        case .degrees90:
            transform = transform.translatedBy(x: image.extent.height, y: 0).rotated(by: .pi / 2)
        case .degrees180:
            transform = transform.translatedBy(x: image.extent.width, y: image.extent.height).rotated(by: .pi)
        case .degrees270:
            transform = transform.translatedBy(x: 0, y: image.extent.width).rotated(by: -.pi / 2)
        }

        return image.transformed(by: transform)
    }

    private func write(_ image: CIImage, preferredExtension: String) throws -> URL {
        let extent = image.extent.integral
        guard let cgImage = context.createCGImage(image, from: extent) else {
            throw YCWorksLibraryError.imageRenderFailed
        }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: 0.95) else {
            throw YCWorksLibraryError.imageRenderFailed
        }
        let outputURL = YCFileUtility.uniqueTemporaryURL(extension: preferredExtension)
        try data.write(to: outputURL, options: [.atomic])
        return outputURL
    }
}

private extension UIImage {
    func yc_resizedAspectFit(to targetSize: CGSize) -> UIImage {
        guard targetSize.width > 0, targetSize.height > 0 else { return self }
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
