import SwiftUI

internal struct YCVideoCoverPickerView: View {
    let duration: Double
    @Binding var coverTime: Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(YCL10n.string("cover_time"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(YCDurationFormatter.string(from: coverTime))
                    .font(.caption.monospacedDigit())
            }
            Slider(value: $coverTime, in: 0...max(duration, 0.1))
        }
        .padding()
        .frame(height: 92)
    }
}
