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

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tag = 1001
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let imageView = context.coordinator.imageView
        imageView?.image = UIImage(contentsOfFile: url.path)
        imageView?.frame = scrollView.bounds
        imageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.zoomScale = 1
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}
