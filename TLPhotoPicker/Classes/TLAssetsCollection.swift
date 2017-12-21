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
    @discardableResult
    public func cloudImageDownload(progressBlock: @escaping (Double) -> Void, completionBlock:@escaping (UIImage?)-> Void ) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        return TLPhotoLibrary.cloudImageDownload(asset: phAsset, progressBlock: progressBlock, completionBlock: completionBlock)
    }

    @discardableResult
    public func cloudVideoDownload(progressBlock: @escaping (Double) -> Void, completionBlock:@escaping (AVAssetExportSession?)-> Void ) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        return TLPhotoLibrary.cloudVideoDownload(asset: phAsset, progressBlock: progressBlock, completionBlock: completionBlock)
    }

    public var originalFileName: String? {
        get {
            guard let phAsset = self.phAsset,let resource = PHAssetResource.assetResources(for: phAsset).first else { return nil }
            return resource.originalFilename
        }
    }

    public func videoSize(options: PHVideoRequestOptions? = nil, completion: @escaping ((Int)->Void)) {
        guard let phAsset = self.phAsset, self.type == .video else { return }
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { (avasset, audioMix, info) in
            func fileSize(_ url: URL?) -> Int? {
                do {
                    guard let fileSize = try url?.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return nil }
                    return fileSize
                }catch { return nil }
            }
            var url: URL? = nil
            if let urlAsset = avasset as? AVURLAsset {
                url = urlAsset.url
            }else if let sandboxKeys = info?["PHImageFileSandboxExtensionTokenKey"] as? String, let path = sandboxKeys.components(separatedBy: ";").last {
                url = URL(fileURLWithPath: path)
            }
            let size = fileSize(url) ?? -1
            DispatchQueue.main.async {
                completion(size)
            }
        }
    }
    
    init(asset: PHAsset?) {
        self.phAsset = asset
    }
}

extension TLPHAsset: Equatable {
    public static func ==(lhs: TLPHAsset, rhs: TLPHAsset) -> Bool {
        guard let lphAsset = lhs.phAsset, let rphAsset = rhs.phAsset else { return false }
        return lphAsset.localIdentifier == rphAsset.localIdentifier
    }
}

struct TLAssetsCollection {
    var phAssetCollection: PHAssetCollection? = nil
    var fetchResult: PHFetchResult<PHAsset>? = nil
    var thumbnail: UIImage? = nil
    var useCameraButton: Bool = false
    var recentPosition: CGPoint = CGPoint.zero
    var title: String
    var localIdentifier: String
    var count: Int {
        get {
            guard let count = self.fetchResult?.count, count > 0 else { return 0 }
            return count + (self.useCameraButton ? 1 : 0)
        }
    }
    
    init(collection: PHAssetCollection) {
        self.phAssetCollection = collection
        self.title = collection.localizedTitle ?? ""
        self.localIdentifier = collection.localIdentifier
    }
    
    func getAsset(at index: Int) -> PHAsset? {
        if self.useCameraButton && index == 0 { return nil }
        let index = index - (self.useCameraButton ? 1 : 0)
        return self.fetchResult?.object(at: max(index,0))
    }
    
    func getTLAsset(at index: Int) -> TLPHAsset? {
        if self.useCameraButton && index == 0 { return nil }
        let index = index - (self.useCameraButton ? 1 : 0)
        guard let asset = self.fetchResult?.object(at: max(index,0)) else { return nil }
        return TLPHAsset(asset: asset)
    }
    
    func getAssets(at range: CountableClosedRange<Int>) -> [PHAsset]? {
        let lowerBound = range.lowerBound - (self.useCameraButton ? 1 : 0)
        let upperBound = range.upperBound - (self.useCameraButton ? 1 : 0)
        return self.fetchResult?.objects(at: IndexSet(integersIn: max(lowerBound,0)...min(upperBound,count)))
    }
    
    static func ==(lhs: TLAssetsCollection, rhs: TLAssetsCollection) -> Bool {
        return lhs.localIdentifier == rhs.localIdentifier
    }
}
