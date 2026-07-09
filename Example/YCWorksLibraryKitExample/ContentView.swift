import PhotosUI
import SwiftUI
import YCWorksLibraryKit

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @StateObject private var importer = ExampleAssetImporter()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YCWorksLibraryKit Example")
                            .font(.title2.bold())

                        Text("用于测试作品库的浏览、管理、图片编辑和视频编辑能力。先从系统相册选择测试资源并导入，再进入作品库验证完整链路。")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("测试资源") {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 30,
                        matching: .any(of: [.images, .videos]),
                        photoLibrary: .shared()
                    ) {
                        Label("从系统相册选择图片 / 视频", systemImage: "photo.on.rectangle.angled")
                    }

                    Button {
                        Task {
                            await importer.importItems(selectedItems)
                            selectedItems.removeAll()
                        }
                    } label: {
                        Label(
                            selectedItems.isEmpty ? "导入选中资源" : "导入选中资源（\(selectedItems.count)）",
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .disabled(selectedItems.isEmpty || importer.isImporting)

                    if importer.isImporting {
                        HStack {
                            ProgressView()
                            Text("正在导入测试资源…")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let message = importer.statusMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let errorMessage = importer.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("打开测试页面") {
                    NavigationLink {
                        ExampleWorksLibraryHostView(directoryURL: importer.directoryURL)
                    } label: {
                        Label("打开 Example 作品库", systemImage: "rectangle.grid.3x2")
                    }

                    Button(role: .destructive) {
                        Task { await importer.clearImportedResources() }
                    } label: {
                        Label("清空 Example 测试资源", systemImage: "trash")
                    }
                }

                Section("测试建议") {
                    Text("1. 导入 3 张以上图片，测试网格、预览、缩略图条、筛选、排序、收藏、重命名、分享和删除。")
                    Text("2. 导入 1 个视频，测试播放、视频信息、修剪、静音、旋转、封面时间点和导出。")
                    Text("3. 导入图片后进入编辑页，测试滤镜、调整、旋转、翻转、裁剪和另存为新作品。")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Example")
        }
    }
}

private struct ExampleWorksLibraryHostView: View {
    let directoryURL: URL

    var body: some View {
        YCWorksLibraryView(
            configuration: YCWorksLibraryConfiguration(
                title: "Example 作品库",
                allowsSelection: true,
                allowsFavorite: true,
                allowsDelete: true,
                allowsRename: true,
                allowsShare: true,
                allowsExport: true,
                allowsImageEditing: true,
                allowsVideoEditing: true,
                showsInfoPanel: true,
                showsThumbnailStrip: true,
                defaultFilter: .all,
                defaultSort: .createdAtDescending
            ),
            dataProvider: YCLocalDemoWorksDataProvider(directoryURL: directoryURL)
        )
    }
}
