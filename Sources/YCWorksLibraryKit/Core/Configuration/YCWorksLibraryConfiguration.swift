import Foundation

public struct YCWorksLibraryConfiguration: Sendable {
    public var title: String
    public var allowsSelection: Bool
    public var allowsFavorite: Bool
    public var allowsDelete: Bool
    public var allowsRename: Bool
    public var allowsShare: Bool
    public var allowsExport: Bool
    public var allowsImageEditing: Bool
    public var allowsVideoEditing: Bool
    public var showsInfoPanel: Bool
    public var showsThumbnailStrip: Bool
    public var defaultFilter: YCWorkFilter
    public var defaultSort: YCWorkSort

    public init(
        title: String = "Works Library",
        allowsSelection: Bool = true,
        allowsFavorite: Bool = true,
        allowsDelete: Bool = true,
        allowsRename: Bool = true,
        allowsShare: Bool = true,
        allowsExport: Bool = true,
        allowsImageEditing: Bool = true,
        allowsVideoEditing: Bool = true,
        showsInfoPanel: Bool = true,
        showsThumbnailStrip: Bool = true,
        defaultFilter: YCWorkFilter = .all,
        defaultSort: YCWorkSort = .createdAtDescending
    ) {
        self.title = title
        self.allowsSelection = allowsSelection
        self.allowsFavorite = allowsFavorite
        self.allowsDelete = allowsDelete
        self.allowsRename = allowsRename
        self.allowsShare = allowsShare
        self.allowsExport = allowsExport
        self.allowsImageEditing = allowsImageEditing
        self.allowsVideoEditing = allowsVideoEditing
        self.showsInfoPanel = showsInfoPanel
        self.showsThumbnailStrip = showsThumbnailStrip
        self.defaultFilter = defaultFilter
        self.defaultSort = defaultSort
    }

    public static let `default` = YCWorksLibraryConfiguration(
        title: "Works Library"
    )
}
