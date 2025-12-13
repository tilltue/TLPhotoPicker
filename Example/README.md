# TLPhotoPicker Example App

Comprehensive example application demonstrating all features of TLPhotoPicker.

## Overview

This example app showcases:
- ✅ Basic photo/video selection
- ✅ Modern Swift patterns (Builder Pattern, Async/Await)
- ✅ Configuration presets
- ✅ Custom UI styling
- ✅ Custom selection rules
- ✅ iCloud download handling
- ✅ Video export functionality
- ✅ Live Photo support

## Examples Included

### 1. Basic Photo Picker
**File:** `ViewController.swift` - `pickerButtonTap()`

Simple photo picker with default settings using modern builder pattern.

```swift
viewController.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .maxSelection(20)
```

### 2. Video Recording Only
**File:** `ViewController.swift` - `onlyVideoRecording()`

Video-only picker using preset configuration.

```swift
viewController.configure = .videoOnly
    .numberOfColumns(3)
    .allowPhotograph(false)
    .allowVideoRecording(true)
```

### 3. Custom Camera Cell
**File:** `ViewController.swift` - `pickerWithCustomCameraCell()`

Custom live camera preview cell.

**Related Files:**
- `CustomCameraCell.swift`
- `CustomCameraCell.xib`

### 4. Custom Black Style
**File:** `ViewController.swift` - `pickerWithCustomBlackStyle()`

Dark theme customization example.

**Related Files:**
- `CustomBlackStylePickerViewController.swift`

### 5. Navigation Controller Integration
**File:** `ViewController.swift` - `pickerWithNavigation()`

Integration with navigation controller.

**Related Files:**
- `PhotoPickerWithNavigationViewController.swift`

### 6. Custom Selection Rules
**File:** `ViewController.swift` - `pickerWithCustomRules()`

Demonstrates custom validation (size requirements).

```swift
viewController.canSelectAsset = { asset -> Bool in
    // Custom validation logic
    return asset.pixelWidth == 300 && asset.pixelHeight == 300
}
```

**Related Files:**
- `CustomCell_Instagram.swift`
- `CustomCell_Instagram.xib`

### 7. Custom Layout (Date Grouping)
**File:** `ViewController.swift` - `pickerWithCustomLayout()`

Photos grouped by date with custom headers.

```swift
viewController.configure = TLPhotosPickerConfigure()
    .groupBy(.day)
```

**Related Files:**
- `CustomDataSources.swift`
- `CustomHeaderView.swift`
- `CustomFooterView.swift`

### 8. Single Photo Selection ⭐ NEW
**File:** `ViewController.swift` - `singlePhotoSelection()`

Using preset for single photo selection.

```swift
viewController.configure = .singlePhoto
    .selectedColor(.systemPurple)
```

### 9. Compact Grid Layout ⭐ NEW
**File:** `ViewController.swift` - `compactGridLayout()`

Instagram-style compact grid.

```swift
viewController.configure = .compactGrid
    .maxSelection(10)
    .selectedColor(.systemBlue)
```

### 10. Async/Await Example ⭐ NEW
**File:** `ViewController.swift` - `asyncAwaitExample()` & `loadImagesAsync()`

Modern Swift concurrency for loading images.

```swift
let images = await withTaskGroup(of: UIImage?.self) { group in
    for asset in selectedAssets {
        group.addTask {
            await asset.fullResolutionImage()
        }
    }
    // Collect results...
}
```

## Advanced Features Demonstrated

### iCloud Download with Progress
**File:** `ViewController.swift` - `loadFirstSelectedImage()`

Shows how to handle iCloud photos with progress indication.

```swift
asset.cloudImageDownload(
    progressBlock: { progress in
        // Update UI with progress (0.0 to 1.0)
    },
    completionBlock: { image in
        // Handle downloaded image
    }
)
```

### Video Export
**File:** `ViewController.swift` - `exportVideo()`

Export video with custom options.

```swift
asset.exportVideoFile(
    progressBlock: { progress in
        // Export progress
    },
    completionBlock: { url, mimeType in
        // Video exported
    }
)
```

### Media File Copying
**File:** `ViewController.swift` - `copyMediaFile()`

Copy media files to temporary location.

