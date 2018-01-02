//
//  TLPhotoLibrary.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 5. 3..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import Photos

protocol TLPhotoLibraryDelegate: class {
    func loadCameraRollCollection(collection: TLAssetsCollection)
    func loadCompleteAllCollection(collections: [TLAssetsCollection])
    func focusCollection(collection: TLAssetsCollection)
}

class TLPhotoLibrary {
    
    weak var delegate: TLPhotoLibraryDelegate? = nil
    
    lazy var imageManager: PHCachingImageManager = {
        return PHCachingImageManager()
    }()
    
    deinit {
//        print("deinit TLPhotoLibrary")
    }
    
    @discardableResult
    func livePhotoAsset(asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), progressBlock: Photos.PHAssetImageProgressHandler? = nil, completionBlock:@escaping (PHLivePhoto,Bool)-> Void ) -> PHImageRequestID {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.progressHandler = progressBlock
        let scale = min(UIScreen.main.scale,2)
        let targetSize = CGSize(width: size.width*scale, height: size.height*scale)
        let requestId = self.imageManager.requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (livePhoto, info) in
            let complete = (info?["PHImageResultIsDegradedKey"] as? Bool) == false
            if let livePhoto = livePhoto {
                completionBlock(livePhoto,complete)
            }
        }
        return requestId
    }
    
    @discardableResult
    func videoAsset(asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), progressBlock: Photos.PHAssetImageProgressHandler? = nil, completionBlock:@escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void ) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        options.progressHandler = progressBlock
        let requestId = self.imageManager.requestPlayerItem(forVideo: asset, options: options, resultHandler: { playerItem, info in
            completionBlock(playerItem,info)
        })
        return requestId
    }

    @discardableResult
    func imageAsset(asset: PHAsset, size: CGSize = CGSize(width: 160, height: 160), options: PHImageRequestOptions? = nil, completionBlock:@escaping (UIImage,Bool)-> Void ) -> PHImageRequestID {
        var options = options
        if options == nil {
            options = PHImageRequestOptions()
            options?.isSynchronous = false
            options?.deliveryMode = .opportunistic
            options?.isNetworkAccessAllowed = true
        }
        let scale = min(UIScreen.main.scale,2)
        let targetSize = CGSize(width: size.width*scale, height: size.height*scale)
        let requestId = self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            let complete = (info?["PHImageResultIsDegradedKey"] as? Bool) == false
            if let image = image {
                completionBlock(image,complete)
            }
        }
        return requestId
    }
    
    func cancelPHImageRequest(requestId: PHImageRequestID) {
        self.imageManager.cancelImageRequest(requestId)
    }
    
    @discardableResult
    class func cloudImageDownload(asset: PHAsset, size: CGSize = PHImageManagerMaximumSize, progressBlock: @escaping (Double) -> Void, completionBlock:@escaping (UIImage?)-> Void ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .exact
        options.progressHandler = { (progress,error,stop,info) in
            progressBlock(progress)
        }
        let requestId = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
            if let data = imageData,let _ = info {
                completionBlock(UIImage(data: data))
            }else{
                completionBlock(nil)//error
            }
        }
        return requestId
    }
    
    @discardableResult
    class func fullResolutionImageData(asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false
        options.version = .current
        var image: UIImage? = nil
        _ = PHCachingImageManager().requestImageData(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
            if let data = imageData {
                image = UIImage(data: data)
            }
        }
        return image
    }
}

//MARK: - Load Collection
extension TLPhotoLibrary {
    func getOption() -> PHFetchOptions {
        let options = PHFetchOptions()
        let sortOrder = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.sortDescriptors = sortOrder
        return options
    }
    
    func fetchResult(collection: TLAssetsCollection?, maxVideoDuration:TimeInterval?=nil, options: PHFetchOptions? = nil) -> PHFetchResult<PHAsset>? {
        guard let phAssetCollection = collection?.phAssetCollection else { return nil }
        let options = options ?? getOption()
        if let duration = maxVideoDuration, phAssetCollection.assetCollectionSubtype == .smartAlbumVideos {
            options.predicate = NSPredicate(format: "mediaType = %i AND duration < %f", PHAssetMediaType.video.rawValue, duration + 1)
        }
        return PHAsset.fetchAssets(in: phAssetCollection, options: options)
    }
    
