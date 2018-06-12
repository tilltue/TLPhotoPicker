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
import MobileCoreServices

public class TLPHAsset {
    
    enum CloudDownloadState {
        case ready, progress, complete, failed
    }
    
    public enum AssetType {
        case photo, video, livePhoto
    }
    
    public enum ImageExtType: String {
        case png, jpg, gif, heic
    }
    
    var state = CloudDownloadState.ready
    public var phAsset: PHAsset? = nil
    public var selectedOrder: Int = 0
    public var type: AssetType {
        get {
            guard let phAsset = self.phAsset else { return .photo }
            if phAsset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            } else if phAsset.mediaType == .video {
                return .video
            } else {
                return .photo
            }
        }
    }
    
    private var _fullResolutionImage: UIImage?
    public var fullResolutionImage: UIImage? {
        set {
            _fullResolutionImage = newValue
        }
        get {
            if let image = _fullResolutionImage {
                return image
            }
            guard let phAsset = self.phAsset else { return nil }
            return TLPhotoLibrary.fullResolutionImageData(asset: phAsset)
        }
    }
    
    public var url: URL?
    
    public func extType() -> ImageExtType {
        var ext = ImageExtType.png
        if let fileName = self.originalFileName, let extention = URL(string: fileName)?.pathExtension.lowercased() {
            ext = ImageExtType(rawValue: extention) ?? .png
        }
        return ext
    }
    
    public lazy var localIdentifier = UUID().uuidString
    @discardableResult
    public func cloudImageDownload(progressBlock: @escaping (Double) -> Void, completionBlock:@escaping (UIImage?)-> Void ) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        return TLPhotoLibrary.cloudImageDownload(asset: phAsset, progressBlock: progressBlock, completionBlock: completionBlock)
    }
    
    public var originalFileName: String? {
        get {
            guard let phAsset = self.phAsset,let resource = PHAssetResource.assetResources(for: phAsset).first else { return nil }
            return resource.originalFilename
        }
    }
    
    public func photoSize(options: PHImageRequestOptions? = nil ,completion: @escaping ((Int)->Void), livePhotoVideoSize: Bool = false) {
        guard let phAsset = self.phAsset, self.type == .photo else { completion(-1); return }
        var resource: PHAssetResource? = nil
        if phAsset.mediaSubtypes.contains(.photoLive) == true, livePhotoVideoSize {
            resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .pairedVideo }.first
        }else {
            resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .photo }.first
        }
        if let fileSize = resource?.value(forKey: "fileSize") as? Int {
            completion(fileSize)
        }else {
            PHImageManager.default().requestImageData(for: phAsset, options: nil) { (data, uti, orientation, info) in
                var fileSize = -1
                if let data = data {
                    let bcf = ByteCountFormatter()
                    bcf.countStyle = .file
                    fileSize = data.count
                }
                DispatchQueue.main.async {
                    completion(fileSize)
                }
            }
        }
    }
    
    public func videoSize(options: PHVideoRequestOptions? = nil, completion: @escaping ((Int)->Void)) {
        guard let phAsset = self.phAsset, self.type == .video else {  completion(-1); return }
        let resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .video }.first
        if let fileSize = resource?.value(forKey: "fileSize") as? Int {
            completion(fileSize)
        }else {
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
    }
    
    func MIMEType(_ url: URL?) -> String? {
        guard let ext = url?.pathExtension else { return nil }
        if !ext.isEmpty {
            let UTIRef = UTTypeCreatePreferredIdentifierForTag("public.filename-extension" as CFString, ext as CFString, nil)
            let UTI = UTIRef?.takeUnretainedValue()
            UTIRef?.release()
            if let UTI = UTI {
                guard let MIMETypeRef = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType) else { return nil }
                let MIMEType = MIMETypeRef.takeUnretainedValue()
                MIMETypeRef.release()
                return MIMEType as String
            }
        }
        return nil
    }
    
    @discardableResult
    public func tempCopyMediaFile(progressBlock:((Double) -> Void)? = nil, completionBlock:@escaping ((URL,String) -> Void)) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        var type: PHAssetResourceType? = nil
        if phAsset.mediaSubtypes.contains(.photoLive) == true {
            type = .pairedVideo
        }else {
            type = phAsset.mediaType == .video ? .video : .photo
        }
        guard let resource = (PHAssetResource.assetResources(for: phAsset).filter{ $0.type == type }).first else { return nil }
        let fileName = resource.originalFilename
        var writeURL: URL? = nil
        if #available(iOS 10.0, *) {
            writeURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName)")
        } else {
            writeURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(fileName)")
        }
        guard let localURL = writeURL,let mimetype = MIMEType(writeURL) else { return nil }
        switch phAsset.mediaType {
        case .video:
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { (progress, error, stop, info) in
                DispatchQueue.main.async {
                    progressBlock?(progress)
                }
            }
            return PHImageManager.default().requestExportSession(forVideo: phAsset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { (session, infoDict) in
                session?.outputURL = localURL
                session?.outputFileType = AVFileType.mov
                session?.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        completionBlock(localURL, mimetype)
                    }
                })
            }
        case .image:
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { (progress, error, stop, info) in
                DispatchQueue.main.async {
                    progressBlock?(progress)
                }
            }
            return PHImageManager.default().requestImageData(for: phAsset, options: options, resultHandler: { (data, uti, orientation, info) in
                do {
                    try data?.write(to: localURL)
                    DispatchQueue.main.async {
                        completionBlock(localURL, mimetype)
                    }
                }catch { }
            })
        default:
            return nil
        }
    }
    
    init(asset: PHAsset?) {
        self.phAsset = asset
    }
    
    public convenience init(image: UIImage) {
        self.init(asset: nil)
        self.fullResolutionImage = image
    }
    
    public convenience init(url: URL) {
        self.init(asset: nil)
        self.url = url
    }
}

