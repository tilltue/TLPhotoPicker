# Configuration Guide

Complete reference for configuring TLPhotoPicker.

## Table of Contents

- [Basic Configuration](#basic-configuration)
- [Builder Pattern](#builder-pattern)
- [Presets](#presets)
- [Configuration Options](#configuration-options)
- [Advanced Options](#advanced-options)

## Basic Configuration

### Traditional Style

```swift
let viewController = TLPhotosPickerViewController()
var configure = TLPhotosPickerConfigure()
configure.numberOfColumn = 3
configure.maxSelectedAssets = 20
viewController.configure = configure
```

## Builder Pattern

TLPhotoPicker supports a fluent builder pattern for easier configuration.

### Quick Start with Presets

```swift
// Single photo selection
viewController.configure = .singlePhoto

// Video only
viewController.configure = .videoOnly

// Photo only (no videos)
viewController.configure = .photoOnly

// Compact grid (4 columns)
viewController.configure = .compactGrid

// Large grid (2 columns)
viewController.configure = .largeGrid
```

### Builder Chaining

```swift
viewController.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .maxSelection(20)
    .allowVideo(true)
    .allowLivePhotos(true)
    .spacing(line: 5, interitem: 5)
    .selectedColor(.systemPink)
    .useCameraButton(true)
```

### Extend Presets

```swift
// Start with a preset and customize
viewController.configure = .videoOnly
    .numberOfColumns(3)
    .selectedColor(.systemBlue)

// Or customize single photo mode
viewController.configure = .singlePhoto
    .selectedColor(.systemPurple)
    .numberOfColumns(4)
```

## Presets

### `.singlePhoto`
Single photo selection mode.

```swift
picker.configure = .singlePhoto
```

### `.videoOnly`
Video selection only (photos disabled).

```swift
picker.configure = .videoOnly
```

### `.photoOnly`
Photo selection only (videos disabled).

```swift
picker.configure = .photoOnly
```

### `.compactGrid`
4-column compact grid layout.

```swift
picker.configure = .compactGrid
```

### `.largeGrid`
2-column large grid layout.

```swift
picker.configure = .largeGrid
```

## Configuration Options

### Grid Layout

```swift
// Number of columns (default: 3)
.numberOfColumns(Int)

// Spacing between items
.spacing(line: CGFloat, interitem: CGFloat)
```

### Selection Rules

```swift
// Maximum number of selections (default: unlimited)
.maxSelection(Int?)

// Enable single selection mode
.singleSelection(Bool)
```

### Media Types

```swift
// Allow video selection (default: true)
.allowVideo(Bool)

// Allow Live Photos (default: true)
.allowLivePhotos(Bool)

// Filter by media type
.mediaType(PHAssetMediaType?) // .image, .video, .audio
```

### Camera

```swift
// Show camera button (default: true)
.useCameraButton(Bool)

// Allow taking photos (default: true)
.allowPhotograph(Bool)

// Allow video recording (default: true)
.allowVideoRecording(Bool)

// Video recording quality
.recordingQuality(UIImagePickerController.QualityType)
```

### Appearance

```swift
// Selection indicator color
.selectedColor(UIColor)
```

**Note:** Camera background color, icons, and other appearance options can be configured through the property-based API:

```swift
var configure = TLPhotosPickerConfigure()
configure.cameraBgColor = .systemGray
configure.cameraIcon = UIImage(named: "customCamera")
configure.videoIcon = UIImage(named: "customVideo")
configure.placeholderIcon = UIImage(named: "customPlaceholder")
```

### Localization

```swift
// Custom album titles
.localizedTitles([String: String])

// Example:
.localizedTitles([
    "Camera Roll": "모든 사진",
    "Favorites": "즐겨찾기"
])
```

### Custom Cells

```swift
// Custom photo cell
.photoCellNib(name: String, bundle: Bundle)

// Custom camera cell
.cameraCellNib(name: String, bundle: Bundle)
```

## Advanced Options

### Complete Configuration Structure

```swift
public struct TLPhotosPickerConfigure {
    // Localization
    public var customLocalizedTitle: [String: String]
    public var tapHereToChange: String
    public var cancelTitle: String
    public var doneTitle: String
    public var emptyMessage: String
    public var emptyImage: UIImage?

    // Camera
    public var usedCameraButton: Bool
    public var defaultToFrontFacingCamera: Bool
    public var allowedPhotograph: Bool
    public var allowedVideoRecording: Bool
    public var recordingVideoQuality: UIImagePickerController.QualityType
    public var maxVideoDuration: TimeInterval?

    // Media types
    public var allowedLivePhotos: Bool
    public var startplayBack: PHLivePhotoViewPlaybackStyle
    public var allowedVideo: Bool
    public var allowedAlbumCloudShared: Bool
    public var mediaType: PHAssetMediaType?

    // Performance
    public var usedPrefetch: Bool
    public var autoPlay: Bool
    public var muteAudio: Bool

    // Layout
    public var numberOfColumn: Int
    public var minimumLineSpacing: CGFloat
    public var minimumInteritemSpacing: CGFloat

    // Selection
    public var singleSelectedMode: Bool
    public var maxSelectedAssets: Int?

    // Fetch options
    public var fetchOption: PHFetchOptions?
    public var fetchCollectionOption: [FetchCollectionType: PHFetchOptions]
    public var fetchCollectionTypes: [(PHAssetCollectionType, PHAssetCollectionSubtype)]?
    public var groupByFetch: PHFetchedResultGroupedBy?

    // Appearance
    public var selectedColor: UIColor
    public var cameraBgColor: UIColor
    public var cameraIcon: UIImage?
    public var videoIcon: UIImage?
    public var placeholderIcon: UIImage?

    // Custom cells
    public var nibSet: (nibName: String, bundle: Bundle)?
    public var cameraCellNibSet: (nibName: String, bundle: Bundle)?

    // UI
    public var previewAtForceTouch: Bool
    public var preventAutomaticLimitedAccessAlert: Bool
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask
    public var popup: [PopupConfigure]
}
```

### Fetch Collection Types

Control which album types are displayed:

```swift
configure.fetchCollectionTypes = [
    (.smartAlbum, .smartAlbumUserLibrary),
    (.smartAlbum, .smartAlbumFavorites),
    (.album, .albumRegular)
]
```

### Fetch Options

Custom PHFetchOptions for fine-grained control:

```swift
let option = PHFetchOptions()
option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
option.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

configure.fetchOption = option

// Per-collection type options
configure.fetchCollectionOption[.assetCollections(.smartAlbum)] = option
configure.fetchCollectionOption[.topLevelUserCollections] = option
```

### Grouping

Group assets by date (cannot be used with prefetch):

```swift
// Group by date intervals
configure.groupByFetch = .year
configure.groupByFetch = .month
configure.groupByFetch = .week
configure.groupByFetch = .day
configure.groupByFetch = .hour

// Custom date format
configure.groupByFetch = .custom(dateFormat: "yyyy-MM-dd")
```

**Note:** Grouping takes a few seconds for large libraries (~1-1.5s for 5000 images on iPhone X).

### Popup Configuration

```swift
// Animation duration for album popup
configure.popup = [.animation(0.3)]
```

## Examples

### Instagram-style Picker

```swift
viewController.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .maxSelection(10)
    .allowVideo(false)
    .selectedColor(UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0))
    .useCameraButton(true)
```

### Video Recording Only

```swift
viewController.configure = TLPhotosPickerConfigure()
    .mediaType(.video)
    .allowPhotograph(false)
    .allowVideoRecording(true)
    .recordingQuality(.typeHigh)
```

### Custom Camera Cell

```swift
if #available(iOS 10.2, *) {
    viewController.configure = TLPhotosPickerConfigure()
        .numberOfColumns(3)
        .cameraCellNib(name: "CustomCameraCell", bundle: .main)
}
```

### Large Thumbnails with Single Selection

```swift
viewController.configure = TLPhotosPickerConfigure()
    .numberOfColumns(2)
    .singleSelection(true)
    .spacing(line: 10, interitem: 10)
    .selectedColor(.systemBlue)
```

## Related Documentation

- [Advanced Usage](ADVANCED.md) - Custom cells and delegates
- [API Reference](API.md) - TLPHAsset methods
- [Migration Guide](MIGRATION.md) - Upgrading guide
