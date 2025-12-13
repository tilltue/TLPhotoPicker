//
//  ViewController.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 05/09/2017.
//  Copyright (c) 2017 wade.hawk. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

/// Main example view controller demonstrating TLPhotoPicker features
class ViewController: UIViewController, TLPhotosPickerViewControllerDelegate {

    // MARK: - Constants

    private enum Constants {
        static let defaultColumns = 3
        static let requiredImageSize: CGFloat = 300
        static let maxSelectionCount = 20
    }

    // MARK: - Properties

    var selectedAssets = [TLPHAsset]()
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!

    // MARK: - Basic Examples

    /// Example 1: Basic photo picker with default settings
    @IBAction func pickerButtonTap() {
        let picker = createPicker(
            CustomPhotoPickerViewController(),
            withLogDelegate: true
        ) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
                .maxSelection(Constants.maxSelectionCount)
        }

        present(picker, animated: true)
    }

    /// Example 2: Video recording only mode (using preset)
    @IBAction func onlyVideoRecording(_ sender: Any) {
        let picker = createPicker(
            CustomPhotoPickerViewController(),
            withLogDelegate: true
        ) { picker in
            picker.configure = .videoOnly
                .numberOfColumns(Constants.defaultColumns)
                .allowPhotograph(false)
                .allowVideoRecording(true)
        }

        present(picker, animated: true)
    }

    /// Example 3: Custom camera cell
    @IBAction func pickerWithCustomCameraCell() {
        let picker = createPicker(CustomPhotoPickerViewController()) { picker in
            if #available(iOS 10.2, *) {
                picker.configure = TLPhotosPickerConfigure()
                    .numberOfColumns(Constants.defaultColumns)
                    .cameraCellNib(name: "CustomCameraCell", bundle: .main)
            } else {
                picker.configure = TLPhotosPickerConfigure()
                    .numberOfColumns(Constants.defaultColumns)
            }
        }

        present(picker.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 4: Custom black style UI
    @IBAction func pickerWithCustomBlackStyle() {
        let picker = createPicker(CustomBlackStylePickerViewController()) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
        }

        present(picker, animated: true)
    }

    /// Example 5: Picker with navigation controller
    @IBAction func pickerWithNavigation() {
        let picker = createPicker(PhotoPickerWithNavigationViewController()) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
        }

        present(picker.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 6: Custom selection rules (size requirement)
    @IBAction func pickerWithCustomRules() {
        let picker = createPicker(PhotoPickerWithNavigationViewController()) { picker in
            // Custom selection validation
            picker.canSelectAsset = { [weak self] asset -> Bool in
                guard let self = self else { return false }

                // Require specific dimensions
                let isValidSize = asset.pixelHeight == Int(Constants.requiredImageSize) &&
                                asset.pixelWidth == Int(Constants.requiredImageSize)

                if !isValidSize {
                    self.showUnsatisfiedSizeAlert(vc: picker)
                    return false
                }
                return true
            }

            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
                .photoCellNib(name: "CustomCell_Instagram", bundle: .main)
        }

        present(picker.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 7: Custom layout with date grouping
    @IBAction func pickerWithCustomLayout() {
        let picker = createPicker(withLogDelegate: true) { picker in
            picker.customDataSouces = CustomDataSources()
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
                .groupBy(.day)
        }

        present(picker, animated: true)
    }

    // MARK: - Modern API Examples

    /// Example 8: Single photo selection (using preset)
    @IBAction func singlePhotoSelection() {
        let picker = createPicker { picker in
            picker.configure = .singlePhoto
                .selectedColor(.systemPurple)
        }

        present(picker, animated: true)
    }

    /// Example 9: Compact grid layout (using preset)
    @IBAction func compactGridLayout() {
        let picker = createPicker { picker in
            picker.configure = .compactGrid
                .maxSelection(10)
                .selectedColor(.systemBlue)
        }

        present(picker, animated: true)
    }

    /// Example 10: Async/Await image loading (iOS 13+)
    @IBAction func asyncAwaitExample() {
        let picker = createPicker { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
                .maxSelection(5)
        }

        present(picker, animated: true)
    }

    // MARK: - Helper Methods

    /// Factory method to create and configure a photo picker with common setup
    ///
    /// This method eliminates boilerplate code by centralizing picker initialization.
    /// All pickers created through this method automatically get:
    /// - Full screen modal presentation
    /// - Delegate set to self
    /// - Common handlers (max selection, permissions)
    /// - Pre-selected assets
    ///
    /// - Parameters:
    ///   - withLogDelegate: Whether to set logDelegate for tracking user interactions
    ///   - configuration: Closure to configure the picker (set configure, custom properties, etc.)
    /// - Returns: Configured TLPhotosPickerViewController ready to present
    private func createPicker(
        withLogDelegate: Bool = false,
        configuration: (TLPhotosPickerViewController) -> Void
    ) -> TLPhotosPickerViewController {
        let picker = TLPhotosPickerViewController()
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        setupCommonHandlers(for: picker)

        configuration(picker)

        picker.selectedAssets = self.selectedAssets

        if withLogDelegate {
            picker.logDelegate = self
        }

        return picker
    }

    /// Factory method for custom picker subclasses
    ///
    /// Use this when you need to instantiate a specific TLPhotosPickerViewController subclass.
    /// All pickers created through this method automatically get:
    /// - Full screen modal presentation
    /// - Delegate set to self
    /// - Common handlers (max selection, permissions)
    /// - Pre-selected assets
    ///
    /// - Parameters:
    ///   - picker: Pre-instantiated picker instance
    ///   - withLogDelegate: Whether to set logDelegate for tracking user interactions
    ///   - configuration: Closure to configure the picker
    /// - Returns: Configured picker ready to present
    private func createPicker<T: TLPhotosPickerViewController>(
        _ picker: T,
        withLogDelegate: Bool = false,
        configuration: (T) -> Void
    ) -> T {
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        setupCommonHandlers(for: picker)

        configuration(picker)

        picker.selectedAssets = self.selectedAssets

        if withLogDelegate {
            picker.logDelegate = self
        }

        return picker
    }

    /// Setup common handlers for picker view controller
    private func setupCommonHandlers(for picker: TLPhotosPickerViewController) {
        picker.didExceedMaximumNumberOfSelection = { [weak self] picker in
            self?.showExceededMaximumAlert(vc: picker)
        }

        picker.handleNoAlbumPermissions = { [weak self] picker in
            self?.handleNoAlbumPermissions(picker: picker)
        }

        picker.handleNoCameraPermissions = { [weak self] picker in
            self?.handleNoCameraPermissions(picker: picker)
        }
    }

    // MARK: - TLPhotosPickerViewControllerDelegate

    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        // Example: Validate before dismissal
        if withTLPHAssets.isEmpty {
            label.text = "Please select at least one item"
            return false
        }
        return true
    }

    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        self.selectedAssets = withTLPHAssets
        label.text = "Selected \(withTLPHAssets.count) item(s)"

        // Load first image
        loadFirstSelectedImage()
    }

    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // Alternative delegate method using PHAssets
    }

    func photoPickerDidCancel() {
        label.text = "Selection cancelled"
    }

    func dismissComplete() {
        print("Picker dismissed")
    }

    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        showExceededMaximumAlert(vc: picker)
    }

    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        picker.dismiss(animated: true) {
            self.showPermissionAlert(
                for: "Photo Library",
                message: "Please grant photo library access in Settings to select photos.",
                on: self
            )
        }
    }

    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        showPermissionAlert(
            for: "Camera",
            message: "Please grant camera access in Settings to take photos.",
            on: picker
        )
    }

    // MARK: - Asset Processing

    /// Load first selected image (with iCloud support)
    private func loadFirstSelectedImage() {
        guard let asset = selectedAssets.first else { return }

        // Handle video
        if asset.type == .video {
            asset.videoSize { [weak self] size in
                let mb = Double(size) / 1_048_576
                self?.label.text = String(format: "Video: %.2f MB", mb)
            }
            return
        }

        // Handle image (local or iCloud)
        if let image = asset.fullResolutionImage {
            // Local image available
            self.label.text = "Local image loaded"
            self.imageView.image = image
        } else {
            // Download from iCloud
            label.text = "Downloading from iCloud..."
            asset.cloudImageDownload(
                progressBlock: { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.label.text = String(format: "Downloading: %.0f%%", progress * 100)
                    }
                },
                completionBlock: { [weak self] image in
                    DispatchQueue.main.async {
                        if let image = image {
                            self?.label.text = "Download complete"
                            self?.imageView.image = image
                        } else {
                            self?.label.text = "Download failed"
                        }
                    }
                }
            )
        }
    }

    /// Load images using async/await (iOS 13+)
    @available(iOS 13.0, *)
    private func loadImagesAsync() {
        Task {
            label.text = "Loading images..."

            let images = await withTaskGroup(of: UIImage?.self) { group in
                for asset in selectedAssets.prefix(5) {
                    group.addTask {
                        await asset.fullResolutionImage()
                    }
                }

                var results: [UIImage] = []
                for await image in group {
                    if let image = image {
                        results.append(image)
                    }
                }
                return results
            }

            await MainActor.run {
                label.text = "Loaded \(images.count) images"
                if let firstImage = images.first {
                    imageView.image = firstImage
                }
            }
        }
    }

    /// Export video file
    private func exportVideo() {
        guard let asset = selectedAssets.first, asset.type == .video else { return }

        label.text = "Exporting video..."

        asset.exportVideoFile(
            progressBlock: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.label.text = String(format: "Exporting: %.0f%%", progress * 100)
                }
            },
            completionBlock: { [weak self] url, mimeType in
                DispatchQueue.main.async {
                    self?.label.text = "Export complete: \(mimeType)"
                    print("Exported to: \(url)")
                }
            }
        )
    }

    /// Copy media file to temporary location
    private func copyMediaFile() {
        guard let asset = selectedAssets.first else { return }

        label.text = "Copying file..."

        asset.tempCopyMediaFile(
            convertLivePhotosToJPG: false,
            progressBlock: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.label.text = String(format: "Copying: %.0f%%", progress * 100)
                }
            },
            completionBlock: { [weak self] url, mimeType in
                DispatchQueue.main.async {
                    self?.label.text = "Copy complete: \(mimeType)"
                    print("Copied to: \(url)")

                    // Remember to clean up temporary file when done
                    // try? FileManager.default.removeItem(at: url)
                }
            }
        )
    }

    // MARK: - Alert Helpers

    /// Generic permission alert with Settings deep-link
    private func showPermissionAlert(for feature: String, message: String, on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "\(feature) Access Required",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)
    }

    private func showExceededMaximumAlert(vc: UIViewController) {
        let alert = UIAlertController(
            title: "Selection Limit Reached",
            message: "You have reached the maximum number of selections.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    private func showUnsatisfiedSizeAlert(vc: UIViewController) {
        let size = Int(Constants.requiredImageSize)
        let alert = UIAlertController(
            title: "Invalid Image Size",
            message: "The required size is \(size) x \(size) pixels.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}

// MARK: - TLPhotosPickerLogDelegate

extension ViewController: TLPhotosPickerLogDelegate {

    func selectedCameraCell(picker: TLPhotosPickerViewController) {
        print("📷 Camera cell tapped")
    }

    func selectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("✅ Photo selected at index: \(index)")
        print("   Total selected: \(picker.selectedAssets.count)")
    }

    func deselectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("❌ Photo deselected at index: \(index)")
        print("   Total selected: \(picker.selectedAssets.count)")
    }

    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at index: Int) {
        print("📁 Album selected: '\(title)' at index: \(index)")
    }
}
