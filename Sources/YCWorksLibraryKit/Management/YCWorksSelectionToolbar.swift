import SwiftUI

internal struct YCWorksSelectionToolbar: View {
    let selectedCount: Int
    let allowsShare: Bool
    let allowsDelete: Bool
    let onShare: () -> Void
    let onDelete: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(String(format: YCL10n.string("selected_count_format"), selectedCount))
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onFavorite()
            } label: {
                Label(YCL10n.string("favorite"), systemImage: "heart")
                    .labelStyle(.iconOnly)
                    .frame(width: 42, height: 42)
            }
            .disabled(selectedCount == 0)

            Button {
                onShare()
            } label: {
                Label(YCL10n.string("share"), systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
                    .frame(width: 42, height: 42)
            }
            .disabled(selectedCount == 0 || !allowsShare)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(YCL10n.string("delete"), systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .frame(width: 42, height: 42)
            }
            .disabled(selectedCount == 0 || !allowsDelete)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}
