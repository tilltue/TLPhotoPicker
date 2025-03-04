//
//  TLBundle+SPM.swift
//  
//
//  Created by wade.hawk on 2020/09/20.
//

import Foundation

import UIKit

open class TLBundle {
    static var isPod: Bool = false
    open class func podBundleImage(named: String) -> UIImage? {
        if( !isPod){
            return UIImage(named: named, in: .module, compatibleWith: nil)
        } else {
            let podBundle = Bundle(for: TLBundle.self)
            if let url = podBundle.url(forResource: "TLPhotoPickerController", withExtension: "bundle") {
                let bundle = Bundle(url: url)
                return UIImage(named: named, in: bundle, compatibleWith: nil)
            }
            return nil
        }
    }
    
    class func bundle() -> Bundle {
        let podBundle = Bundle.module
        if let url = podBundle.url(forResource: "TLPhotoPicker", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle ?? podBundle
        }
        return podBundle
    }
}
