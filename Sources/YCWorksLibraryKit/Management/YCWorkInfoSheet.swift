import SwiftUI

internal struct YCWorkInfoSheet: View {
    let item: YCWorkItem

    var body: some View {
        NavigationStack {
            List {
                Section {
                    YCInfoRow(title: YCL10n.string("name"), value: item.title)
                    YCInfoRow(title: YCL10n.string("type"), value: item.mediaType == .image ? YCL10n.string("image") : YCL10n.string("video"))
                    YCInfoRow(title: YCL10n.string("created_at"), value: YCDateFormatter.string(from: item.createdAt))
                    YCInfoRow(title: YCL10n.string("updated_at"), value: YCDateFormatter.string(from: item.updatedAt))
                }

                Section {
                    YCInfoRow(title: YCL10n.string("resolution"), value: resolution)
                    YCInfoRow(title: YCL10n.string("file_size"), value: YCFileSizeFormatter.string(from: item.fileSize))
                    if item.mediaType == .video {
                        YCInfoRow(title: YCL10n.string("duration"), value: YCDurationFormatter.string(from: item.duration))
                    }
                    YCInfoRow(title: YCL10n.string("format"), value: item.fileURL.pathExtension.uppercased())
                }

                Section {
                    YCInfoRow(title: YCL10n.string("favorite"), value: item.isFavorite ? YCL10n.string("yes") : YCL10n.string("no"))
                    YCInfoRow(title: YCL10n.string("edited"), value: item.isEdited ? YCL10n.string("yes") : YCL10n.string("no"))
                    YCInfoRow(title: YCL10n.string("exported"), value: item.isExported ? YCL10n.string("yes") : YCL10n.string("no"))
                }

                Section(YCL10n.string("file_path")) {
                    Text(item.fileURL.path)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle(YCL10n.string("info"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var resolution: String {
        if let width = item.width, let height = item.height {
            return "\(width) × \(height)"
        }
        return "—"
    }
}

private struct YCInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