```swift
asset.tempCopyMediaFile(
    convertLivePhotosToJPG: false,
    progressBlock: { progress in ... },
    completionBlock: { url, mimeType in ... }
)
```

### shouldDismissPhotoPicker Validation
**File:** `ViewController.swift` - `shouldDismissPhotoPicker(withTLPHAssets:)`

Validate selection before dismissing picker.

```swift
func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
    if withTLPHAssets.isEmpty {
        // Show error and prevent dismissal
        return false
    }
    return true
}
```

## Code Quality Features

### Constants
All magic numbers extracted to constants:

```swift
private enum Constants {
    static let defaultColumns = 3
    static let requiredImageSize: CGFloat = 300
    static let maxSelectionCount = 20
}
```

### Helper Methods
Common setup code extracted:

```swift
private func setupCommonHandlers(for picker: TLPhotosPickerViewController) {
    // Common configuration
}
```

### MARK Comments
Well-organized code sections:
- Basic Examples
- Modern API Examples
- Helper Methods
- TLPhotosPickerViewControllerDelegate
- Asset Processing
- Alert Helpers

### Logging
Comprehensive logging in `TLPhotosPickerLogDelegate`:
- 📷 Camera cell tapped
- ✅ Photo selected
- ❌ Photo deselected
- 📁 Album selected

## Best Practices Demonstrated

### Memory Management
- ✅ `[weak self]` in closures
- ✅ Proper cleanup comments for temporary files

### Error Handling
- ✅ Guard statements
- ✅ Optional unwrapping
- ✅ User-friendly error messages

### UI/UX
- ✅ Progress indication
- ✅ Clear user feedback
- ✅ Settings deep links for permissions

### Modern Swift
- ✅ Builder Pattern
- ✅ Async/Await (iOS 13+)
- ✅ Structured Concurrency
- ✅ String interpolation

## Running the Example

1. Open `TLPhotoPicker.xcworkspace`
2. Select the `TLPhotoPicker-Example` scheme
3. Run on simulator or device
4. Grant photo library permissions when prompted

## Project Structure

```
Example/TLPhotoPicker/
├── ViewController.swift                      # Main examples
├── CustomPhotoPickerViewController.swift     # Custom picker
├── CustomBlackStylePickerViewController.swift # Dark theme
├── PhotoPickerWithNavigationViewController.swift # With nav
├── CustomCameraCell.swift                    # Live camera
├── CustomCell_Instagram.swift                # Instagram-style cell
├── CustomDataSources.swift                   # Custom layout
├── ImagePreviewViewController.swift          # Preview screen
├── Main.storyboard                           # UI layout
└── Various XIB files                         # Custom cells
```

## Key Learnings

### 1. Configuration Patterns

**Traditional:**
```swift
var configure = TLPhotosPickerConfigure()
configure.numberOfColumn = 3
configure.maxSelectedAssets = 20
```

**Modern (Recommended):**
```swift
viewController.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .maxSelection(20)
```

**Preset (Best for common cases):**
```swift
viewController.configure = .singlePhoto
viewController.configure = .videoOnly
viewController.configure = .compactGrid
```

### 2. Delegate vs Closure

**Delegate (for complex logic):**
```swift
class ViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // Handle selection
    }
}
```

**Closure (for simple cases):**
```swift
picker.didExceedMaximumNumberOfSelection = { picker in
    // Handle max selection
}
```

### 3. Asset Loading

**Synchronous (local only):**
```swift
if let image = asset.fullResolutionImage {
    // Use image
}
```

**Asynchronous (with iCloud support):**
```swift
asset.cloudImageDownload(
    progressBlock: { progress in },
    completionBlock: { image in }
)
```

**Modern Async/Await:**
```swift
let image = await asset.fullResolutionImage()
```

## Additional Resources

- [Main Documentation](../README.md)
- [Configuration Guide](../Documentation/CONFIGURATION.md)
- [Advanced Usage](../Documentation/ADVANCED.md)
- [API Reference](../Documentation/API.md)
- [Migration Guide](../Documentation/MIGRATION.md)

## Contributing

Found a bug or want to add an example?
1. Check [existing issues](https://github.com/tilltue/TLPhotoPicker/issues)
2. Create a new issue with example code
3. Submit a pull request

## License

MIT License - See [LICENSE](../LICENSE) file
