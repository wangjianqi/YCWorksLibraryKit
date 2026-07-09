import SwiftUI
import Foundation

public struct YCWorksLibraryView: View {
    @StateObject private var viewModel: YCWorksLibraryViewModel
    @State private var showsFilterSheet = false
    @State private var previewRoute: PreviewRoute?
    @State private var activeHeroID: YCWorkItem.ID?
    @Namespace private var heroNamespace
    @State private var shareRoute: ShareRoute?
    @State private var deletingItems: [YCWorkItem] = []
    @State private var showsDeleteConfirmation = false

    public init(
        configuration: YCWorksLibraryConfiguration = .default,
        dataProvider: any YCWorksDataProvider
    ) {
        _viewModel = StateObject(
            wrappedValue: YCWorksLibraryViewModel(
                configuration: configuration,
                dataProvider: dataProvider
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                YCWorksGridView(
                    items: viewModel.visibleWorks,
                    isSelectionMode: viewModel.isSelectionMode,
                    selectedIDs: viewModel.selectedIDs,
                    transitionNamespace: heroNamespace,
                    activeHeroID: activeHeroID,
                    onTap: handleTap,
                    onLongPress: handleLongPress,
                    onToggleSelection: viewModel.toggleSelection,
                    onFavorite: { item in
                        Task { await viewModel.toggleFavorite(item) }
                    },
                    onRename: { item in
                        Task { await viewModel.update(item) }
                    },
                    onDelete: { item in
                        deletingItems = [item]
                        showsDeleteConfirmation = true
                    },
                    onShare: { item in
                        shareRoute = ShareRoute(urls: [item.fileURL])
                    }
                )

                if viewModel.isLoading {
                    ProgressView()
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if viewModel.visibleWorks.isEmpty && !viewModel.isLoading {
                    YCWorksEmptyStateView()
                }

                if let previewRoute {
                    YCWorkPreviewView(
                        items: previewRoute.items,
                        initialIndex: previewRoute.index,
                        configuration: viewModel.configuration,
                        dataProvider: viewModel.dataProvider,
                        transitionNamespace: heroNamespace,
                        activeHeroID: activeHeroID,
                        onCurrentItemChanged: { _, item in
                            activeHeroID = item.id
                        },
                        onDismiss: {
                            dismissPreviewWithHeroAnimation()
                        },
                        onReload: {
                            Task { await viewModel.reloadSilently() }
                        }
                    )
                    .zIndex(20)
                    .transition(.identity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.isSelectionMode && previewRoute == nil {
                    YCWorksSelectionToolbar(
                        selectedCount: viewModel.selectedIDs.count,
                        allowsShare: viewModel.configuration.allowsShare,
                        allowsDelete: viewModel.configuration.allowsDelete,
                        onShare: {
                            let urls = viewModel.selectedWorks.map(\.fileURL)
                            if !urls.isEmpty { shareRoute = ShareRoute(urls: urls) }
                        },
                        onDelete: {
                            deletingItems = viewModel.selectedWorks
                            showsDeleteConfirmation = true
                        },
                        onFavorite: {
                            Task {
                                for item in viewModel.selectedWorks where !item.isFavorite {
                                    var updated = item
                                    updated.isFavorite = true
                                    await viewModel.update(updated)
                                }
                            }
                        }
                    )
                }
            }
            .navigationTitle(viewModel.configuration.title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.isSelectionMode {
                        Button(YCL10n.string("cancel")) {
                            viewModel.exitSelection()
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.isSelectionMode {
                        Button(YCL10n.string("select_all")) {
                            viewModel.selectAllVisible()
                        }
                    } else {
                        Button {
                            showsFilterSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }

                        if viewModel.configuration.allowsSelection {
                            Button(YCL10n.string("select")) {
                                viewModel.isSelectionMode = true
                            }
                        }
                    }
                }
            }
            .toolbar(previewRoute == nil ? .visible : .hidden, for: .navigationBar)
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.reloadSilently()
            }
            .sheet(isPresented: $showsFilterSheet) {
                YCWorksFilterSheet(
                    filter: $viewModel.filter,
                    sort: $viewModel.sort
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $shareRoute) { route in
                YCShareSheet(activityItems: route.urls)
            }
            .confirmationDialog(
                YCL10n.string("delete_confirmation_title"),
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(YCL10n.string("delete"), role: .destructive) {
                    let items = deletingItems
                    deletingItems = []
                    Task { await viewModel.delete(items) }
                }
                Button(YCL10n.string("cancel"), role: .cancel) {}
            } message: {
                Text(YCL10n.string("delete_confirmation_message"))
            }
            .alert(YCL10n.string("error"), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(YCL10n.string("ok"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func handleTap(_ item: YCWorkItem) {
        if viewModel.isSelectionMode {
            viewModel.toggleSelection(for: item)
            return
        }
        guard let index = viewModel.visibleWorks.firstIndex(where: { $0.id == item.id }) else { return }
        activeHeroID = item.id
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88, blendDuration: 0.04)) {
            previewRoute = PreviewRoute(items: viewModel.visibleWorks, index: index)
        }
    }

    private func dismissPreviewWithHeroAnimation() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88, blendDuration: 0.04)) {
            previewRoute = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            activeHeroID = nil
        }
    }

    private func handleLongPress(_ item: YCWorkItem) {
        guard viewModel.configuration.allowsSelection else { return }
        viewModel.isSelectionMode = true
        viewModel.selectedIDs.insert(item.id)
    }
}

private struct PreviewRoute: Identifiable {
    let id = UUID()
    let items: [YCWorkItem]
    let index: Int
}

private struct ShareRoute: Identifiable {
    let id = UUID()
    let urls: [URL]
}
