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
    var fetchResult: PHFetchResult<PHAsset>? = nil
    var thumbnail: UIImage? = nil
    var useCameraButton: Bool = false
    var recentPosition: CGPoint = CGPoint.zero
    var title: String {
        get {
            return self.collection.localizedTitle ?? ""
        }
    }
    var count: Int {
        get {
            guard let count = self.fetchResult?.count, count > 0 else { return 0 }
            return count + (self.useCameraButton ? 1 : 0)
        }
    }
    
    init(collection: PHAssetCollection) {
        self.collection = collection
    }
    
    func getAsset(at index: Int) -> PHAsset? {
        var index = index - (self.useCameraButton ? 1 : 0)
        return self.fetchResult?.object(at: max(index,0))
    }
    
    func getTLAsset(at index: Int) -> TLPHAsset? {
        var index = index - (self.useCameraButton ? 1 : 0)
        guard let asset = self.fetchResult?.object(at: max(index,0)) else { return nil }
        return TLPHAsset(asset: asset)
    }
    
    func getAssets(at range: CountableClosedRange<Int>) -> [PHAsset]? {
        var lowerBound = range.lowerBound - (self.useCameraButton ? 1 : 0)
        var upperBound = range.upperBound - (self.useCameraButton ? 1 : 0)
        return self.fetchResult?.objects(at: IndexSet(integersIn: max(lowerBound,0)...min(upperBound,count)))
    }
    
    static func ==(lhs: TLAssetsCollection, rhs: TLAssetsCollection) -> Bool {
        return lhs.collection.localIdentifier == rhs.collection.localIdentifier
    }
}
