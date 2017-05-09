<p align="center"><img src="./Images/tlphotologo.png" width="700" height="408" /></p>

[![Version](https://img.shields.io/cocoapods/v/TLPhotoPicker.svg?style=flat)](http://cocoapods.org/pods/TLPhotoPicker)
[![License](https://img.shields.io/cocoapods/l/TLPhotoPicker.svg?style=flat)](http://cocoapods.org/pods/TLPhotoPicker)
[![Platform](https://img.shields.io/cocoapods/p/TLPhotoPicker.svg?style=flat)](http://cocoapods.org/pods/TLPhotoPicker)
![Swift](https://img.shields.io/badge/%20in-swift%203.0-orange.svg)

## Written in Swift 3

TLPhotoPicker enables application to pick images and videos from multiple smart album in iOS. like a Facebook app.

| Facebook Picker | TLPhotoPicker  |
| ------------- | ------------- |
| ![Facebook Picker](Images/facebook_ex.gif)  | ![TLPhotoPicker](Images/tlphotopicker_ex.gif)  |

## Features

- support smart album collection. 🏞
(camera roll, selfies, panoramas, favorites, videos, custom users album)
- selected order index.📱
- playback video and live photos.📺
(just one. playback first video or live Photo in bounds of visible cell.)
- display video duration.⏱
- async phasset request and displayed cell.
(scrolling performance is better than facebook in displaying video assets collection.🙋)

## Example

```swift

class ViewController: UIViewController {

var selectedAssets = [TLPHAsset]()
@IBAction func pickerButtonTap() {
let viewController = TLPhotosPickerViewController(completion: { [weak self] (assets) in
self?.selectedAssets = assets
}, didCancel: nil)
var configure = TLPhotosPickerConfigure()
configure.selectedColor = UIColor.red
configure.numberOfColumns = 2
viewController.selectedAssets = selectedAssets
viewController.delegate = self
viewController.configure = configure
self.present(viewController, animated: true, completion: nil)
}
}

extension ViewController: TLPhotosPickerViewControllerDelegate {
func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
self.selectedAssets = withTLPHAssets
}
func dismissPhotoPicker(withPHAssets: [PHAsset]) {

}
func photoPickerDidCancel() {

}
}

```


## Requirements

- Swift 3.0
- iOS 9.1 (live photos)

## Installation

TLPhotoPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TLPhotoPicker"
```

## Author

wade.hawk, junhyi.park@gmail.com

## License

TLPhotoPicker is available under the MIT license. See the LICENSE file for more info.
