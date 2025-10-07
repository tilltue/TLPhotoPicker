//
//  TLPhotoLibraryService.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Photos
import UIKit

/// Service responsible for PHPhotoLibrary operations
class TLPhotoLibraryService {
    private let photoLibrary = TLPhotoLibrary()
    private let state: TLPhotosPickerState

    init(state: TLPhotosPickerState) {
        self.state = state
    }

    // MARK: - Configuration
    func configurePhotoLibrary(limitMode: Bool, delegate: TLPhotoLibraryDelegate) {
        photoLibrary.limitMode = limitMode
        photoLibrary.delegate = delegate
    }

    // MARK: - Image Loading
    func loadThumbnail(
        for asset: PHAsset,
        size: CGSize,
        options: PHImageRequestOptions? = nil,
        completion: @escaping (UIImage?, Bool) -> Void
    ) -> PHImageRequestID {
        let requestOptions = options ?? defaultImageOptions()

        return photoLibrary.imageAsset(
            asset: asset,
            size: size,
            options: requestOptions,
            completionBlock: completion
        )
    }

    func cancelRequest(_ requestID: PHImageRequestID) {
        photoLibrary.cancelPHImageRequest(requestID: requestID)
    }

    func cancelRequest(at indexPath: IndexPath) {
        guard let requestID = state.requestIDs[indexPath] else { return }
        cancelRequest(requestID)
        state.requestIDs.removeValue(forKey: indexPath)
    }

    // MARK: - Collection Loading
    func fetchCollections(configure: TLPhotosPickerConfigure) {
        photoLibrary.fetchCollection(configure: configure)
    }

    func setFocusedCollection(_ collection: TLAssetsCollection) {
        state.focusedCollection = collection
    }

    func fetchResult(collection: TLAssetsCollection?, configure: TLPhotosPickerConfigure) -> PHFetchResult<PHAsset>? {
        return photoLibrary.fetchResult(collection: collection, configure: configure)
    }

    func getOption(configure: TLPhotosPickerConfigure) -> PHFetchOptions {
        return photoLibrary.getOption(configure: configure)
    }

    // MARK: - Caching
    func startCaching(for assets: [PHAsset], targetSize: CGSize) {
        photoLibrary.imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    func stopCaching(for assets: [PHAsset], targetSize: CGSize) {
        photoLibrary.imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    // MARK: - Helper Methods
    private func defaultImageOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        return options
    }

    // MARK: - Request Tracking
    func trackRequest(_ requestID: PHImageRequestID, for indexPath: IndexPath) {
        if requestID > 0 {
            state.requestIDs[indexPath] = requestID
        }
    }

    func untrackRequest(for indexPath: IndexPath) {
        state.requestIDs.removeValue(forKey: indexPath)
    }

    func isTracking(indexPath: IndexPath) -> Bool {
        return state.requestIDs[indexPath] != nil
    }
}
