//
//  TLCollectionViewAdapter.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

/// Adapter for UICollectionView delegate/datasource operations
class TLCollectionViewAdapter: NSObject {
    // MARK: - Dependencies
    private let state: TLPhotosPickerState
    private let selectionService: TLPhotoSelectionService
    private let libraryService: TLPhotoLibraryService

    // MARK: - Weak References (ViewController coordination)
    weak var viewController: TLPhotosPickerViewController?

    // MARK: - Configuration
    private var configure: TLPhotosPickerConfigure {
        return state.configure
    }

    // MARK: - UI State
    private var thumbnailSize: CGSize = .zero
    private var placeholderThumbnail: UIImage?
    private var cameraImage: UIImage?

    // MARK: - Queue
    private let queue = DispatchQueue(label: "tilltue.photos.pikcker.queue")

    // MARK: - Initialization
    init(
        state: TLPhotosPickerState,
        selectionService: TLPhotoSelectionService,
        libraryService: TLPhotoLibraryService
    ) {
        self.state = state
        self.selectionService = selectionService
        self.libraryService = libraryService
        super.init()
    }

    // MARK: - Configuration
    func configure(
        thumbnailSize: CGSize,
        placeholderThumbnail: UIImage?,
        cameraImage: UIImage?
    ) {
        self.thumbnailSize = thumbnailSize
        self.placeholderThumbnail = placeholderThumbnail
        self.cameraImage = cameraImage
    }

    // MARK: - Cell Configuration Helpers
    private func getSelectedAssets(_ asset: TLPHAsset) -> TLPHAsset? {
        return selectionService.getSelectedAsset(for: asset)
    }

