import SwiftUI

internal struct YCWorksEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(YCL10n.string("empty_title"))
                .font(.headline)
            Text(YCL10n.string("empty_message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
    }
}
