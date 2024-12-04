//
//  TLPhotoPermissionsInfoModel.swift
//  TLPhotoPicker
//
//  Created by Viachaslau Holikau on 25.11.24.
//

import Foundation

/// The model of the photo permissions info
public struct TLPhotoPermissionsInfoModel {
    /// Info text for the limited access type to the photo library
    public let limitedAccessInfoText: String
    /// Link text for the limited access type to the photo library
    public let limitedAccessLinkText: String
    /// Info text for the no access type to the photo library
    public let noAccessInfoText: String
    /// Link text for the no access type to the photo library
    public let noAccessLinkText: String
}