    func orderUpdateCells(in collectionView: UICollectionView) {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })
        for indexPath in visibleIndexPaths {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { continue }
            guard let asset = state.focusedCollection?.getTLAsset(at: indexPath) else { continue }
            if let selectedAsset = getSelectedAssets(asset) {
                cell.selectedAsset = true
                cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
            } else {
                cell.selectedAsset = false
            }
        }
    }

    // MARK: - Cell Selection Helpers
    func isCameraRow(indexPath: IndexPath, collection: TLAssetsCollection) -> Bool {
        return collection.useCameraButton && indexPath.section == 0 && indexPath.row == 0
    }

    // MARK: - Image Loading
    private func loadImage(
        for asset: PHAsset,
        cell: TLPhotoCollectionViewCell?,
        indexPath: IndexPath,
        tlAsset: TLPHAsset,
        usePrefetch: Bool
    ) {
        if usePrefetch {
            loadImageWithPrefetch(for: asset, cell: cell, indexPath: indexPath, tlAsset: tlAsset)
        } else {
            loadImageWithQueue(for: asset, cell: cell, indexPath: indexPath, tlAsset: tlAsset)
        }
    }

    private func loadImageWithPrefetch(
        for asset: PHAsset,
        cell: TLPhotoCollectionViewCell?,
        indexPath: IndexPath,
        tlAsset: TLPHAsset
    ) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        let requestID = libraryService.loadThumbnail(for: asset, size: thumbnailSize, options: options) { [weak self, weak cell] (image, complete) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self, weak cell] in
                guard let self = self else { return }
                if self.state.requestIDs[indexPath] != nil {
                    cell?.imageView?.image = image
                    cell?.update(with: asset)
                    if self.configure.allowedVideo {
                        cell?.durationView?.isHidden = tlAsset.type != .video
                        cell?.duration = tlAsset.type == .video ? asset.duration : nil
                    }
                    if complete {
                        self.state.requestIDs.removeValue(forKey: indexPath)
                    }
                }
            }
        }
        if requestID > 0 {
            libraryService.trackRequest(requestID, for: indexPath)
        }
    }

    private func loadImageWithQueue(
        for asset: PHAsset,
        cell: TLPhotoCollectionViewCell?,
        indexPath: IndexPath,
        tlAsset: TLPHAsset
    ) {
        queue.async { [weak self, weak cell] in
            guard let self = self else { return }
            let requestID = self.libraryService.loadThumbnail(for: asset, size: self.thumbnailSize) { [weak self, weak cell] (image, complete) in
                DispatchQueue.main.async { [weak self, weak cell] in
                    guard let self = self else { return }
                    if self.state.requestIDs[indexPath] != nil {
                        cell?.imageView?.image = image
                        cell?.update(with: asset)
                        if self.configure.allowedVideo {
                            cell?.durationView?.isHidden = tlAsset.type != .video
                            cell?.duration = tlAsset.type == .video ? asset.duration : nil
                        }
                        if complete {
                            self.state.requestIDs.removeValue(forKey: indexPath)
                        }
                    }
                }
            }
            if requestID > 0 {
                self.libraryService.trackRequest(requestID, for: indexPath)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension TLCollectionViewAdapter: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collection = state.focusedCollection,
              let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else {
            return
        }

        let isCameraRow = isCameraRow(indexPath: indexPath, collection: collection)

        if isCameraRow {
            viewController?.selectCameraCell(cell)
            return
        }

        viewController?.toggleSelection(for: cell, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TLPhotoCollectionViewCell {
            cell.endDisplayingCell()
            cell.stopPlay()
            if indexPath == state.playRequestID?.indexPath {
                state.playRequestID = nil
            }
        }
        libraryService.cancelRequest(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? TLPhotoCollectionViewCell else { return }

        cell.willDisplayCell()

        if configure.usedPrefetch, let collection = state.focusedCollection, let asset = collection.getTLAsset(at: indexPath) {
            if let selectedAsset = getSelectedAssets(asset) {
                cell.selectedAsset = true
                cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
            } else {
                cell.selectedAsset = false
            }
        }

        // Fade-in animation for regular cells only
        if cell.isCameraCell == false && cell.alpha == 0 {
            UIView.transition(with: cell, duration: 0.1, options: .curveEaseIn, animations: {
                cell.alpha = 1
            }, completion: nil)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension TLCollectionViewAdapter: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return state.focusedCollection?.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collection = state.focusedCollection else {
            return 0
        }
        return state.focusedCollection?.sections?[safe: section]?.assets.count ?? collection.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        func makeCell(nibName: String) -> TLPhotoCollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: nibName, for: indexPath) as! TLPhotoCollectionViewCell
            cell.configure = configure
            cell.imageView?.image = placeholderThumbnail
            cell.liveBadgeImageView?.image = nil
            return cell
        }

        guard let collection = state.focusedCollection else {
            let nibName = configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
            return makeCell(nibName: nibName)
        }

        // Check if this is a camera cell
        let isCameraCell = isCameraRow(indexPath: indexPath, collection: collection)

        if isCameraCell {
            if let nibName = configure.cameraCellNibSet?.nibName {
                var cell = makeCell(nibName: nibName)
                cell.isCameraCell = true
                return cell
            } else {
                let nibName = configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
                var cell = makeCell(nibName: nibName)
                cell.isCameraCell = true
                cell.imageView?.image = cameraImage
                return cell
            }
        }

        // Regular photo cell
        let nibName = configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
        var cell = makeCell(nibName: nibName)
        guard let asset = collection.getTLAsset(at: indexPath) else { return cell }

        cell.asset = asset.phAsset

        if let selectedAsset = getSelectedAssets(asset) {
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
        } else {
            cell.selectedAsset = false
        }

        if asset.state == .progress {
            cell.indicator?.startAnimating()
        } else {
            cell.indicator?.stopAnimating()
        }

        if let phAsset = asset.phAsset {
            loadImage(for: phAsset, cell: cell, indexPath: indexPath, tlAsset: asset, usePrefetch: configure.usedPrefetch)

            if configure.allowedLivePhotos {
                cell.liveBadgeImageView?.image = asset.type == .livePhoto ? PHLivePhotoView.livePhotoBadgeImage(options: .overContent) : nil
                cell.livePhotoView?.delegate = asset.type == .livePhoto ? viewController : nil
            }
        }

        // Only set alpha for regular cells, not custom camera cells
        if cell.isCameraCell == false {
            cell.alpha = 0
        }
        return cell
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension TLCollectionViewAdapter: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if configure.usedPrefetch {
            queue.async { [weak self] in
                guard let self = self, let collection = self.state.focusedCollection else { return }
                var assets = [PHAsset]()
                for indexPath in indexPaths {
                    if let asset = collection.getAsset(at: indexPath.row) {
                        assets.append(asset)
                    }
                }
                let scale = max(UIScreen.main.scale, 2)
                let targetSize = CGSize(width: self.thumbnailSize.width * scale, height: self.thumbnailSize.height * scale)
                self.libraryService.startCaching(for: assets, targetSize: targetSize)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if configure.usedPrefetch {
            for indexPath in indexPaths {
                libraryService.cancelRequest(at: indexPath)
            }
            queue.async { [weak self] in
                guard let self = self, let collection = self.state.focusedCollection else { return }
                var assets = [PHAsset]()
                for indexPath in indexPaths {
                    if let asset = collection.getAsset(at: indexPath.row) {
                        assets.append(asset)
                    }
                }
                let scale = max(UIScreen.main.scale, 2)
                let targetSize = CGSize(width: self.thumbnailSize.width * scale, height: self.thumbnailSize.height * scale)
                self.libraryService.stopCaching(for: assets, targetSize: targetSize)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TLCollectionViewAdapter: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let identifier = viewController?.customDataSouces?.supplementIdentifier(kind: kind) else {
            return UICollectionReusableView()
        }
        let reuseView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                        withReuseIdentifier: identifier,
                                                                        for: indexPath)
        if let section = state.focusedCollection?.sections?[safe: indexPath.section] {
            viewController?.customDataSouces?.configure(supplement: reuseView, section: section)
        }
        return reuseView
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let sections = state.focusedCollection?.sections?[safe: section], sections.title != "camera" {
            return viewController?.customDataSouces?.headerReferenceSize() ?? CGSize.zero
        }
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let sections = state.focusedCollection?.sections?[safe: section], sections.title != "camera" {
            return viewController?.customDataSouces?.footerReferenceSize() ?? CGSize.zero
        }
        return CGSize.zero
    }
}
