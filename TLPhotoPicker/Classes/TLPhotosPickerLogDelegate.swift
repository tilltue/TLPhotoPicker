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
}

extension TLPhotosPickerLogDelegate {
    public func selectedCameraCell(picker: TLPhotosPickerViewController) { }
    public func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    public func selectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    public func selectedAlbum(picker: TLPhotosPickerViewController, collections: [TLAssetsCollection], at: Int) { }
}
