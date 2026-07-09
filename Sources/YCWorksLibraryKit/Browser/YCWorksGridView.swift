import SwiftUI

internal struct YCWorksGridView: View {
    let items: [YCWorkItem]
    let isSelectionMode: Bool
    let selectedIDs: Set<YCWorkItem.ID>
    let onTap: (YCWorkItem) -> Void
    let onLongPress: (YCWorkItem) -> Void
    let onToggleSelection: (YCWorkItem) -> Void
    let onFavorite: (YCWorkItem) -> Void
    let onRename: (YCWorkItem) -> Void
    let onDelete: (YCWorkItem) -> Void
    let onShare: (YCWorkItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    YCWorkGridCell(
                        item: item,
                        isSelectionMode: isSelectionMode,
                        isSelected: selectedIDs.contains(item.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap(item)
                    }
                    .onLongPressGesture {
                        onLongPress(item)
                    }
                    .contextMenu {
                        Button {
                            onFavorite(item)
                        } label: {
                            Label(
                                item.isFavorite ? YCL10n.string("unfavorite") : YCL10n.string("favorite"),
                                systemImage: item.isFavorite ? "heart.slash" : "heart"
                            )
                        }

                        Button {
                            onShare(item)
                        } label: {
                            Label(YCL10n.string("share"), systemImage: "square.and.arrow.up")
                        }

                        YCWorkRenameMenuButton(item: item, onRename: onRename)

                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Label(YCL10n.string("delete"), systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 12)
        }
    }
}
