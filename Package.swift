// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TLPhotoPicker",
    platforms: [
        .iOS(.v13)
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
            exclude: [
                "Classes/TLBundle.swift",
                "TLPhotoPicker/Info.plist",
                "TLPhotoPickerController.bundle"
            ],
            resources: [
                .process("Classes/TLCollectionTableViewCell.xib"),
                .process("Classes/TLPhotoCollectionViewCell.xib"),
                .process("Classes/TLPhotosPickerViewController.xib"),
                .process("Assets.xcassets"),
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
