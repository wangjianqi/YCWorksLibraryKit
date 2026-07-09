import SwiftUI

internal struct YCImageAdjustmentPanel: View {
    @Binding var adjustments: YCImageAdjustments

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                YCAdjustmentSlider(title: YCL10n.string("brightness"), value: $adjustments.brightness, range: -1...1)
                YCAdjustmentSlider(title: YCL10n.string("contrast"), value: $adjustments.contrast, range: -1...1)
                YCAdjustmentSlider(title: YCL10n.string("saturation"), value: $adjustments.saturation, range: -1...1)
                YCAdjustmentSlider(title: YCL10n.string("exposure"), value: $adjustments.exposure, range: -2...2)
                YCAdjustmentSlider(title: YCL10n.string("warmth"), value: $adjustments.warmth, range: -1...1)
                YCAdjustmentSlider(title: YCL10n.string("sharpness"), value: $adjustments.sharpness, range: 0...1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 108)
    }
}

private struct YCAdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .lineLimit(1)
            Slider(value: $value, in: range)
                .frame(width: 132)
            Text(String(format: "%.2f", value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(width: 144)
    }
}