extension TLPHAsset: Equatable {
    
    public static func ==(lhs: TLPHAsset, rhs: TLPHAsset) -> Bool {
        if let lphAsset = lhs.phAsset, let rphAsset = rhs.phAsset {
            return lphAsset.localIdentifier == rphAsset.localIdentifier
        } else {
            return lhs.localIdentifier == rhs.localIdentifier
        }
    }
}

public struct TLAssetsCollection {
    var customAssets: [TLPHAsset]? = nil
    var phAssetCollection: PHAssetCollection? = nil
    var fetchResult: PHFetchResult<PHAsset>? = nil
    var thumbnail: UIImage? = nil
    var useCameraButton: Bool = false
    var recentPosition: CGPoint = CGPoint.zero
    var title: String
    var localIdentifier: String
    var count: Int {
        get {
		if let assets = self.customAssets {
                return assets.count
            } else {
                guard let count = self.fetchResult?.count, count > 0 else { return self.useCameraButton ? 1 : 0 }
                return count + (self.useCameraButton ? 1 : 0)
            }
        }
    }
    
    init(collection: PHAssetCollection) {
        self.phAssetCollection = collection
        self.title = collection.localizedTitle ?? ""
        self.localIdentifier = collection.localIdentifier
    }

    public init(assets: [TLPHAsset], title: String?) {
        self.customAssets = assets
        self.thumbnail = assets[0].fullResolutionImage
        self.title = title ?? ""
        self.localIdentifier = UUID().uuidString
    }

    func getAsset(at index: Int) -> PHAsset? {
        if self.useCameraButton && index == 0 { return nil }
        let index = index - (self.useCameraButton ? 1 : 0)
        guard let result = self.fetchResult, index < result.count else { return nil }
        return result.object(at: max(index,0))
    }
    
    func getTLAsset(at index: Int) -> TLPHAsset? {
        if self.useCameraButton && index == 0 { return nil }
        let index = index - (self.useCameraButton ? 1 : 0)
        if let assets = self.customAssets, index < assets.count {
            return assets[index]
        } else {
            guard let result = self.fetchResult, index < result.count else { return nil }
            return TLPHAsset(asset: result.object(at: max(index,0)))
        }
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
