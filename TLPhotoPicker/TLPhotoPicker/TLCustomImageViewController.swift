//
//  TLCustomImageViewController.swift
//
//  Created by Rizwan Ahmed A on 18/12/17.


import UIKit
import Photos

class TLCustomPhotoPickerViewController: TLPhotosPickerViewController {
    override func makeUI() {
        super.makeUI()
        self.customNavItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .stop, target: nil, action: #selector(customDismissAction))
        
        
    }
    @objc func customDismissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func doneButtonTap() {
        super.doneButtonTap()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    
    
}




