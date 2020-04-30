// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TLPhotoPicker",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "TLPhotoPicker",
            targets: ["TLPhotoPicker"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "TLPhotoPicker",
            dependencies: [],
            path: "TLPhotoPicker")
    ]
)
