//
//  TLAssetsCollection.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 18..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import Photos
import PhotosUI

public struct TLPHAsset {
    enum CloudDownloadState {
        case ready,progress,complete,failed
    }
    var camera: Bool = false
    var state = CloudDownloadState.ready

    public enum AssetType {
        case photo,video,livePhoto
    }
    public var phAsset: PHAsset? = nil
    public var selectedOrder: Int = 0
    public var type: AssetType {
        get {
            guard let phAsset = self.phAsset else { return .photo }
            if phAsset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }else if phAsset.mediaType == .video {
                return .video
            }else {
                return .photo
            }
        }
    }
    public var fullResolutionImage: UIImage? {
        get {
            guard let phAsset = self.phAsset else { return nil }
            return TLPhotoLibrary.fullResolutionImageData(asset: phAsset)
        }
    }
    public var originalFileName: String? {
        get {
            guard let phAsset = self.phAsset,let resource = PHAssetResource.assetResources(for: phAsset).first else { return nil }
            return resource.originalFilename
        }
    }
    
    init(asset: PHAsset?) {
        self.phAsset = asset
    }
}

struct TLAssetsCollection {
    var collection: PHAssetCollection
    var assets = [TLPHAsset]()
    var thumbnail: UIImage? = nil
    //var loadComplete: Bool = false
    var recentPosition: CGPoint = CGPoint.zero
    var title: String {
        get {
            return self.collection.localizedTitle ?? ""
        }
    }
    var count: Int {
        get {
            return self.assets.count
        }
    }
    
    init(collection: PHAssetCollection) {
        self.collection = collection
    }
    
    static func ==(lhs: TLAssetsCollection, rhs: TLAssetsCollection) -> Bool {
        return lhs.collection.localIdentifier == rhs.collection.localIdentifier
    }
}
