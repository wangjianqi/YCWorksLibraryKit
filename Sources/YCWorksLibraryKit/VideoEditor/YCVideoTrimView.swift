import SwiftUI

internal struct YCVideoTrimView: View {
    let duration: Double
    @Binding var startTime: Double
    @Binding var endTime: Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(YCDurationFormatter.string(from: startTime))
                    .font(.caption.monospacedDigit())
                Spacer()
                Text(YCDurationFormatter.string(from: max(0, endTime - startTime)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(YCDurationFormatter.string(from: endTime))
                    .font(.caption.monospacedDigit())
            }

            VStack(spacing: 10) {
                Slider(value: $startTime, in: 0...max(0, endTime - 0.1))
                Slider(value: $endTime, in: min(duration, startTime + 0.1)...duration)
            }
        }
        .padding()
        .frame(height: 112)
    }
}
