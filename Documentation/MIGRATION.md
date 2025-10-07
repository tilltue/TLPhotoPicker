# Migration Guide

Guide for upgrading TLPhotoPicker across versions.

## Table of Contents

- [Upgrading to 2.1.x](#upgrading-to-21x)
- [Upgrading from 1.x to 2.x](#upgrading-from-1x-to-2x)
- [Breaking Changes](#breaking-changes)
- [Deprecated APIs](#deprecated-apis)

## Upgrading to 2.1.x

### What's New

- ✅ **Async/Await Support** - Modern Swift concurrency
- ✅ **Builder Pattern** - Fluent configuration API
- ✅ **iOS 13+ Support** - Minimum deployment target raised
- ✅ **UniformTypeIdentifiers** - Modern type identifiers
- ✅ **Performance Improvements** - Better memory management
- ✅ **Privacy Manifest** - App Store privacy requirements

### Requirements Changed

```diff
- iOS 9.1+
+ iOS 13.0+

- Swift 4.2 support via version 1.8.3
+ Swift 5.0+ only
```

### New Features

#### Async/Await (iOS 13+)

**Before (Callback):**
```swift
selectedAssets.first?.cloudImageDownload(
    progressBlock: { progress in
        print("Progress: \(progress)")
    },
    completionBlock: { image in
        self.imageView.image = image
    }
)
```

**After (Async/Await):**
```swift
Task {
    if let image = await selectedAssets.first?.fullResolutionImage() {
        await MainActor.run {
            self.imageView.image = image
        }
    }
}
```

#### Builder Pattern

**Before (Manual Configuration):**
```swift
var configure = TLPhotosPickerConfigure()
configure.numberOfColumn = 3
configure.maxSelectedAssets = 20
configure.allowedVideo = true
configure.selectedColor = .systemBlue
picker.configure = configure
```

**After (Builder Pattern):**
```swift
picker.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .maxSelection(20)
    .allowVideo(true)
    .selectedColor(.systemBlue)
```

**Or Use Presets:**
```swift
picker.configure = .singlePhoto
picker.configure = .videoOnly
    .selectedColor(.systemBlue)
```

### Privacy Manifest

TLPhotoPicker 2.1.12+ includes `PrivacyInfo.xcprivacy` for App Store requirements.

**What's Included:**
- Photo Library access (for reading/selecting photos)
- Camera access (for taking photos/videos)
- Privacy-preserving data handling

No action required - the manifest is automatically included.

## Upgrading from 1.x to 2.x

### Major Changes

1. **Swift Version**
   - Swift 4.2 → Swift 5.0+

2. **iOS Version**
   - iOS 9.1 → iOS 13.0+

3. **API Changes**
   - Some delegate methods now optional
   - Improved closure support
   - Better async handling

### Migration Steps

#### Step 1: Update Dependencies

**CocoaPods:**
```ruby
# Before
pod 'TLPhotoPicker', '~> 1.8'

# After
pod 'TLPhotoPicker', '~> 2.1'
```

**Swift Package Manager:**
```swift
// Before
.package(url: "https://github.com/tilltue/TLPhotoPicker.git", from: "1.8.0")

// After
.package(url: "https://github.com/tilltue/TLPhotoPicker.git", from: "2.1.0")
```

#### Step 2: Update Deployment Target

**Xcode Project Settings:**
```diff
- Deployment Target: iOS 9.1
+ Deployment Target: iOS 13.0
```

#### Step 3: Update Code

**Delegate Methods:**

Most delegate methods are now optional with default implementations:

```swift
// Before: All methods required
extension ViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // Required
    }

    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // Required (even if unused)
    }

    func photoPickerDidCancel() {
        // Required
    }

    func dismissComplete() {
        // Required
    }

    // ... all other methods required
}

// After: Only implement what you need
extension ViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // Only this is typically needed
        self.selectedAssets = withTLPHAssets
    }
}
```

**Configuration:**

```swift
// Before: Property assignments
var configure = TLPhotosPickerConfigure()
configure.numberOfColumn = 3
configure.singleSelectedMode = true

// After: Can use builder pattern
picker.configure = TLPhotosPickerConfigure()
    .numberOfColumns(3)
    .singleSelection(true)

// Or continue using property assignments (still supported)
var configure = TLPhotosPickerConfigure()
configure.numberOfColumn = 3
configure.singleSelectedMode = true
```

## Breaking Changes

### Version 2.1.x

#### Removed Deprecated APIs

```swift
// ❌ Removed: Swift 4.2 compatibility
#if swift(<4.1)
// Old code paths removed
#endif
```

#### Changed Minimum Requirements

```swift
// ❌ No longer supported
iOS 9.1 - 12.x
Swift 4.2

// ✅ Required
iOS 13.0+
Swift 5.0+
```

### Version 2.0.x

#### Delegate Methods Optional

```swift
// Before: Implement all methods or compiler error
// After: All methods have default implementations
```

#### Configuration Property Names

Some configuration properties were renamed for consistency:

```diff
// Camera button
- configure.usedCameraButton
+ configure.useCameraButton() // builder method

// Prefetch
- configure.usedPrefetch
+ configure.usedPrefetch // unchanged

// Force touch
- configure.previewAtForceTouch
+ configure.previewAtForceTouch // unchanged
```

## Deprecated APIs

### Currently Deprecated

#### Force Touch / Context Menu Preview

```swift
// Enable preview on long press (disabled by default)
configure.previewAtForceTouch = true
```

**Notes:**
- On iOS 12 and earlier: Uses 3D Touch (if device supports it)
- On iOS 13+: Uses Context Menu API
- Default is `false` (disabled)
- The library automatically handles the appropriate API for each iOS version

#### UIImagePickerController Quality Types

```swift
// ⚠️ Some quality types deprecated
configure.recordingVideoQuality = .type640x480

// ✅ Use modern presets
configure.recordingVideoQuality = .typeMedium
configure.recordingVideoQuality = .typeHigh
```

### Planned Deprecations

None currently planned for 2.1.x.

## Compatibility Notes

### iOS Version Support

| TLPhotoPicker Version | iOS Support | Swift Version |
|----------------------|-------------|---------------|
| 1.8.x                | 9.1+        | 4.2, 5.0      |
| 2.0.x                | 9.1+        | 5.0           |
| 2.1.x                | 13.0+       | 5.0+          |

### Feature Availability

| Feature | iOS 13.0+ | iOS 14.0+ | iOS 15.0+ |
|---------|-----------|-----------|-----------|
| Async/Await | ✅ | ✅ | ✅ |
| Builder Pattern | ✅ | ✅ | ✅ |
| Limited Photo Access | ✅ | ✅ | ✅ |
| Privacy Manifest | ✅ | ✅ | ✅ |
| UniformTypeIdentifiers | ✅ | ✅ | ✅ |

## Common Migration Issues

### Issue 1: Minimum iOS Version

**Error:**
```
'TLPhotoPicker' requires a minimum deployment target of iOS 13.0
```

**Solution:**
Update your project's deployment target to iOS 13.0+.

### Issue 2: Swift Version Mismatch

**Error:**
```
Swift version mismatch
```

**Solution:**
Ensure your project uses Swift 5.0+.

### Issue 3: Missing Delegate Methods

**Error:**
```
Type 'ViewController' does not conform to protocol 'TLPhotosPickerViewControllerDelegate'
```

**Solution:**
This shouldn't occur in 2.1.x as all methods are optional. If it does, check your protocol conformance:

```swift
extension ViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // At minimum, implement this method
    }
}
```

### Issue 4: Closure vs Delegate Confusion

**Symptoms:**
Callbacks not firing.

**Solution:**
Don't mix delegate and closure patterns:

```swift
// ❌ Bad: Mixing patterns
picker.delegate = self
picker.dismissCompletion = { /* Won't be called if delegate is set */ }

// ✅ Good: Use one pattern
// Option 1: Delegate only
picker.delegate = self

// Option 2: Closures only
picker = TLPhotosPickerViewController(withTLPHAssets: { assets in
    // Handle assets
})
```

## Need Help?

- 📖 [Configuration Guide](CONFIGURATION.md)
- 🔧 [Advanced Usage](ADVANCED.md)
- 📚 [API Reference](API.md)
- 🐛 [Report Issues](https://github.com/tilltue/TLPhotoPicker/issues)

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Configuration options
- [Advanced Usage](ADVANCED.md) - Custom cells and delegates
- [API Reference](API.md) - Complete API reference
