// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TLPhotoPicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TLPhotoPicker",
            targets: ["TLPhotoPicker"]
        ),
    ],
    targets: [
        .target(
            name: "TLPhotoPicker",
            path: "TLPhotoPicker",
            exclude: ["Classes/TLBundle.swift"]
        )
    ]
)
