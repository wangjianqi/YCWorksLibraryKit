import SwiftUI
@preconcurrency import UIKit

internal struct YCWorkImagePreviewView: View {
    let url: URL

    var body: some View {
        YCZoomableImageView(url: url)
            .ignoresSafeArea()
    }
}

internal struct YCZoomableImageView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> YCImageZoomScrollView {
        let scrollView = YCImageZoomScrollView()
        scrollView.backgroundColor = .black
        scrollView.configure(url: url)
        return scrollView
    }

    func updateUIView(_ scrollView: YCImageZoomScrollView, context: Context) {
        scrollView.configure(url: url)
    }
}

internal final class YCImageZoomScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private var currentURL: URL?
    private var currentImageSize: CGSize = .zero
    private var needsInitialZoom = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 6
        bouncesZoom = true
        alwaysBounceVertical = true
        alwaysBounceHorizontal = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = .fast
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    func configure(url: URL) {
        guard currentURL != url else { return }
        currentURL = url
        imageView.image = UIImage(contentsOfFile: url.path)
        currentImageSize = imageView.image?.size ?? .zero
        needsInitialZoom = true
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0, currentImageSize.width > 0, currentImageSize.height > 0 else {
            imageView.frame = bounds
            contentSize = bounds.size
            return
        }

        if imageView.bounds.size != currentImageSize {
            imageView.bounds = CGRect(origin: .zero, size: currentImageSize)
            imageView.center = CGPoint(x: currentImageSize.width * 0.5, y: currentImageSize.height * 0.5)
            contentSize = currentImageSize
        }

        let xScale = bounds.width / currentImageSize.width
        let yScale = bounds.height / currentImageSize.height
        let fitScale = min(xScale, yScale)
        let resolvedMinimumScale = max(0.01, fitScale)
        let resolvedMaximumScale = max(resolvedMinimumScale * 6, 1.5)

        if abs(minimumZoomScale - resolvedMinimumScale) > 0.0001 || abs(maximumZoomScale - resolvedMaximumScale) > 0.0001 {
            minimumZoomScale = resolvedMinimumScale
            maximumZoomScale = resolvedMaximumScale
            if zoomScale < resolvedMinimumScale || needsInitialZoom {
                zoomScale = resolvedMinimumScale
            }
        }

        if needsInitialZoom {
            zoomScale = resolvedMinimumScale
            needsInitialZoom = false
        }

        centerImageIfNeeded()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
    }

    private func centerImageIfNeeded() {
        let offsetX = max((bounds.width - contentSize.width) * 0.5, 0)
        let offsetY = max((bounds.height - contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(
            x: contentSize.width * 0.5 + offsetX,
            y: contentSize.height * 0.5 + offsetY
        )
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let targetScale: CGFloat
        if zoomScale > minimumZoomScale * 1.25 {
            targetScale = minimumZoomScale
        } else {
            targetScale = min(maximumZoomScale, minimumZoomScale * 2.6)
        }

        let point = recognizer.location(in: imageView)
        let size = CGSize(width: bounds.width / targetScale, height: bounds.height / targetScale)
        let origin = CGPoint(x: point.x - size.width * 0.5, y: point.y - size.height * 0.5)
        zoom(to: CGRect(origin: origin, size: size), animated: true)
    }
}
