//
//  TLPhotosPickerConfigure.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2025. 10. 7..
//  Copyright © 2025년 wade.hawk. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

// MARK: - TLPhotosPickerConfigure

public struct TLPhotosPickerConfigure {
    public var customLocalizedTitle: [String: String] = ["Camera Roll": "Camera Roll"]
    public var tapHereToChange = "Tap here to change"
    public var cancelTitle = "Cancel"
    public var doneTitle = "Done"
    public var emptyMessage = "No albums"
    public var selectMessage = "Select"
    public var deselectMessage = "Deselect"
    public var emptyImage: UIImage? = nil
    public var usedCameraButton = true
    public var defaultToFrontFacingCamera = false
    public var usedPrefetch = false
    public var previewAtForceTouch = false
    public var startplayBack: PHLivePhotoViewPlaybackStyle = .hint
    public var allowedLivePhotos = true
    public var allowedVideo = true
    public var allowedAlbumCloudShared = false
    public var allowedPhotograph = true
    public var allowedVideoRecording = true
    public var recordingVideoQuality: UIImagePickerController.QualityType = .typeMedium
    public var maxVideoDuration: TimeInterval? = nil
    public var autoPlay = true
    public var muteAudio = true
    public var preventAutomaticLimitedAccessAlert = true
    public var mediaType: PHAssetMediaType? = nil
    public var numberOfColumn = 3
    public var minimumLineSpacing: CGFloat = 5
    public var minimumInteritemSpacing: CGFloat = 5
    public var singleSelectedMode = false
    public var maxSelectedAssets: Int? = nil
    public var fetchOption: PHFetchOptions? = nil
    public var fetchCollectionOption: [FetchCollectionType: PHFetchOptions] = [:]
    public var selectedColor = UIColor(red: 88/255, green: 144/255, blue: 255/255, alpha: 1.0)
    public var cameraBgColor = UIColor(red: 221/255, green: 223/255, blue: 226/255, alpha: 1)
    public var cameraIcon = TLBundle.podBundleImage(named: "camera")
    public var videoIcon = TLBundle.podBundleImage(named: "video")
    public var placeholderIcon = TLBundle.podBundleImage(named: "insertPhotoMaterial")
    public var nibSet: (nibName: String, bundle: Bundle)? = nil
    public var cameraCellNibSet: (nibName: String, bundle: Bundle)? = nil
    public var fetchCollectionTypes: [(PHAssetCollectionType, PHAssetCollectionSubtype)]? = nil
    public var groupByFetch: PHFetchedResultGroupedBy? = nil
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait
    public var popup: [PopupConfigure] = []

    public init() {

    }

    // MARK: - Builder Methods

    /// Sets the number of columns for the photo grid
    public func numberOfColumns(_ count: Int) -> Self {
        var config = self
        config.numberOfColumn = count
        return config
    }

    /// Sets whether video selection is allowed
    public func allowVideo(_ allowed: Bool) -> Self {
        var config = self
        config.allowedVideo = allowed
        return config
    }

    /// Sets whether live photos are allowed
    public func allowLivePhotos(_ allowed: Bool) -> Self {
        var config = self
        config.allowedLivePhotos = allowed
        return config
    }

    /// Sets the media type filter
    public func mediaType(_ type: PHAssetMediaType?) -> Self {
        var config = self
        config.mediaType = type
        return config
    }

    /// Sets the maximum number of selected assets
    public func maxSelection(_ max: Int?) -> Self {
        var config = self
        config.maxSelectedAssets = max
        return config
    }

    /// Sets whether single selection mode is enabled
    public func singleSelection(_ enabled: Bool) -> Self {
        var config = self
        config.singleSelectedMode = enabled
        return config
    }

    /// Sets whether camera button is used
    public func useCameraButton(_ use: Bool) -> Self {
        var config = self
        config.usedCameraButton = use
        return config
    }

    /// Sets custom camera cell nib
    public func cameraCellNib(name: String, bundle: Bundle) -> Self {
        var config = self
        config.cameraCellNibSet = (nibName: name, bundle: bundle)
        return config
    }

    /// Sets custom photo cell nib
    public func photoCellNib(name: String, bundle: Bundle) -> Self {
        var config = self
        config.nibSet = (nibName: name, bundle: bundle)
        return config
    }

    /// Sets the selected color
    public func selectedColor(_ color: UIColor) -> Self {
        var config = self
        config.selectedColor = color
        return config
    }

    /// Sets grid spacing
    public func spacing(line: CGFloat, interitem: CGFloat) -> Self {
        var config = self
        config.minimumLineSpacing = line
        config.minimumInteritemSpacing = interitem
        return config
    }

    /// Sets whether to allow photography
    public func allowPhotograph(_ allowed: Bool) -> Self {
        var config = self
        config.allowedPhotograph = allowed
        return config
    }

    /// Sets whether to allow video recording
    public func allowVideoRecording(_ allowed: Bool) -> Self {
        var config = self
        config.allowedVideoRecording = allowed
        return config
    }

    /// Sets the recording video quality
    public func recordingQuality(_ quality: UIImagePickerController.QualityType) -> Self {
        var config = self
        config.recordingVideoQuality = quality
        return config
    }

    /// Sets group by fetch option
    public func groupBy(_ groupBy: PHFetchedResultGroupedBy?) -> Self {
        var config = self
        config.groupByFetch = groupBy
        return config
    }

    /// Sets custom localized titles
    public func localizedTitles(_ titles: [String: String]) -> Self {
        var config = self
        config.customLocalizedTitle = titles
        return config
    }
}

// MARK: - Preset Configurations

public extension TLPhotosPickerConfigure {

    /// Default configuration with common settings
    static var `default`: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
    }

    /// Configuration optimized for single photo selection
    static var singlePhoto: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
            .singleSelection(true)
            .allowVideo(false)
            .allowLivePhotos(false)
            .useCameraButton(true)
    }

    /// Configuration for video-only selection
    static var videoOnly: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
            .mediaType(.video)
            .allowPhotograph(false)
            .allowVideoRecording(true)
    }

    /// Configuration for photo-only selection (no videos)
    static var photoOnly: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
            .allowVideo(false)
            .allowLivePhotos(false)
    }

    /// Configuration with compact grid (4 columns)
    static var compactGrid: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
            .numberOfColumns(4)
            .spacing(line: 2, interitem: 2)
    }

    /// Configuration with large grid (2 columns)
    static var largeGrid: TLPhotosPickerConfigure {
        return TLPhotosPickerConfigure()
            .numberOfColumns(2)
            .spacing(line: 10, interitem: 10)
    }
}

// MARK: - FetchCollectionType

public enum FetchCollectionType {
    case assetCollections(PHAssetCollectionType)
    case topLevelUserCollections
}

extension FetchCollectionType: Hashable {
    private var identifier: String {
        switch self {
        case let .assetCollections(collectionType):
            return "assetCollections\(collectionType.rawValue)"
        case .topLevelUserCollections:
            return "topLevelUserCollections"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }
}

// MARK: - PopupConfigure

public enum PopupConfigure {
    case animation(TimeInterval)
}

// MARK: - Platform

public struct Platform {
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
