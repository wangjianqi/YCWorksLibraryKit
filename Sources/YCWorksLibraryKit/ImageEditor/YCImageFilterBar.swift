import SwiftUI

internal struct YCImageFilterBar: View {
    @Binding var selectedFilter: YCImageFilter
    @Binding var intensity: Double

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(YCImageFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.localizedTitle)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(selectedFilter == filter ? Color.accentColor : Color.clear, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }

            HStack {
                Text(YCL10n.string("intensity"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $intensity, in: 0...1)
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 10)
        .frame(height: 108)
    }
}

internal extension YCImageFilter {
    var localizedTitle: String {
        switch self {
        case .original: return YCL10n.string("filter_original")
        case .vivid: return YCL10n.string("filter_vivid")
        case .film: return YCL10n.string("filter_film")
        case .mono: return YCL10n.string("filter_mono")
        case .warm: return YCL10n.string("filter_warm")
        case .cool: return YCL10n.string("filter_cool")
        case .contrast: return YCL10n.string("filter_contrast")
        case .soft: return YCL10n.string("filter_soft")
        }
    }
}
