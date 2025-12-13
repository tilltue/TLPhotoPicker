//
//  TLPhotosPickerViewControllerDelegate.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Photos

public protocol TLPhotosPickerViewControllerDelegate: AnyObject {
    func dismissPhotoPicker(withPHAssets: [PHAsset])
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset])
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool
    func dismissComplete()
    func photoPickerDidCancel()
    func canSelectAsset(phAsset: PHAsset) -> Bool
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController)
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController)
}

extension TLPhotosPickerViewControllerDelegate {
    public func deninedAuthoization() { }
    public func dismissPhotoPicker(withPHAssets: [PHAsset]) { }
    public func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) { }
    public func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool { return true }
    public func dismissComplete() { }
    public func photoPickerDidCancel() { }
    public func canSelectAsset(phAsset: PHAsset) -> Bool { return true }
    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) { }
    public func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) { }
    public func handleNoCameraPermissions(picker: TLPhotosPickerViewController) { }
}
