//
//  TLPhotoSelectionService.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Photos

/// Result of asset selection operation
enum SelectionResult {
    case selected(order: Int)
    case deselected(previousOrder: Int)
    case limitExceeded
    case notAllowed
}

/// Service responsible for photo selection business logic
class TLPhotoSelectionService {
    private let state: TLPhotosPickerState
    weak var delegate: TLPhotosPickerViewControllerDelegate?

    init(state: TLPhotosPickerState) {
        self.state = state
    }

    // MARK: - Selection Validation
    func canSelectAsset(_ asset: PHAsset) -> Bool {
        let config = state.configure

        // Check maximum selection limit
        if let maxSelectedAssets = config.maxSelectedAssets,
           state.selectedAssets.count >= maxSelectedAssets,
           !state.isAssetSelected(TLPHAsset(asset: asset)) {
            return false
        }

        // Check custom validation from delegate
        if let canSelect = delegate?.canSelectAsset(phAsset: asset), !canSelect {
            return false
        }

        // Check media type restrictions
        if !config.allowedVideo && asset.mediaType == .video {
            return false
        }

        if !config.allowedLivePhotos && asset.mediaSubtypes.contains(.photoLive) {
            return false
        }

        return true
    }

    // MARK: - Selection Operations
    func selectAsset(_ asset: TLPHAsset) -> SelectionResult {
        guard let phAsset = asset.phAsset else {
            return .notAllowed
        }

        // Check if already selected (toggle off)
        if let index = state.selectedAssetIndex(for: asset) {
            let previousOrder = state.selectedAssets[index].selectedOrder
            state.selectedAssets.remove(at: index)

            // Reorder remaining assets
            for i in index..<state.selectedAssets.count {
                state.selectedAssets[i].selectedOrder = i + 1
            }

            return .deselected(previousOrder: previousOrder)
        }

        // Check if can select new asset
        guard canSelectAsset(phAsset) else {
            if let maxSelectedAssets = state.configure.maxSelectedAssets,
               state.selectedAssets.count >= maxSelectedAssets {
                return .limitExceeded
            }
            return .notAllowed
        }

        // Add new selection
        let newOrder = state.selectedAssets.count + 1
        var mutableAsset = asset
        mutableAsset.selectedOrder = newOrder
        state.selectedAssets.append(mutableAsset)

        return .selected(order: newOrder)
    }

    // MARK: - Batch Operations
    func deselectAll() {
        state.selectedAssets.removeAll()
    }

    func selectMultiple(_ assets: [TLPHAsset]) -> [SelectionResult] {
        return assets.map { selectAsset($0) }
    }

    // MARK: - State Queries
    func getSelectedAsset(for asset: TLPHAsset) -> TLPHAsset? {
        return state.getSelectedAsset(for: asset)
    }

    func isSelected(_ asset: TLPHAsset) -> Bool {
        return state.isAssetSelected(asset)
    }

    var selectedCount: Int {
        return state.selectedAssets.count
    }

    var canSelectMore: Bool {
        guard let maxSelectedAssets = state.configure.maxSelectedAssets else {
            return true
        }
        return state.selectedAssets.count < maxSelectedAssets
    }
}
