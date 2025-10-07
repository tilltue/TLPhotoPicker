# API Reference

Complete API reference for TLPhotoPicker.

## Table of Contents

- [TLPHAsset](#tlphasset)
- [TLPhotosPickerViewController](#tlphotospickerviewcontroller)
- [TLPhotosPickerConfigure](#tlphotospickerconfigure)
- [Delegates](#delegates)
- [Enumerations](#enumerations)

## TLPHAsset

Wrapper around `PHAsset` with convenient helper methods.

### Properties

```swift
public struct TLPHAsset {
    // Underlying PHAsset
    public var phAsset: PHAsset?

    // Selection order (1-indexed)
    public var selectedOrder: Int

    // Asset type
    public var type: AssetType // .photo, .video, .livePhoto

    // Original file name
    public var originalFileName: String?

    // Indicates if asset was captured from camera
    public var isSelectedFromCamera: Bool

    // Full resolution image (sync, may be nil for iCloud)
    public var fullResolutionImage: UIImage?
}
```

### Asset Type

```swift
public enum AssetType {
    case photo
    case video
    case livePhoto
}
```

### Async Methods

#### fullResolutionImage() async

Get full resolution image using async/await (iOS 13+).

```swift
public func fullResolutionImage() async -> UIImage?
```

**Example:**

```swift
Task {
    if let image = await asset.fullResolutionImage() {
        await MainActor.run {
            imageView.image = image
        }
    }
}
```

#### cloudImageDownload

Download image from iCloud with progress tracking.

```swift
@discardableResult
public func cloudImageDownload(
    progressBlock: @escaping (Double) -> Void,
    completionBlock: @escaping (UIImage?) -> Void
) -> PHImageRequestID?
```

**Parameters:**
- `progressBlock`: Progress callback (0.0 to 1.0)
- `completionBlock`: Completion callback with image

**Returns:** Request ID for cancellation

**Example:**

```swift
asset.cloudImageDownload(
    progressBlock: { progress in
        print("Download: \(Int(progress * 100))%")
    },
    completionBlock: { image in
        guard let image = image else { return }
        self.imageView.image = image
    }
)
```

### File Export Methods

#### tempCopyMediaFile

Export original media file to temporary location.

```swift
@discardableResult
public func tempCopyMediaFile(
    videoRequestOptions: PHVideoRequestOptions? = nil,
    imageRequestOptions: PHImageRequestOptions? = nil,
    livePhotoRequestOptions: PHLivePhotoRequestOptions? = nil,
    exportPreset: String = AVAssetExportPresetHighestQuality,
    convertLivePhotosToJPG: Bool = false,
    progressBlock: ((Double) -> Void)? = nil,
    completionBlock: @escaping ((URL, String) -> Void)
) -> PHImageRequestID?
```

**Parameters:**
- `videoRequestOptions`: Options for video export
- `imageRequestOptions`: Options for image export
- `livePhotoRequestOptions`: Options for Live Photo export
- `exportPreset`: Video export quality preset
- `convertLivePhotosToJPG`:
  - `false`: Export Live Photo as `.mov` file
  - `true`: Export Live Photo as `.jpg`/`.heic` still image
- `progressBlock`: Progress callback
- `completionBlock`: Completion with file URL and MIME type

**Returns:** Request ID for cancellation

**Example:**

```swift
asset.tempCopyMediaFile(
    convertLivePhotosToJPG: false,
    progressBlock: { progress in
        print("Export: \(Int(progress * 100))%")
    },
    completionBlock: { url, mimeType in
        print("Exported to: \(url)")
        print("MIME type: \(mimeType)")

        // Use the file
        self.uploadFile(at: url)

        // Clean up temporary file
        try? FileManager.default.removeItem(at: url)
    }
)
```

**Live Photo Export:**

For complete Live Photo export, call twice:

```swift
// Export still image
asset.tempCopyMediaFile(convertLivePhotosToJPG: true) { imageURL, _ in
    // Save image
}

// Export video component
asset.tempCopyMediaFile(convertLivePhotosToJPG: false) { videoURL, _ in
    // Save video
}
```

#### exportVideoFile

Export video with custom options.

```swift
public func exportVideoFile(
    options: PHVideoRequestOptions? = nil,
    outputURL: URL? = nil,
    outputFileType: AVFileType = .mov,
    progressBlock: ((Double) -> Void)? = nil,
    completionBlock: @escaping ((URL, String) -> Void)
)
```

**Parameters:**
- `options`: Video request options
- `outputURL`: Custom output path (optional)
- `outputFileType`: Export file type (`.mov`, `.mp4`, etc.)
- `progressBlock`: Progress callback
- `completionBlock`: Completion with URL and MIME type

**Example:**

```swift
let outputURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("video.mp4")

asset.exportVideoFile(
    outputURL: outputURL,
    outputFileType: .mp4,
    progressBlock: { progress in
        print("Export: \(Int(progress * 100))%")
    },
    completionBlock: { url, mimeType in
        print("Video exported to: \(url)")
    }
)
```

### Static Methods

#### asset(with:)

Fetch asset by local identifier.

```swift
public static func asset(with localIdentifier: String) -> TLPHAsset?
```

**Parameters:**
- `localIdentifier`: PHAsset local identifier

**Returns:** TLPHAsset if found, nil otherwise

**Example:**

```swift
if let asset = TLPHAsset.asset(with: "some-local-identifier") {
    print("Found asset: \(asset.originalFileName ?? "Unknown")")
}
```

### File Size Methods

#### photoSize

Get photo file size.

```swift
public func photoSize(
    options: PHImageRequestOptions? = nil,
    completion: @escaping (Int) -> Void,
    livePhotoVideoSize: Bool = false
)
```

**Parameters:**
- `options`: Image request options
- `completion`: Completion with size in bytes
- `livePhotoVideoSize`: Include Live Photo video size

**Example:**

```swift
asset.photoSize { bytes in
    let mb = Double(bytes) / 1_048_576
    print("Photo size: \(String(format: "%.2f", mb)) MB")
}
```

#### videoSize

Get video file size.

```swift
public func videoSize(
    options: PHVideoRequestOptions? = nil,
    completion: @escaping (Int) -> Void
)
```

**Example:**

```swift
asset.videoSize { bytes in
    let mb = Double(bytes) / 1_048_576
    print("Video size: \(String(format: "%.2f", mb)) MB")
}
```

## TLPhotosPickerViewController

Main view controller for photo picking.

### Initialization

```swift
public init()
public init(withPHAssets: (([PHAsset]) -> Void)?, didCancel: (() -> Void)?)
public init(withTLPHAssets: (([TLPHAsset]) -> Void)?, didCancel: (() -> Void)?)
```

### Properties

```swift
// Configuration
public var configure: TLPhotosPickerConfigure

// Selected assets
public var selectedAssets: [TLPHAsset]

// Delegates
public weak var delegate: TLPhotosPickerViewControllerDelegate?
public weak var logDelegate: TLPhotosPickerLogDelegate?

// Custom data sources
public var customDataSouces: TLPhotopickerDataSourcesProtocol?

// Closures (alternative to delegate)
public var canSelectAsset: ((PHAsset) -> Bool)?
public var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)?
public var handleNoAlbumPermissions: ((TLPhotosPickerViewController) -> Void)?
public var handleNoCameraPermissions: ((TLPhotosPickerViewController) -> Void)?
public var dismissCompletion: (() -> Void)?
```

### Methods

```swift
// UI customization (override in subclass)
open func makeUI()

// Dismissal
public func dismiss(animated: Bool, completion: (() -> Void)?)
```

## TLPhotosPickerConfigure

Configuration object for the picker.

### Builder Methods

```swift
// Grid layout
public func numberOfColumns(_ count: Int) -> Self
public func spacing(line: CGFloat, interitem: CGFloat) -> Self

// Selection
public func maxSelection(_ count: Int?) -> Self
public func singleSelection(_ enabled: Bool) -> Self

// Media types
public func allowVideo(_ allow: Bool) -> Self
public func allowLivePhotos(_ allow: Bool) -> Self
public func mediaType(_ type: PHAssetMediaType?) -> Self

// Camera
public func useCameraButton(_ use: Bool) -> Self
public func allowPhotograph(_ allow: Bool) -> Self
public func allowVideoRecording(_ allow: Bool) -> Self
public func recordingQuality(_ quality: UIImagePickerController.QualityType) -> Self

// Appearance
public func selectedColor(_ color: UIColor) -> Self
public func cameraBgColor(_ color: UIColor) -> Self

// Custom cells
public func photoCellNib(name: String, bundle: Bundle) -> Self
public func cameraCellNib(name: String, bundle: Bundle) -> Self

// Advanced
public func groupBy(_ grouping: PHFetchedResultGroupedBy?) -> Self
public func localizedTitles(_ titles: [String: String]) -> Self
```

### Presets

```swift
public static var singlePhoto: TLPhotosPickerConfigure
public static var videoOnly: TLPhotosPickerConfigure
public static var photoOnly: TLPhotosPickerConfigure
public static var compactGrid: TLPhotosPickerConfigure
public static var largeGrid: TLPhotosPickerConfigure
```

## Delegates

### TLPhotosPickerViewControllerDelegate

```swift
public protocol TLPhotosPickerViewControllerDelegate: AnyObject {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset])
    func dismissPhotoPicker(withPHAssets: [PHAsset])
    func photoPickerDidCancel()
    func dismissComplete()
    func canSelectAsset(phAsset: PHAsset) -> Bool
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController)
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController)
}
```

All methods are optional (provide default empty implementations).

### TLPhotosPickerLogDelegate

```swift
public protocol TLPhotosPickerLogDelegate: AnyObject {
    func selectedCameraCell(picker: TLPhotosPickerViewController)
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int)
}
```

### TLPhotopickerDataSourcesProtocol

```swift
public protocol TLPhotopickerDataSourcesProtocol {
    func headerReferenceSize() -> CGSize
    func footerReferenceSize() -> CGSize
    func registerSupplementView(collectionView: UICollectionView)
    func supplementIdentifier(kind: String) -> String
    func configure(supplement view: UICollectionReusableView,
                  section: (title: String, assets: [TLPHAsset]))
}
```

## Enumerations

### PHFetchedResultGroupedBy

```swift
public enum PHFetchedResultGroupedBy {
    case year
    case month
    case week
    case day
    case hour
    case custom(dateFormat: String)
}
```

### FetchCollectionType

```swift
public enum FetchCollectionType {
    case assetCollections(PHAssetCollectionType)
    case topLevelUserCollections
}
```

### PopupConfigure

```swift
public enum PopupConfigure {
    case animation(TimeInterval)
}
```

## Helper Classes

### Platform

```swift
public struct Platform {
    public static var isSimulator: Bool
}
```

### TLBundle

```swift
public class TLBundle {
    class func bundle() -> Bundle
    open class func podBundleImage(named: String) -> UIImage?
}
```

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Configuration options
- [Advanced Usage](ADVANCED.md) - Custom cells and delegates
- [Migration Guide](MIGRATION.md) - Upgrading guide
