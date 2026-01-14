//
//  TLPhotosPickerState.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Photos

/// Centralized state management for TLPhotosPickerViewController
class TLPhotosPickerState {
    // MARK: - Selection State
    var selectedAssets: [TLPHAsset] = []

    // MARK: - Collection State
    var collections: [TLAssetsCollection] = []
    var focusedCollection: TLAssetsCollection?

    // MARK: - Configuration
    var configure: TLPhotosPickerConfigure

    // MARK: - Request Tracking
    var requestIDs: SynchronizedDictionary<IndexPath, PHImageRequestID> = SynchronizedDictionary()
    var playRequestID: (indexPath: IndexPath, requestID: PHImageRequestID)?

    // MARK: - Initialization
    init(configure: TLPhotosPickerConfigure = TLPhotosPickerConfigure()) {
        self.configure = configure
    }

    // MARK: - State Queries
    func isAssetSelected(_ asset: TLPHAsset) -> Bool {
        return selectedAssets.contains(where: { $0.phAsset == asset.phAsset })
    }

    func getSelectedAsset(for asset: TLPHAsset) -> TLPHAsset? {
        return selectedAssets.first(where: { $0.phAsset == asset.phAsset })
    }

    func selectedAssetIndex(for asset: TLPHAsset) -> Int? {
        return selectedAssets.firstIndex(where: { $0.phAsset == asset.phAsset })
    }
}
