//
//  TLVideoPlayerService.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import AVFoundation

/// Service responsible for video/live photo playback in collection view
class TLVideoPlayerService {
    // MARK: - Dependencies
    private let state: TLPhotosPickerState
    private let selectionService: TLPhotoSelectionService
    private let photoLibrary: TLPhotoLibrary
    private weak var collectionView: UICollectionView?

    // MARK: - Configuration
    private var configure: TLPhotosPickerConfigure {
        return state.configure
    }

    // MARK: - State
    var thumbnailSize: CGSize = .zero

    // MARK: - Initialization
    init(
        state: TLPhotosPickerState,
        selectionService: TLPhotoSelectionService,
        photoLibrary: TLPhotoLibrary,
        collectionView: UICollectionView?
    ) {
        self.state = state
        self.selectionService = selectionService
        self.photoLibrary = photoLibrary
        self.collectionView = collectionView
    }

    // MARK: - Public Methods
    func videoCheck() {
        guard configure.autoPlay else { return }
        guard state.playRequestID == nil else { return }
        guard let collectionView = collectionView else { return }

        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })

        #if swift(>=4.1)
        let boundAssets = visibleIndexPaths.compactMap { indexPath -> (IndexPath, TLPHAsset)? in
            guard let asset = state.focusedCollection?.getTLAsset(at: indexPath),
                  asset.phAsset?.mediaType == .video else { return nil }
            return (indexPath, asset)
        }
        #else
        let boundAssets = visibleIndexPaths.flatMap { indexPath -> (IndexPath, TLPHAsset)? in
            guard let asset = state.focusedCollection?.getTLAsset(at: indexPath),
                  asset.phAsset?.mediaType == .video else { return nil }
            return (indexPath, asset)
        }
        #endif

        if let firstSelectedVideoAsset = boundAssets.first(where: { selectionService.getSelectedAsset(for: $0.1) != nil }) {
            playIfNeeded(asset: firstSelectedVideoAsset)
        } else if let firstVideoAsset = boundAssets.first {
            playIfNeeded(asset: firstVideoAsset)
        }
    }

    func stopPlay() {
        guard let playRequest = state.playRequestID else { return }
        guard let collectionView = collectionView else { return }

        state.playRequestID = nil

        guard let cell = collectionView.cellForItem(at: playRequest.indexPath) as? TLPhotoCollectionViewCell else { return }
        cell.stopPlay()
    }

    func playVideo(asset: TLPHAsset, at indexPath: IndexPath) {
        stopPlay()
        guard let phAsset = asset.phAsset else { return }
        guard let collectionView = collectionView else { return }

        if asset.type == .video {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }

            let requestID = photoLibrary.videoAsset(asset: phAsset) { [weak self, weak cell] playerItem, info in
                guard let self = self else { return }

                DispatchQueue.main.async { [weak self, weak cell] in
                    guard let self = self, let cell = cell, cell.player == nil else { return }

                    let player = AVPlayer(playerItem: playerItem)
                    cell.player = player
                    player.play()
                    player.isMuted = self.configure.muteAudio
                }
            }

            if requestID > 0 {
                state.playRequestID = (indexPath, requestID)
            }
        } else if asset.type == .livePhoto && configure.allowedLivePhotos {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }

            let requestID = photoLibrary.livePhotoAsset(asset: phAsset, size: thumbnailSize) { [weak cell, weak self] livePhoto, complete in
                guard let self = self else { return }

                cell?.livePhotoView?.isHidden = false
                cell?.livePhotoView?.livePhoto = livePhoto
                cell?.livePhotoView?.isMuted = true
                cell?.livePhotoView?.startPlayback(with: self.configure.startplayBack)
            }

            if requestID > 0 {
                state.playRequestID = (indexPath, requestID)
            }
        }
    }

    // MARK: - Private Methods
    private func playIfNeeded(asset: (IndexPath, TLPHAsset)) {
        if state.playRequestID?.indexPath != asset.0 {
            playVideo(asset: asset.1, at: asset.0)
        }
    }
}
