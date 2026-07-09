// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YCWorksLibraryKit",
    defaultLocalization: "en",
    platforms: [
        .iOS("17.6")
    ],
    products: [
        .library(
            name: "YCWorksLibraryKit",
            targets: ["YCWorksLibraryKit"]
        )
    ],
    targets: [
        .target(
            name: "YCWorksLibraryKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "YCWorksLibraryKitTests",
            dependencies: ["YCWorksLibraryKit"]
        )
    ]
)
