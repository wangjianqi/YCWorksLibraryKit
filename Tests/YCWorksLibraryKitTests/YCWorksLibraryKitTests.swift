import XCTest
@testable import YCWorksLibraryKit

final class YCWorksLibraryKitTests: XCTestCase {
    func testWorkItemConstruction() {
        let item = YCWorkItem(
            title: "Demo",
            mediaType: .image,
            fileURL: URL(fileURLWithPath: "/tmp/demo.jpg")
        )
        XCTAssertEqual(item.title, "Demo")
        XCTAssertEqual(item.mediaType, .image)
    }

    func testFilterTitlesExist() {
        XCTAssertFalse(YCWorkFilter.allCases.isEmpty)
        XCTAssertFalse(YCWorkSort.allCases.isEmpty)
    }
}
