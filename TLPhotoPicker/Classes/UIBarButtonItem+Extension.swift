//
//  UIBarButtonItem+Extension.swift
//  TLPhotoPicker
//
//  Created by Claude on 2025. 11. 20..
//  Copyright © 2025년 wade.hawk. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    /// Sets the hidesSharedBackground property if available (iOS 18.0+)
    /// Uses KVC for backward compatibility with Xcode 16.2
    func setHidesSharedBackground(_ hides: Bool) {
        if #available(iOS 18.0, *) {
            if self.responds(to: NSSelectorFromString("setHidesSharedBackground:")) {
                self.setValue(hides, forKey: "hidesSharedBackground")
            }
        }
    }
}
