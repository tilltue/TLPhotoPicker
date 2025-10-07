//
//  TLCameraService.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import UniformTypeIdentifiers

/// Service responsible for camera capture and photo/video creation
class TLCameraService: NSObject {
    // MARK: - Dependencies
    private let state: TLPhotosPickerState
    private let selectionService: TLPhotoSelectionService
    private weak var presentingViewController: UIViewController?

    // MARK: - Callbacks
    var handleNoCameraPermissions: (() -> Void)?
    var didCaptureAsset: ((TLPHAsset) -> Void)?
    weak var logDelegate: TLPhotosPickerLogDelegate?

    // MARK: - Configuration
    private var configure: TLPhotosPickerConfigure {
        return state.configure
    }

    // MARK: - Initialization
    init(
        state: TLPhotosPickerState,
        selectionService: TLPhotoSelectionService,
        presentingViewController: UIViewController?
    ) {
        self.state = state
        self.selectionService = selectionService
        self.presentingViewController = presentingViewController
        super.init()
    }

    // MARK: - Public Methods
    func showCameraIfAuthorized() {
        let cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorization {
        case .authorized:
            showCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] authorized in
                DispatchQueue.main.async {
                    if authorized {
                        self?.showCamera()
                    } else {
                        self?.handleDeniedCameraAuthorization()
                    }
                }
            }
        case .restricted, .denied:
            handleDeniedCameraAuthorization()
        @unknown default:
            break
        }
    }

    // MARK: - Private Methods
    private func showCamera() {
        guard let viewController = presentingViewController else { return }

        // Check max selection limit
        if let maxSelectedAssets = configure.maxSelectedAssets,
           state.selectedAssets.count >= maxSelectedAssets {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        var mediaTypes: [String] = []

        if configure.allowedPhotograph {
            if #available(iOS 14.0, *) {
                mediaTypes.append(UTType.image.identifier)
            } else {
                mediaTypes.append("public.image")
            }
        }

        if configure.allowedVideoRecording {
            if #available(iOS 14.0, *) {
                mediaTypes.append(UTType.movie.identifier)
            } else {
                mediaTypes.append("public.movie")
            }
            picker.videoQuality = configure.recordingVideoQuality
            if let duration = configure.maxVideoDuration {
                picker.videoMaximumDuration = duration
            }
        }

        guard mediaTypes.count > 0 else {
            return
        }

        picker.cameraDevice = configure.defaultToFrontFacingCamera ? .front : .rear
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = false
        picker.delegate = self

        // iPad split view support
        if UIDevice.current.userInterfaceIdiom == .pad {
            picker.modalPresentationStyle = .popover
            picker.popoverPresentationController?.sourceView = viewController.view
            picker.popoverPresentationController?.sourceRect = .zero
        }

        viewController.present(picker, animated: true, completion: nil)
    }

    private func handleDeniedCameraAuthorization() {
        DispatchQueue.main.async { [weak self] in
            self?.handleNoCameraPermissions?()
        }
    }

    private func saveCapturedAsset(image: UIImage? = nil, videoURL: URL? = nil) {
        // Check max selection limit again
        if let maxSelectedAssets = configure.maxSelectedAssets,
           state.selectedAssets.count >= maxSelectedAssets {
            return
        }

        var placeholderAsset: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            if let image = image {
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            } else if let videoURL = videoURL {
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
            }
        }) { [weak self] success, error in
            guard let self = self else { return }

            // Check max selection limit one more time
            if let maxSelectedAssets = self.configure.maxSelectedAssets,
               self.state.selectedAssets.count >= maxSelectedAssets {
                return
            }

            if let error = error {
                let mediaType = image != nil ? "photo" : "video"
                print("[TLPhotoPicker] Failed to save \(mediaType) to library: \(error.localizedDescription)")
                return
            }

            if success, let identifier = placeholderAsset?.localIdentifier {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
                    return
                }

                // Check if asset can be selected
                guard self.selectionService.canSelectAsset(asset) else {
                    return
                }

                var result = TLPHAsset(asset: asset)
                result.selectedOrder = self.state.selectedAssets.count + 1
                result.isSelectedFromCamera = true
                self.state.selectedAssets.append(result)

                self.logDelegate?.selectedPhoto(picker: self.presentingViewController as! TLPhotosPickerViewController, at: 1)
                self.didCaptureAsset?(result)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension TLCameraService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            saveCapturedAsset(image: image)
        } else if let mediaType = info[.mediaType] as? String {
            let isMovieType: Bool
            if #available(iOS 14.0, *) {
                isMovieType = mediaType == UTType.movie.identifier
            } else {
                isMovieType = mediaType == "public.movie"
            }

            if isMovieType, let videoURL = info[.mediaURL] as? URL {
                saveCapturedAsset(videoURL: videoURL)
            }
        }

        picker.dismiss(animated: true, completion: nil)
    }
}
