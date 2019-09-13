//
//  PhotoPickerWithNavigationViewController.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2017. 7. 24..
//  Copyright © 2017년 CocoaPods. All rights reserved.
//

import Foundation
import TLPhotoPicker

class PhotoPickerWithNavigationViewController: TLPhotosPickerViewController {
    override func makeUI() {
        super.makeUI()
        self.customNavItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .stop, target: nil, action: #selector(customAction))
    }
    @objc func customAction() {
        self.delegate?.photoPickerDidCancel()
        self.dismiss(animated: true) { [weak self] in
            self?.delegate?.dismissComplete()
            self?.dismissCompletion?()
        }
    }
    
    override func doneButtonTap() {
        let imagePreviewVC = ImagePreviewViewController()
        imagePreviewVC.assets = self.selectedAssets.first
        self.navigationController?.pushViewController(imagePreviewVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assetSelectionChangedAction = { [weak self] assets in
            self?.activateRightBarButton(!assets.isEmpty)
        }
        assetSelectionChangedAction?(selectedAssets)
    }
    
    private func activateRightBarButton(_ isActive: Bool) {
        UIView.transition(with: view, duration: 0.1, options: .curveEaseInOut, animations: {
            self.customNavItem.rightBarButtonItem?.isEnabled = isActive
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.navigationController?.topViewController is ImagePreviewViewController {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
}
