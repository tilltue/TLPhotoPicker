//
//  TLImagePickerAdapter.swift
//
//  Created by Rizwan Ahmed A on 18/12/17.

import UIKit
import Photos



@objc protocol TLImagePickerAdapterDelegate {
    
    func picked(images:[PHAsset]?)
    
}

extension TLImagePickerAdapterDelegate{
    func picked(images:[PHAsset]?){}
    
}

@objc class TLImagePickerAdapter: NSObject {
    
    var selectedAssets = [TLPHAsset]()
    
    
    @objc public var  imageViewController : TLCustomPhotoPickerViewController?
    
    @objc weak var imagePickerDelegate: TLImagePickerAdapterDelegate?
    
    override init() {
        super.init()
        createImagePickerView()
    }
    
    //MARK : Local methdos
    
    func createImagePickerView(){
        imageViewController = TLCustomPhotoPickerViewController()
        imageViewController!.delegate = self
        
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 4
        configure.maxSelectedAssets = 7
        imageViewController!.configure = configure
        imageViewController!.selectedAssets = self.selectedAssets
        
    }

}

extension TLImagePickerAdapter : TLPhotosPickerViewControllerDelegate {
    
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        
    }

    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        self.selectedAssets = withTLPHAssets
    }
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        
        self.imagePickerDelegate?.picked(images: withPHAssets)
        
    }
    
    func photoPickerDidCancel() {
        
    }
    
    func dismissComplete() {
        
    }
   
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        
    }


}

