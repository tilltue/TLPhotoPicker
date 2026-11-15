//
//  TLPhotosPickerLogDelegate.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation

//for log
public protocol TLPhotosPickerLogDelegate: AnyObject {
    func selectedCameraCell(picker: TLPhotosPickerViewController)
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int)
    /// Called each time the user finishes dragging the date scrubber, or steps it with VoiceOver.
    func usedDateScrubber(picker: TLPhotosPickerViewController)
}

extension TLPhotosPickerLogDelegate {
    public func selectedCameraCell(picker: TLPhotosPickerViewController) { }
    public func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    public func selectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    public func selectedAlbum(picker: TLPhotosPickerViewController, collections: [TLAssetsCollection], at: Int) { }
    public func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int) { }
    public func usedDateScrubber(picker: TLPhotosPickerViewController) { }
}
