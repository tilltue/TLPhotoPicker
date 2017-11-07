//
//  CustomCell_Instagram.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2017. 5. 15..
//  Copyright © 2017년 CocoaPods. All rights reserved.
//

import Foundation
import TLPhotoPicker
import PhotosUI

class CustomCell_Instagram: TLPhotoCollectionViewCell {
    
    let selectedColor = UIColor(red: 88/255, green: 144/255, blue: 255/255, alpha: 1.0)
    
    override var duration: TimeInterval? {
        didSet {
            self.durationLabel?.isHidden = self.duration == nil ? true : false
            guard let duration = self.duration else { return }
            self.durationLabel?.text = timeFormatted(timeInterval: duration)
        }
    }
    
    override var isCameraCell: Bool {
        didSet {
            self.orderLabel?.isHidden = self.isCameraCell
        }
    }
    
    override public var selectedAsset: Bool {
        willSet(newValue) {
            self.orderLabel?.layer.borderColor = newValue ? self.selectedColor.cgColor : UIColor.white.cgColor
            self.orderLabel?.backgroundColor = newValue ? self.selectedColor : UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.durationView?.backgroundColor = UIColor.clear
        self.orderLabel?.clipsToBounds = true
        self.orderLabel?.layer.cornerRadius = 10
        self.orderLabel?.layer.borderWidth = 1
        self.orderLabel?.layer.borderColor = UIColor.white.cgColor
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        self.durationView?.backgroundColor = UIColor.clear
    }
}
