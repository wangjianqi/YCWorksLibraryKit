import Foundation
import SwiftUI

@MainActor
internal final class YCWorksLibraryViewModel: ObservableObject {
    @Published var works: [YCWorkItem] = []
    @Published var filter: YCWorkFilter
    @Published var sort: YCWorkSort
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSelectionMode = false
    @Published var selectedIDs: Set<YCWorkItem.ID> = []

    let configuration: YCWorksLibraryConfiguration
    let dataProvider: any YCWorksDataProvider

    init(configuration: YCWorksLibraryConfiguration, dataProvider: any YCWorksDataProvider) {
        self.configuration = configuration
        self.dataProvider = dataProvider
        self.filter = configuration.defaultFilter
        self.sort = configuration.defaultSort
    }

    var visibleWorks: [YCWorkItem] {
        let filtered: [YCWorkItem]
        switch filter {
        case .all:
            filtered = works
        case .images:
            filtered = works.filter { $0.mediaType == .image }
        case .videos:
            filtered = works.filter { $0.mediaType == .video }
        case .favorites:
            filtered = works.filter { $0.isFavorite }
        case .edited:
            filtered = works.filter { $0.isEdited }
        case .exported:
            filtered = works.filter { $0.isExported }
        }

        switch sort {
        case .createdAtDescending:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .createdAtAscending:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .updatedAtDescending:
            return filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .fileSizeDescending:
            return filtered.sorted { ($0.fileSize ?? 0) > ($1.fileSize ?? 0) }
        case .titleAscending:
            return filtered.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
    }

    var selectedWorks: [YCWorkItem] {
        works.filter { selectedIDs.contains($0.id) }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            works = try await dataProvider.loadWorks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadSilently() async {
        do {
            works = try await dataProvider.loadWorks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSelection(for item: YCWorkItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    func exitSelection() {
        isSelectionMode = false
        selectedIDs.removeAll()
    }

    func selectAllVisible() {
        selectedIDs = Set(visibleWorks.map(\.id))
    }

    func toggleFavorite(_ item: YCWorkItem) async {
        var updated = item
        updated.isFavorite.toggle()
        await update(updated)
    }

    func update(_ item: YCWorkItem) async {
        do {
            try await dataProvider.updateWork(item)
            if let index = works.firstIndex(where: { $0.id == item.id }) {
                works[index] = item
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ items: [YCWorkItem]) async {
        do {
            try await dataProvider.deleteWorks(items)
            let ids = Set(items.map(\.id))
            works.removeAll { ids.contains($0.id) }
            selectedIDs.subtract(ids)
            if selectedIDs.isEmpty { isSelectionMode = false }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func insert(_ item: YCWorkItem) {
        works.insert(item, at: 0)
    }
}
