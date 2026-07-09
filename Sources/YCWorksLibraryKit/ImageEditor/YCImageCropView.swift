import SwiftUI

internal struct YCImageCropView: View {
    @Binding var selectedAspect: YCImageCropAspect

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(YCL10n.string("crop_aspect_note"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(YCImageCropAspect.allCases) { aspect in
                        Button {
                            selectedAspect = aspect
                        } label: {
                            Text(aspect.localizedTitle)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedAspect == aspect ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(selectedAspect == aspect ? Color.accentColor : Color.clear, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 10)
        .frame(height: 108)
    }
}

internal extension YCImageCropAspect {
    var localizedTitle: String {
        switch self {
        case .original: return YCL10n.string("original")
        case .free: return YCL10n.string("free")
        case .square: return "1:1"
        case .portrait4x3: return "3:4"
        case .landscape4x3: return "4:3"
        case .portrait16x9: return "9:16"
        case .landscape16x9: return "16:9"
        }
    }
}
