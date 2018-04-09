//
//  TLBundle.swift
//  Pods
//
//  Created by wade.hawk on 2017. 5. 9..
//
//

import Foundation

class TLBundle {
    class func resourceBundle(classCoder: AnyClass) -> Bundle {
        let bundle = Bundle(for: classCoder)
        if let url = bundle.url(forResource: "TLPhotoPicker", withExtension: "bundle") {
            return Bundle(url: url)!
        }else {
            print("test charthage")
            return bundle
        }
    }
    class func podBundleImage(named: String) -> UIImage? {
        let podBundle = Bundle(for: TLBundle.self)
        if let url = podBundle.url(forResource: "TLPhotoPickerImage", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: named, in: bundle, compatibleWith: nil)!
        }
        return nil
    }
}