    func fetchCollection(configure: TLPhotosPickerConfigure) {
        let allowedVideo = configure.allowedVideo
        let useCameraButton = configure.usedCameraButton
        let mediaType = configure.mediaType
        let maxVideoDuration = configure.maxVideoDuration
        let options = configure.fetchOption ?? getOption()
        
        @discardableResult
        func getAlbum(subType: PHAssetCollectionSubtype, result: inout [TLAssetsCollection]) {
            let fetchCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: subType, options: nil)
            var collections = [PHAssetCollection]()
            fetchCollection.enumerateObjects { (collection, index, _) in
                //Why this? : Can't getting image for cloud shared album
                if collection.assetCollectionSubtype != .albumCloudShared {
                    collections.append(collection)
                }
            }
            for collection in collections {
                if !result.contains(where: { $0.localIdentifier == collection.localIdentifier }) {
                    var assetsCollection = TLAssetsCollection(collection: collection)
                    assetsCollection.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                    if assetsCollection.count > 0 {
                        result.append(assetsCollection)
                    }
                }
            }
        }
        
        @discardableResult
        func getSmartAlbum(subType: PHAssetCollectionSubtype, result: inout [TLAssetsCollection]) -> TLAssetsCollection? {
            let fetchCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subType, options: nil)
            if let collection = fetchCollection.firstObject, !result.contains(where: { $0.localIdentifier == collection.localIdentifier }) {
                var assetsCollection = TLAssetsCollection(collection: collection)
                assetsCollection.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                if assetsCollection.count > 0 {
                    result.append(assetsCollection)
                    return assetsCollection
                }
            }
            return nil
        }
        
        if let mediaType = mediaType {
            options.predicate = maxVideoDuration != nil && mediaType == PHAssetMediaType.video ? NSPredicate(format: "mediaType = %i AND duration < %f", mediaType.rawValue, maxVideoDuration! + 1) : NSPredicate(format: "mediaType = %i", mediaType.rawValue)
        } else if !allowedVideo {
            options.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.image.rawValue)
        } else if let duration = maxVideoDuration {
            options.predicate = NSPredicate(format: "mediaType = %i OR (mediaType = %i AND duration < %f)", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue, duration + 1)
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            var assetCollections = [TLAssetsCollection]()
            //Camera Roll
            let camerarollCollection = getSmartAlbum(subType: .smartAlbumUserLibrary, result: &assetCollections)
            if var cameraRoll = camerarollCollection {
                cameraRoll.useCameraButton = useCameraButton
                assetCollections[0] = cameraRoll
                DispatchQueue.main.async {
                    self?.delegate?.focusCollection(collection: cameraRoll)
                    self?.delegate?.loadCameraRollCollection(collection: cameraRoll)
                }
            }
            //Selfies
            getSmartAlbum(subType: .smartAlbumSelfPortraits, result: &assetCollections)
            //Panoramas
            getSmartAlbum(subType: .smartAlbumPanoramas, result: &assetCollections)
            //Favorites
            getSmartAlbum(subType: .smartAlbumFavorites, result: &assetCollections)
            //get all another albums
            getAlbum(subType: .any, result: &assetCollections)
            if allowedVideo {
                //Videos
                getSmartAlbum(subType: .smartAlbumVideos, result: &assetCollections)
            }
            //Album
            let albumsResult = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            albumsResult.enumerateObjects({ (collection, index, stop) -> Void in
                guard let collection = collection as? PHAssetCollection else { return }
                var assetsCollection = TLAssetsCollection(collection: collection)
                assetsCollection.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                if assetsCollection.count > 0, !assetCollections.contains(where: { $0.localIdentifier == collection.localIdentifier }) {
                    assetCollections.append(assetsCollection)
                }
            })
            
            DispatchQueue.main.async {
                self?.delegate?.loadCompleteAllCollection(collections: assetCollections)
            }
        }
    }
}
