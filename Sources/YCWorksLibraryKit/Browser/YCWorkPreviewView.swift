import SwiftUI
import AVKit

public struct YCWorkPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var items: [YCWorkItem]
    @State private var currentIndex: Int
    @State private var showsChrome = true
    @State private var showsInfo = false
    @State private var showsRename = false
    @State private var showsShare = false
    @State private var showsDeleteConfirmation = false
    @State private var imageEditorRoute: YCWorkItem?
    @State private var videoEditorRoute: YCWorkItem?
    @State private var errorMessage: String?

    private let configuration: YCWorksLibraryConfiguration
    private let dataProvider: any YCWorksDataProvider
    private let onDismiss: () -> Void
    private let onReload: () -> Void

    public init(
        items: [YCWorkItem],
        initialIndex: Int,
        configuration: YCWorksLibraryConfiguration = .default,
        dataProvider: any YCWorksDataProvider,
        onDismiss: @escaping () -> Void = {},
        onReload: @escaping () -> Void = {}
    ) {
        _items = State(initialValue: items)
        _currentIndex = State(initialValue: max(0, min(initialIndex, max(items.count - 1, 0))))
        self.configuration = configuration
        self.dataProvider = dataProvider
        self.onDismiss = onDismiss
        self.onReload = onReload
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !items.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        previewContent(for: item)
                            .tag(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    showsChrome.toggle()
                                }
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }

            if showsChrome, let currentItem {
                VStack(spacing: 0) {
                    topBar(for: currentItem)
                    Spacer()
                    bottomBar(for: currentItem)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showsInfo) {
            if let currentItem {
                YCWorkInfoSheet(item: currentItem)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showsRename) {
            if let currentItem {
                YCWorkRenameSheet(item: currentItem) { renamed in
                    Task { await update(renamed) }
                }
                .presentationDetents([.height(220)])
            }
        }
        .sheet(isPresented: $showsShare) {
            if let currentItem {
                YCShareSheet(activityItems: [currentItem.fileURL])
            }
        }
        .fullScreenCover(item: $imageEditorRoute) { item in
            YCImageEditorView(item: item) { result in
                await saveEditedImage(original: item, imageURL: result)
            }
        }
        .fullScreenCover(item: $videoEditorRoute) { item in
            YCVideoEditorView(item: item) { result in
                await saveEditedVideo(original: item, videoURL: result)
            }
        }
        .confirmationDialog(
            YCL10n.string("delete_confirmation_title"),
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(YCL10n.string("delete"), role: .destructive) {
                if let currentItem {
                    Task { await delete(currentItem) }
                }
            }
            Button(YCL10n.string("cancel"), role: .cancel) {}
        } message: {
            Text(YCL10n.string("delete_confirmation_message"))
        }
        .alert(YCL10n.string("error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(YCL10n.string("ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var currentItem: YCWorkItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    @ViewBuilder
    private func previewContent(for item: YCWorkItem) -> some View {
        switch item.mediaType {
        case .image:
            YCWorkImagePreviewView(url: item.fileURL)
        case .video:
            YCWorkVideoPreviewView(url: item.fileURL)
        }
    }

    private func topBar(for item: YCWorkItem) -> some View {
        HStack(spacing: 12) {
            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.35), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(YCDateFormatter.string(from: item.createdAt))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Menu {
                if configuration.allowsRename {
                    Button(YCL10n.string("rename"), systemImage: "pencil") {
                        showsRename = true
                    }
                }

                if configuration.showsInfoPanel {
                    Button(YCL10n.string("info"), systemImage: "info.circle") {
                        showsInfo = true
                    }
                }

                if configuration.allowsShare {
                    Button(YCL10n.string("share"), systemImage: "square.and.arrow.up") {
                        showsShare = true
                    }
                }

                if configuration.allowsDelete {
                    Button(YCL10n.string("delete"), systemImage: "trash", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.35), in: Circle())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [.black.opacity(0.62), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    private func bottomBar(for item: YCWorkItem) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                YCPreviewActionButton(title: YCL10n.string("share"), systemImage: "square.and.arrow.up") {
                    showsShare = true
                }
                .disabled(!configuration.allowsShare)

                YCPreviewActionButton(title: item.isFavorite ? YCL10n.string("unfavorite") : YCL10n.string("favorite"), systemImage: item.isFavorite ? "heart.fill" : "heart") {
                    Task {
                        var updated = item
                        updated.isFavorite.toggle()
                        await update(updated)
                    }
                }
                .disabled(!configuration.allowsFavorite)

                YCPreviewActionButton(title: YCL10n.string("edit"), systemImage: "slider.horizontal.3") {
                    switch item.mediaType {
                    case .image:
                        if configuration.allowsImageEditing { imageEditorRoute = item }
                    case .video:
                        if configuration.allowsVideoEditing { videoEditorRoute = item }
                    }
                }

                YCPreviewActionButton(title: YCL10n.string("info"), systemImage: "info.circle") {
                    showsInfo = true
                }
                .disabled(!configuration.showsInfoPanel)

                YCPreviewActionButton(title: YCL10n.string("delete"), systemImage: "trash") {
                    showsDeleteConfirmation = true
                }
                .disabled(!configuration.allowsDelete)
            }
            .padding(.horizontal, 12)

            if configuration.showsThumbnailStrip {
                YCThumbnailStripView(items: items, currentIndex: currentIndex) { index in
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentIndex = index
                    }
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 16)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func update(_ item: YCWorkItem) async {
        do {
            try await dataProvider.updateWork(item)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
            onReload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ item: YCWorkItem) async {
        do {
            try await dataProvider.deleteWorks([item])
            items.removeAll { $0.id == item.id }
            if currentIndex >= items.count {
                currentIndex = max(0, items.count - 1)
            }
            onReload()
            if items.isEmpty {
                onDismiss()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveEditedImage(original: YCWorkItem, imageURL: URL) async {
        do {
            let newItem = try await dataProvider.saveEditedImage(original: original, imageURL: imageURL)
            items.insert(newItem, at: min(currentIndex + 1, items.count))
            onReload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveEditedVideo(original: YCWorkItem, videoURL: URL) async {
        do {
            let newItem = try await dataProvider.saveEditedVideo(original: original, videoURL: videoURL)
            items.insert(newItem, at: min(currentIndex + 1, items.count))
            onReload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct YCPreviewActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(height: 22)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
