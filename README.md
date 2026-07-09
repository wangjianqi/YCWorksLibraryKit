# YCWorksLibraryKit

`YCWorksLibraryKit` is a reusable iOS Swift Package for in-app media works: browsing, management, lightweight image editing, and lightweight video editing.

## Minimum target

- iOS 17.6+
- Swift Package Manager
- SwiftUI + AVFoundation + Core Image
- No third-party dependencies

## Usage

```swift
import SwiftUI
import YCWorksLibraryKit

struct WorksPage: View {
    private let provider = YCLocalDemoWorksDataProvider()

    var body: some View {
        YCWorksLibraryView(
            configuration: .default,
            dataProvider: provider
        )
    }
}
```

## Core flow

```text
Works grid -> Preview -> Info / Share / Favorite / Delete -> Edit -> Save as new work
```

## Notes

This package is intentionally scoped as a V1 reusable module. Advanced features such as AI object removal, AI outpainting, multi-clip timeline editing, cloud sync, album hierarchy, and tagging should be added as separate modules after the core browsing and editing workflow is stable.

## Example 工程

已内置可运行的 iOS Example 工程：

```text
Example/YCWorksLibraryKitExample.xcodeproj
```

Example 支持：

- 使用系统 `PhotosPicker` 从相册选择图片 / 视频；
- 将选中资源复制到 `Documents/YCWorksLibraryDemo`；
- 使用 `YCLocalDemoWorksDataProvider` 扫描测试资源；
- 打开 `YCWorksLibraryView` 测试浏览、管理、图片编辑和视频编辑。

运行步骤：

1. 用 Xcode 打开 `Example/YCWorksLibraryKitExample.xcodeproj`。
2. 选择 `YCWorksLibraryKitExample` Scheme。
3. 运行到真机或模拟器。
4. 点击「从系统相册选择图片 / 视频」。
5. 选择资源后点击「导入选中资源」。
6. 点击「打开 Example 作品库」开始测试。

注意：Example 为了方便验证，使用 `PhotosPickerItem.loadTransferable(type: Data.self)` 导入资源。大视频会占用较高内存，正式项目建议改成基于 `FileRepresentation` 的文件导入方式。

## 2026-07-09 Native Photos Interaction Update

This version adds two iOS Photos-style interactions to the library grid/browser flow:

- The library grid supports a two-finger pinch gesture. Pinching changes the thumbnail size and therefore changes the number of visible items per row, similar to the native Photos grid.
- Opening a work item from the grid now uses an in-place hero zoom transition built with `matchedGeometryEffect`. The preview is presented as a full-screen overlay inside `YCWorksLibraryView`, not through a bottom sheet or modal sheet.

The public `YCWorkPreviewView` initializer remains usable as a standalone full-screen viewer. `YCWorksLibraryView` uses the enhanced hero transition path automatically.
