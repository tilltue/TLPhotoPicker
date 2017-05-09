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

## Usage
- use closure
```swift 
class ViewController: UIViewController,TLPhotosPickerViewControllerDelegate {
    var selectedAssets = [TLPHAsset]()
    @IBAction func pickerButtonTap() {
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
    }
    //TLPhotosPickerViewControllerDelegate
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        self.selectedAssets = withTLPHAssets
    }
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset. 
    }
    func photoPickerDidCancel() {
        // cancel
    }
}
```
- use closure
convenience public init(completion withPHAssets: (([PHAsset]) -> Void)? = nil, didCancel: ((Void) -> Void)? = nil)

convenience public init(completion withTLPHAssets: (([TLPHAsset]) -> Void)? = nil, didCancel: ((Void) -> Void)? = nil)

```

class ViewController: UIViewController,TLPhotosPickerViewControllerDelegate {
    var selectedAssets = [TLPHAsset]()
    @IBAction func pickerButtonTap() {
        let viewController = TLPhotosPickerViewController(completion: { [weak self] (assets) in // TLAssets
            self?.selectedAssets = assets
        }, didCancel: nil)
        self.present(viewController, animated: true, completion: nil)
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
