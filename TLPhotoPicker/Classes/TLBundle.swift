//
//  TLBundle.swift
//  Pods
//
//  Created by wade.hawk on 2017. 5. 9..
//
//

import UIKit

open class TLBundle {
    open class func podBundleImage(named: String) -> UIImage? {
        let podBundle = Bundle(for: TLBundle.self)
        if let url = podBundle.url(forResource: "TLPhotoPickerController", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: named, in: bundle, compatibleWith: nil)
        }
        return nil
    }
    
    open class func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let podBundle = Bundle(for: TLBundle.self)
        if let url = podBundle.url(forResource: "TLPhotoPickerController", withExtension: "bundle") {
            if let bundle = Bundle(url: url) {
                let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
                return String(format: format, locale: SharedLocaleManager.shared.locale, arguments: args)
            } else {
                return ""
            }
        }
        return ""
    }
    
    class func bundle() -> Bundle {
        let podBundle = Bundle(for: TLBundle.self)
        if let url = podBundle.url(forResource: "TLPhotoPicker", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle ?? podBundle
        }
        return podBundle
    }
}

public class SharedLocaleManager {
    static let shared = SharedLocaleManager()

    public var locale: Locale = .current
}
