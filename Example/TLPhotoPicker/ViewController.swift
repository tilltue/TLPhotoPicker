//
//  ViewController.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 05/09/2017.
//  Copyright (c) 2017 wade.hawk. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

class ViewController: UIViewController,TLPhotosPickerViewControllerDelegate {
    
    var selectedAssets = [TLPHAsset]()
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBAction func pickerButtonTap() {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            self?.showAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets

        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func pickerWithCustomCameraCell() {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            self?.showAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        if #available(iOS 10.2, *) {
            configure.cameraCellNibSet = (nibName: "CustomCameraCell", bundle: Bundle.main)
        }
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        self.present(viewController.wrapNavigationControllerWithoutBar(), animated: true, completion: nil)
    }

    @IBAction func pickerWithNavigation() {
        let viewController = PhotoPickerWithNavigationViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            self?.showAlert(vc: picker)
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        self.present(viewController.wrapNavigationControllerWithoutBar(), animated: true, completion: nil)
    }
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        self.selectedAssets = withTLPHAssets
        getFirstSelectedImage()
//        getAsyncCopyTemporaryFile()
    }
    
    func getAsyncCopyTemporaryFile() {
        if let asset = self.selectedAssets.first {
            asset.tempCopyMediaFile(progressBlock: { (progress) in
                print(progress)
            }, completionBlock: { (url, mimeType) in
                print(mimeType)
            })
        }
    }
    
    func getFirstSelectedImage() {
        if let asset = self.selectedAssets.first {
            if asset.type == .video {
                asset.videoSize(completion: { [weak self] (size) in
                    self?.label.text = "video file size\(size)"
                })
                return
            }
            if let image = asset.fullResolutionImage {
                print(image)
                self.label.text = "local storage image"
                self.imageView.image = image
            }else {
                print("Can't get image at local storage, try download image")
                asset.cloudImageDownload(progressBlock: { [weak self] (progress) in
                    DispatchQueue.main.async {
                        self?.label.text = "download \(100*progress)%"
                        print(progress)
                    }
                }, completionBlock: { [weak self] (image) in
                    if let image = image {
                        //use image
                        DispatchQueue.main.async {
                            self?.label.text = "complete download"
                            self?.imageView.image = image
                        }
                    }
                })
            }
        }
    }

    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }

    func photoPickerDidCancel() {
        // cancel
    }

    func dismissComplete() {
        // picker dismiss completion
    }

    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        self.showAlert(vc: picker)
    }

    func showAlert(vc: UIViewController) {
        let alert = UIAlertController(title: "", message: "Exceed Maximum Number Of Selection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }

}
