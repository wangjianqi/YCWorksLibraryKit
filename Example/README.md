# YCWorksLibraryKit Example

这是 `YCWorksLibraryKit` 的 iOS Example 工程，用于真机或模拟器测试作品库能力。

## 测试内容

- 从系统相册选择图片 / 视频
- 将选中的资源复制到 `Documents/YCWorksLibraryDemo`
- 使用 `YCLocalDemoWorksDataProvider` 扫描测试目录
- 打开 `YCWorksLibraryView` 测试：
  - 作品网格
  - 图片 / 视频浏览
  - 底部缩略图条
  - 筛选 / 排序
  - 多选 / 删除 / 分享 / 收藏 / 重命名
  - 信息面板
  - 图片轻编辑
  - 视频轻编辑

## 使用方式

1. 用 Xcode 打开：

```text
Example/YCWorksLibraryKitExample.xcodeproj
```

2. 选择 `YCWorksLibraryKitExample` Scheme。
3. 运行到 iPhone 真机或模拟器。
4. 点击「从系统相册选择图片 / 视频」。
5. 选择资源后点击「导入选中资源」。
6. 点击「打开 Example 作品库」开始测试。

## 注意

- Example 使用 SwiftUI `PhotosPicker`，只读取用户主动选择的资源。
- 为了便于测试，仍然在工程里配置了 `NSPhotoLibraryUsageDescription`。
- 视频较大时，`PhotosPickerItem.loadTransferable(type: Data.self)` 会占用较高内存。正式 App 可改成基于 `FileRepresentation` 的文件拷贝模式。
