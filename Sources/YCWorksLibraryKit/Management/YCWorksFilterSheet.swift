import SwiftUI

internal struct YCWorksFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: YCWorkFilter
    @Binding var sort: YCWorkSort

    var body: some View {
        NavigationStack {
            Form {
                Section(YCL10n.string("filter")) {
                    ForEach(YCWorkFilter.allCases) { item in
                        Button {
                            filter = item
                        } label: {
                            HStack {
                                Text(item.localizedTitle)
                                Spacer()
                                if filter == item {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section(YCL10n.string("sort")) {
                    ForEach(YCWorkSort.allCases) { item in
                        Button {
                            sort = item
                        } label: {
                            HStack {
                                Text(item.localizedTitle)
                                Spacer()
                                if sort == item {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(YCL10n.string("filter_and_sort"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(YCL10n.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

internal extension YCWorkFilter {
    var localizedTitle: String {
        switch self {
        case .all: return YCL10n.string("all")
        case .images: return YCL10n.string("images")
        case .videos: return YCL10n.string("videos")
        case .favorites: return YCL10n.string("favorites")
        case .edited: return YCL10n.string("edited")
        case .exported: return YCL10n.string("exported")
        }
    }
}

internal extension YCWorkSort {
    var localizedTitle: String {
        switch self {
        case .createdAtDescending: return YCL10n.string("sort_recent_added")
        case .createdAtAscending: return YCL10n.string("sort_oldest_added")
        case .updatedAtDescending: return YCL10n.string("sort_recent_edited")
        case .fileSizeDescending: return YCL10n.string("sort_file_size")
        case .titleAscending: return YCL10n.string("sort_title")
        }
    }
}
