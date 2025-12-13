# Advanced Usage

Advanced features including custom cells, delegates, selection rules, and UI customization.

## Table of Contents

- [Delegate Methods](#delegate-methods)
- [Closure-based Initialization](#closure-based-initialization)
- [Custom Cells](#custom-cells)
- [Custom Selection Rules](#custom-selection-rules)
- [Log Delegate](#log-delegate)
- [Custom Data Sources](#custom-data-sources)
- [Subclassing](#subclassing)

## Delegate Methods

### TLPhotosPickerViewControllerDelegate

Full delegate protocol:

```swift
protocol TLPhotosPickerViewControllerDelegate: AnyObject {
    // Called before dismissing - return false to prevent dismissal
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool

    // Called when user taps Done
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset])

    // Alternative PHAsset version
    func dismissPhotoPicker(withPHAssets: [PHAsset])

    // Called when user cancels
    func photoPickerDidCancel()

    // Called after picker dismissal completes
    func dismissComplete()

    // Custom selection validation
    func canSelectAsset(phAsset: PHAsset) -> Bool

    // Called when max selection is exceeded
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)

    // Handle permission denied cases
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController)
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController)
}
```

### Basic Implementation

```swift
class ViewController: UIViewController, TLPhotosPickerViewControllerDelegate {
    var selectedAssets = [TLPHAsset]()

    @IBAction func openPhotoPicker() {
        let picker = TLPhotosPickerViewController()
        picker.delegate = self
        present(picker, animated: true)
    }

    // Required
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        self.selectedAssets = withTLPHAssets
        // Process selected assets
    }

    // Optional
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // Use PHAssets directly if preferred
    }

    func photoPickerDidCancel() {
        print("User cancelled")
    }

    func dismissComplete() {
        print("Picker dismissed")
    }
}
```

## Closure-based Initialization

Alternative to delegate pattern:

### Available Closures

```swift
class TLPhotosPickerViewController {
    init(withPHAssets: (([PHAsset]) -> Void)? = nil,
         didCancel: (() -> Void)? = nil)

    init(withTLPHAssets: (([TLPHAsset]) -> Void)? = nil,
         didCancel: (() -> Void)? = nil)

    var canSelectAsset: ((PHAsset) -> Bool)? = nil
    var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)? = nil
    var handleNoAlbumPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    var handleNoCameraPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    var dismissCompletion: (() -> Void)? = nil
}
```

### Example Usage

```swift
class ViewController: UIViewController {
    var selectedAssets = [TLPHAsset]()

    @IBAction func openPhotoPicker() {
        let picker = TLPhotosPickerViewController(
            withTLPHAssets: { [weak self] assets in
                self?.selectedAssets = assets
                print("Selected \(assets.count) assets")
            },
            didCancel: {
                print("Cancelled")
            }
        )

        picker.canSelectAsset = { [weak self] asset in
            // Custom validation
            guard asset.pixelWidth >= 300 else {
                self?.showAlert("Image too small")
                return false
            }
            return true
        }

        picker.didExceedMaximumNumberOfSelection = { [weak self] picker in
            self?.showAlert("Maximum selection reached")
        }

        picker.handleNoAlbumPermissions = { [weak self] picker in
            self?.showPermissionAlert(for: "Photos")
        }

        picker.handleNoCameraPermissions = { [weak self] picker in
            self?.showPermissionAlert(for: "Camera")
        }

        picker.selectedAssets = self.selectedAssets
        present(picker, animated: true)
    }
}
```

## Custom Cells

### Creating Custom Photo Cells

Custom cells must subclass `TLPhotoCollectionViewCell`:

```swift
class CustomCell_Instagram: TLPhotoCollectionViewCell {
    @IBOutlet weak var customImageView: UIImageView!
    @IBOutlet weak var customOverlay: UIView!

    // Called when cell is updated with asset
    override func update(with phAsset: PHAsset) {
        super.update(with: phAsset)

        // Custom display logic
        if phAsset.pixelHeight < 300 || phAsset.pixelWidth < 300 {
            customOverlay.isHidden = false
        } else {
            customOverlay.isHidden = true
        }
    }

    // Called when cell is selected
    override func selectedCell() {
        super.selectedCell()
        // Custom selection animation
    }

    // Called when cell will display
    override func willDisplayCell() {
        super.willDisplayCell()
    }

    // Called when cell ends displaying
    override func endDisplayingCell() {
        super.endDisplayingCell()
    }
}
```

### Register Custom Cell

```swift
var configure = TLPhotosPickerConfigure()
configure.nibSet = (nibName: "CustomCell_Instagram", bundle: Bundle.main)
picker.configure = configure
```

### Custom Camera Cell

Example: Live camera preview cell

```swift
class CustomCameraCell: TLPhotoCollectionViewCell {
    @IBOutlet weak var previewView: UIView!
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func willDisplayCell() {
        super.willDisplayCell()
        setupCamera()
    }

    override func endDisplayingCell() {
        super.endDisplayingCell()
        stopCamera()
    }

    private func setupCamera() {
        guard Platform.isSimulator == false else { return }

        captureSession = AVCaptureSession()
        guard let session = captureSession,
              let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        session.addInput(input)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = previewView.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func stopCamera() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
}
```

Full example: [CustomCameraCell.swift](../Example/TLPhotoPicker/CustomCameraCell.swift)

### Register Custom Camera Cell

```swift
if #available(iOS 10.2, *) {
    var configure = TLPhotosPickerConfigure()
    configure.cameraCellNibSet = (nibName: "CustomCameraCell", bundle: .main)
    picker.configure = configure
}
```

## Custom Selection Rules

### Using Delegate

```swift
extension ViewController: TLPhotosPickerViewControllerDelegate {
    func canSelectAsset(phAsset: PHAsset) -> Bool {
        // Rule 1: Size restriction
        guard phAsset.pixelWidth >= 100, phAsset.pixelHeight >= 100 else {
            showAlert("Image must be at least 100x100 pixels")
            return false
        }

        // Rule 2: Aspect ratio restriction
        let aspectRatio = Double(phAsset.pixelWidth) / Double(phAsset.pixelHeight)
        guard aspectRatio >= 0.5, aspectRatio <= 2.0 else {
            showAlert("Invalid aspect ratio")
            return false
        }

        // Rule 3: Video duration limit
        if phAsset.mediaType == .video {
            guard phAsset.duration <= 60 else {
                showAlert("Video must be under 60 seconds")
                return false
            }
        }

        return true
    }

    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        let maxCount = picker.configure.maxSelectedAssets ?? 0
        showAlert("You can only select up to \(maxCount) items")
    }
}
```

### Using Closure

```swift
picker.canSelectAsset = { [weak self] asset in
    // Custom validation logic
    if asset.pixelWidth < 300 || asset.pixelHeight < 300 {
        self?.showAlert("Image too small")
        return false
    }
    return true
}
```

### Display Rule in Custom Cell

Combine with custom cell for visual feedback:

```swift
class CustomCell: TLPhotoCollectionViewCell {
    @IBOutlet weak var sizeWarningView: UIView!

    override func update(with phAsset: PHAsset) {
        super.update(with: phAsset)

        // Show warning overlay for small images
        let isTooSmall = phAsset.pixelHeight < 300 || phAsset.pixelWidth < 300
        sizeWarningView.isHidden = !isTooSmall
    }
}
```

## Log Delegate

Track user interactions with the picker:

```swift
protocol TLPhotosPickerLogDelegate: AnyObject {
    func selectedCameraCell(picker: TLPhotosPickerViewController)
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int)
}
```

### Implementation

```swift
class ViewController: UIViewController, TLPhotosPickerLogDelegate {
    func selectedCameraCell(picker: TLPhotosPickerViewController) {
        print("Camera cell tapped")
    }

    func selectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("Photo selected at index: \(index)")
        print("Total selected: \(picker.selectedAssets.count)")
    }

    func deselectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("Photo deselected at index: \(index)")
    }

    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at index: Int) {
        print("Album selected: \(title) at index: \(index)")
    }
}

// Set log delegate
picker.logDelegate = self
```

## Custom Data Sources

Add custom header/footer views to collection view:

```swift
protocol TLPhotopickerDataSourcesProtocol {
    func headerReferenceSize() -> CGSize
    func footerReferenceSize() -> CGSize
    func registerSupplementView(collectionView: UICollectionView)
    func supplementIdentifier(kind: String) -> String
    func configure(supplement view: UICollectionReusableView,
                  section: (title: String, assets: [TLPHAsset]))
}
```

### Implementation Example

```swift
class CustomDataSources: TLPhotopickerDataSourcesProtocol {
    func headerReferenceSize() -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 50)
    }

    func footerReferenceSize() -> CGSize {
        return .zero
    }

    func registerSupplementView(collectionView: UICollectionView) {
        collectionView.register(
            CustomHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "CustomHeader"
        )
    }

    func supplementIdentifier(kind: String) -> String {
        return "CustomHeader"
    }

    func configure(supplement view: UICollectionReusableView,
                  section: (title: String, assets: [TLPHAsset])) {
        guard let header = view as? CustomHeaderView else { return }
        header.titleLabel.text = section.title
        header.countLabel.text = "\(section.assets.count) items"
    }
}

// Use custom data sources
let picker = TLPhotosPickerViewController()
picker.customDataSouces = CustomDataSources()
```

## Subclassing

Customize picker behavior by subclassing:

```swift
class CustomPhotoPicker: TLPhotosPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Custom setup
    }

    override func makeUI() {
        super.makeUI()

        // Customize navigation bar
        customNavItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .stop,
            target: self,
            action: #selector(customCancel)
        )

        customNavItem.rightBarButtonItem = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(customDone)
        )

        // Customize appearance
        customNavBar.barTintColor = .systemBlue
        customNavBar.tintColor = .white
    }

    @objc func customCancel() {
        delegate?.photoPickerDidCancel()
        dismiss(animated: true, completion: nil)
    }

    @objc func customDone() {
        delegate?.dismissPhotoPicker(withTLPHAssets: selectedAssets)
        dismiss(animated: true) { [weak self] in
            self?.delegate?.dismissComplete()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Custom logic before appearance
    }
}
```

### Using Subclass

```swift
let picker = CustomPhotoPicker()
picker.delegate = self
present(picker, animated: true)
```

## Permission Handling

Handle permission denied cases gracefully:

```swift
extension ViewController: TLPhotosPickerViewControllerDelegate {
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
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

        picker.present(alert, animated: true)
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
}
```

## Related Documentation

- [Configuration Guide](CONFIGURATION.md) - Configuration options
- [API Reference](API.md) - TLPHAsset and methods
- [Migration Guide](MIGRATION.md) - Upgrading guide
