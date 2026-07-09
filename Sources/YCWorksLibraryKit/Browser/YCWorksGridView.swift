import SwiftUI

internal struct YCWorksGridView: View {
    let items: [YCWorkItem]
    let isSelectionMode: Bool
    let selectedIDs: Set<YCWorkItem.ID>
    let transitionNamespace: Namespace.ID?
    let activeHeroID: YCWorkItem.ID?
    let onTap: (YCWorkItem) -> Void
    let onLongPress: (YCWorkItem) -> Void
    let onToggleSelection: (YCWorkItem) -> Void
    let onFavorite: (YCWorkItem) -> Void
    let onRename: (YCWorkItem) -> Void
    let onDelete: (YCWorkItem) -> Void
    let onShare: (YCWorkItem) -> Void

    @AppStorage("YCWorksLibraryKit.gridCellWidth") private var committedCellWidth: Double = 92
    @GestureState private var pinchScale: CGFloat = 1

    private let spacing: CGFloat = 2
    private let minCellWidth: CGFloat = 26
    private let maxCellWidth: CGFloat = 210

    var body: some View {
        GeometryReader { proxy in
            let layout = makeGridLayout(containerWidth: proxy.size.width)

            ScrollView {
                LazyVGrid(columns: layout.columns, spacing: spacing) {
                    ForEach(items) { item in
                        YCWorkGridCell(
                            item: item,
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedIDs.contains(item.id),
                            sideLength: layout.itemWidth
                        )
                        .frame(width: layout.itemWidth, height: layout.itemWidth)
                        .ycHeroMatchedSource(
                            id: item.id,
                            namespace: transitionNamespace,
                            isEnabled: activeHeroID == item.id
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
                .padding(.horizontal, spacing)
                .padding(.bottom, 12)
                .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.92, blendDuration: 0.02), value: layout.columnCount)
                .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.92, blendDuration: 0.02), value: layout.itemWidth)
            }
            .simultaneousGesture(pinchGesture, including: .all)
        }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.001)
            .updating($pinchScale) { value, state, _ in
                state = max(0.2, min(6, value))
            }
            .onEnded { value in
                let finalWidth = clampedCellWidth(CGFloat(committedCellWidth) * value)
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.9, blendDuration: 0.02)) {
                    committedCellWidth = Double(finalWidth)
                }
            }
    }

    private func clampedCellWidth(_ value: CGFloat) -> CGFloat {
        min(max(value, minCellWidth), maxCellWidth)
    }

    private func makeGridLayout(containerWidth: CGFloat) -> YCGridLayout {
        let availableWidth = max(1, containerWidth - spacing * 2)
        let targetWidth = clampedCellWidth(CGFloat(committedCellWidth) * pinchScale)
        let rawColumnCount = Int((availableWidth + spacing) / (targetWidth + spacing))
        let columnCount = max(1, min(32, rawColumnCount))
        let exactWidth = floor((availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount))
        let columns = Array(
            repeating: GridItem(.fixed(exactWidth), spacing: spacing, alignment: .center),
            count: columnCount
        )
        return YCGridLayout(columns: columns, itemWidth: exactWidth, columnCount: columnCount)
    }
}

private struct YCGridLayout: Equatable {
    let columns: [GridItem]
    let itemWidth: CGFloat
    let columnCount: Int

    static func == (lhs: YCGridLayout, rhs: YCGridLayout) -> Bool {
        lhs.itemWidth == rhs.itemWidth && lhs.columnCount == rhs.columnCount
    }
}

private extension View {
    @ViewBuilder
    func ycHeroMatchedSource(
        id: YCWorkItem.ID,
        namespace: Namespace.ID?,
        isEnabled: Bool
    ) -> some View {
        if let namespace, isEnabled {
            self.matchedGeometryEffect(
                id: id,
                in: namespace,
                properties: .frame,
                anchor: .center,
                isSource: true
            )
        } else {
            self
        }
    }
}
