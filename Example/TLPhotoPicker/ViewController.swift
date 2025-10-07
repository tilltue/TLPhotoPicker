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
        let viewController = CustomPhotoPickerViewController()
        viewController.modalPresentationStyle = .fullScreen
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Modern builder pattern
        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)
            .maxSelection(Constants.maxSelectionCount)

        viewController.selectedAssets = self.selectedAssets
        viewController.logDelegate = self

        present(viewController, animated: true)
    }

    /// Example 2: Video recording only mode (using preset)
    @IBAction func onlyVideoRecording(_ sender: Any) {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Using preset with customization
        viewController.configure = .videoOnly
            .numberOfColumns(Constants.defaultColumns)
            .allowPhotograph(false)
            .allowVideoRecording(true)

        viewController.selectedAssets = self.selectedAssets
        viewController.logDelegate = self

        present(viewController, animated: true)
    }

    /// Example 3: Custom camera cell
    @IBAction func pickerWithCustomCameraCell() {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Builder pattern with custom camera cell
        if #available(iOS 10.2, *) {
            viewController.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
                .cameraCellNib(name: "CustomCameraCell", bundle: .main)
        } else {
            viewController.configure = TLPhotosPickerConfigure()
                .numberOfColumns(Constants.defaultColumns)
        }

        viewController.selectedAssets = self.selectedAssets
        present(viewController.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 4: Custom black style UI
    @IBAction func pickerWithCustomBlackStyle() {
        let viewController = CustomBlackStylePickerViewController()
        viewController.modalPresentationStyle = .fullScreen
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)

        viewController.selectedAssets = self.selectedAssets
        present(viewController, animated: true)
    }

    /// Example 5: Picker with navigation controller
    @IBAction func pickerWithNavigation() {
        let viewController = PhotoPickerWithNavigationViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)

        viewController.selectedAssets = self.selectedAssets

        present(viewController.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 6: Custom selection rules (size requirement)
    @IBAction func pickerWithCustomRules() {
        let viewController = PhotoPickerWithNavigationViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Custom selection validation
        viewController.canSelectAsset = { [weak self] asset -> Bool in
            guard let self = self else { return false }

            // Require specific dimensions
            let isValidSize = asset.pixelHeight == Int(Constants.requiredImageSize) &&
                            asset.pixelWidth == Int(Constants.requiredImageSize)

            if !isValidSize {
                self.showUnsatisfiedSizeAlert(vc: viewController)
                return false
            }
            return true
        }

        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)
            .photoCellNib(name: "CustomCell_Instagram", bundle: .main)

        viewController.selectedAssets = self.selectedAssets

        present(viewController.wrapNavigationControllerWithoutBar(), animated: true)
    }

    /// Example 7: Custom layout with date grouping
    @IBAction func pickerWithCustomLayout() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        viewController.customDataSouces = CustomDataSources()

        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)
            .groupBy(.day)

        viewController.selectedAssets = self.selectedAssets
        viewController.logDelegate = self

        present(viewController, animated: true)
    }

    // MARK: - Modern API Examples

    /// Example 8: Single photo selection (using preset)
    @IBAction func singlePhotoSelection() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Using single photo preset
        viewController.configure = .singlePhoto
            .selectedColor(.systemPurple)

        viewController.selectedAssets = self.selectedAssets

        present(viewController, animated: true)
    }

    /// Example 9: Compact grid layout (using preset)
    @IBAction func compactGridLayout() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        // Using compact grid preset
        viewController.configure = .compactGrid
            .maxSelection(10)
            .selectedColor(.systemBlue)

        viewController.selectedAssets = self.selectedAssets

        present(viewController, animated: true)
    }

    /// Example 10: Async/Await image loading (iOS 13+)
    @IBAction func asyncAwaitExample() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self

        setupCommonHandlers(for: viewController)

        viewController.configure = TLPhotosPickerConfigure()
            .numberOfColumns(Constants.defaultColumns)
            .maxSelection(5)

        viewController.selectedAssets = self.selectedAssets

        present(viewController, animated: true)
    }

    // MARK: - Helper Methods

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
            let alert = UIAlertController(
                title: "Photo Library Access Required",
                message: "Please grant photo library access in Settings to select photos.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please grant camera access in Settings to take photos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        picker.present(alert, animated: true)
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
