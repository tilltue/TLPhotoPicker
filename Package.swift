// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TLPhotoPicker",
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
            exclude: ["Classes/TLBundle.swift"],
            resources: [
                .process("TLPhotoPicker/Classes/TLCollectionTableViewCell.xib"),
                .process("TLPhotoPicker/Classes/TLPhotoCollectionViewCell.xib"),
                .process("TLPhotoPicker/Classes/TLPhotosPickerViewController.xib"),
                .process("TLPhotoPicker/Assets.xcassets")
            ]
        )
    ]
)
