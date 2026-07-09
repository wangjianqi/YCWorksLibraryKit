import SwiftUI

internal struct YCWorkRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    let item: YCWorkItem
    let onRename: (YCWorkItem) -> Void

    init(item: YCWorkItem, onRename: @escaping (YCWorkItem) -> Void) {
        self.item = item
        self.onRename = onRename
        _title = State(initialValue: item.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(YCL10n.string("name"), text: $title)
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle(YCL10n.string("rename"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(YCL10n.string("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(YCL10n.string("done")) {
                        var renamed = item
                        renamed.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        renamed.updatedAt = Date()
                        onRename(renamed)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

internal struct YCWorkRenameMenuButton: View {
    let item: YCWorkItem
    let onRename: (YCWorkItem) -> Void

    @State private var showsRename = false

    var body: some View {
        Button {
            showsRename = true
        } label: {
            Label(YCL10n.string("rename"), systemImage: "pencil")
        }
        .sheet(isPresented: $showsRename) {
            YCWorkRenameSheet(item: item, onRename: onRename)
                .presentationDetents([.height(220)])
        }
    }
}
