//
//  PhotoPickeAutoScrollViewController.swift
//  TLPhotoPicker_Example
//
//  Created by Ali ABBAS on 19/06/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import TLPhotoPicker

class CustomPhotoPickeAutoScrollViewController: TLPhotosPickerViewController {
    override func makeUI() {
        super.makeUI()
        self.customNavItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .stop, target: nil, action: #selector(customAction))
    }
    
    @objc func customAction() {
        self.dismiss(animated: true, completion: nil)
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
