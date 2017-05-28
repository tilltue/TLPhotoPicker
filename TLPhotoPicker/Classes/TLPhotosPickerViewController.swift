//
//  TLPhotosPickerViewController.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

public protocol TLPhotosPickerViewControllerDelegate: class {
    func dismissPhotoPicker(withPHAssets: [PHAsset])
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset])
    func dismissComplete()
    func photoPickerDidCancel()
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)
}
extension TLPhotosPickerViewControllerDelegate {
    public func dismissPhotoPicker(withPHAssets: [PHAsset]) { }
    public func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) { }
    public func dismissComplete() { }
    public func photoPickerDidCancel() { }
    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) { }
}

public struct TLPhotosPickerConfigure {
    public var defaultCameraRollTitle = "Camera Roll"
    public var tapHereToChange = "Tap here to change"
    public var cancelTitle = "Cancel"
    public var doneTitle = "Done"
    public var usedCameraButton = true
    public var usedPrefetch = false
    public var allowedLivePhotos = true
    public var allowedVideo = true
    public var mediaType: PHAssetMediaType? = nil
    public var numberOfColumn = 3
    public var maxSelectedAssets: Int? = nil
    public var selectedColor = UIColor(red: 88/255, green: 144/255, blue: 255/255, alpha: 1.0)
    public var cameraBgColor = UIColor(red: 221/255, green: 223/255, blue: 226/255, alpha: 1)
    public var cameraIcon = TLBundle.podBundleImage(named: "camera")
    public var videoIcon = TLBundle.podBundleImage(named: "video")
    public var placeholderIcon = TLBundle.podBundleImage(named: "insertPhotoMaterial")
    public var nibSet: (nibName: String, bundle:Bundle)? = nil
    public init() {
        
    }
}


public struct Platform {
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
    }
    
}


open class TLPhotosPickerViewController: UIViewController {
    @IBOutlet open var titleView: UIView!
    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var subTitleStackView: UIStackView!
    @IBOutlet open var subTitleLabel: UILabel!
    @IBOutlet open var subTitleArrowImageView: UIImageView!
    @IBOutlet open var albumPopView: TLAlbumPopView!
    @IBOutlet open var collectionView: UICollectionView!
    @IBOutlet open var indicator: UIActivityIndicatorView!
    @IBOutlet open var popArrowImageView: UIImageView!
    @IBOutlet open var customNavItem: UINavigationItem!
    @IBOutlet open var doneButton: UIBarButtonItem!
    @IBOutlet open var cancelButton: UIBarButtonItem!

    public weak var delegate: TLPhotosPickerViewControllerDelegate? = nil
    public var selectedAssets = [TLPHAsset]()
    public var configure = TLPhotosPickerConfigure()
    
    fileprivate var usedCameraButton: Bool {
        get {
            return self.configure.usedCameraButton
        }
    }
    fileprivate var allowedVideo: Bool {
        get {
            return self.configure.allowedVideo
        }
    }
    fileprivate var usedPrefetch: Bool {
        get {
            return self.configure.usedPrefetch
        }
        set {
            self.configure.usedPrefetch = newValue
        }
    }
    fileprivate var allowedLivePhotos: Bool {
        get {
            return self.configure.allowedLivePhotos
        }
        set {
            self.configure.allowedLivePhotos = newValue
        }
    }
    open var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)? = nil
    open var dismissCompletion: (() -> Void)? = nil
    fileprivate var completionWithPHAssets: (([PHAsset]) -> Void)? = nil
    fileprivate var completionWithTLPHAssets: (([TLPHAsset]) -> Void)? = nil
    fileprivate var didCancel: ((Void) -> Void)? = nil
    
    fileprivate var collections = [TLAssetsCollection]()
    fileprivate var focusedCollection: TLAssetsCollection? = nil
    fileprivate var requestIds = [IndexPath:PHImageRequestID]()
    fileprivate var cloudRequestIds = [IndexPath:PHImageRequestID]()
    fileprivate var playRequestId: (indexPath: IndexPath, requestId: PHImageRequestID)? = nil
    fileprivate var photoLibrary = TLPhotoLibrary()
    fileprivate var queue = DispatchQueue(label: "tilltue.photos.pikcker.queue")
    fileprivate var thumbnailSize = CGSize.zero
    fileprivate var placeholderThumbnail: UIImage? = nil
    fileprivate var cameraImage: UIImage? = nil
    
    deinit {
        //print("deinit TLPhotosPickerViewController")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        super.init(nibName: "TLPhotosPickerViewController", bundle: Bundle(for: TLPhotosPickerViewController.self))
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                self?.initPhotoLibrary()
            }
        }
    }
    
    convenience public init(withPHAssets: (([PHAsset]) -> Void)? = nil, didCancel: ((Void) -> Void)? = nil) {
        self.init()
        self.completionWithPHAssets = withPHAssets
        self.didCancel = didCancel
    }
    
    convenience public init(withTLPHAssets: (([TLPHAsset]) -> Void)? = nil, didCancel: ((Void) -> Void)? = nil) {
        self.init()
        self.completionWithTLPHAssets = withTLPHAssets
        self.didCancel = didCancel
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopPlay()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isBeingPresented {
            initItemSize()
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isBeingPresented {
            initPhotoLibrary()
        }
    }
}

// MARK: - UI & UI Action
extension TLPhotosPickerViewController {
    
    public func registerNib(nibName: String, bundle: Bundle) {
        self.collectionView.register(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier: nibName)
    }
    
    fileprivate func centerAtRect(image: UIImage?, rect: CGRect, bgColor: UIColor = UIColor.white) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        bgColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        image.draw(in: CGRect(x:rect.size.width/2 - image.size.width/2, y:rect.size.height/2 - image.size.height/2, width:image.size.width, height:image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    fileprivate func initItemSize() {
        guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let count = CGFloat(self.configure.numberOfColumn)
        let width = (self.view.frame.size.width-(5*(count-1)))/count
        self.thumbnailSize = CGSize(width: width, height: width)
        layout.itemSize = self.thumbnailSize
        self.collectionView.collectionViewLayout = layout
        self.placeholderThumbnail = centerAtRect(image: self.configure.placeholderIcon, rect: CGRect(x: 0, y: 0, width: width, height: width))
        self.cameraImage = centerAtRect(image: self.configure.cameraIcon, rect: CGRect(x: 0, y: 0, width: width, height: width), bgColor: self.configure.cameraBgColor)
    }
    
    open func makeUI() {
        registerNib(nibName: "TLPhotoCollectionViewCell", bundle: Bundle(for: TLPhotoCollectionViewCell.self))
        if let nibSet = self.configure.nibSet {
            registerNib(nibName: nibSet.nibName, bundle: nibSet.bundle)
        }
        self.indicator.startAnimating()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(titleTap))
        self.titleView.addGestureRecognizer(tapGesture)
        self.titleLabel.text = self.configure.defaultCameraRollTitle
        self.subTitleLabel.text = self.configure.tapHereToChange
        self.cancelButton.title = self.configure.cancelTitle
        self.doneButton.title = self.configure.doneTitle
        self.doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)], for: .normal)
        self.albumPopView.tableView.delegate = self
        self.albumPopView.tableView.dataSource = self
        self.popArrowImageView.image = TLBundle.podBundleImage(named: "pop_arrow")
        self.subTitleArrowImageView.image = TLBundle.podBundleImage(named: "arrow")
        if #available(iOS 10.0, *), self.usedPrefetch {
            self.collectionView.isPrefetchingEnabled = true
            self.collectionView.prefetchDataSource = self
        } else {
            self.usedPrefetch = false
        }
        if #available(iOS 9.0, *), self.allowedLivePhotos {
        }else {
            self.allowedLivePhotos = false
        }
    }
    
    fileprivate func updateTitle() {
        guard self.focusedCollection != nil else { return }
        self.titleLabel.text = self.focusedCollection?.collection.localizedTitle
    }
    
    fileprivate func reloadCollectionView() {
        guard self.focusedCollection != nil else { return }
        self.collectionView.reloadData()
    }
    
    fileprivate func reloadTableView() {
        let count = min(5, self.collections.count)
        var frame = self.albumPopView.popupView.frame
        frame.size.height = CGFloat(count * 75)
        self.albumPopView.popupViewHeight.constant = CGFloat(count * 75)
        UIView.animate(withDuration: self.albumPopView.show ? 0.1:0) {
            self.albumPopView.popupView.frame = frame
            self.albumPopView.setNeedsLayout()
        }
        self.albumPopView.tableView.reloadData()
        self.albumPopView.setupPopupFrame()
    }
    
    fileprivate func initPhotoLibrary() {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.photoLibrary.delegate = self
            self.photoLibrary.fetchCollection(allowedVideo: self.allowedVideo, addCameraAsset: self.usedCameraButton, mediaType: self.configure.mediaType)
        }else{
            //self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func getfocusedIndex() -> Int {
        guard let focused = self.focusedCollection, let result = self.collections.index(where: { $0 == focused }) else { return 0 }
        return result
    }
    
    fileprivate func focused(collection: TLAssetsCollection) {
        func resetRequest() {
            cancelAllCloudRequest()
            cancelAllImageAssets()
        }
        resetRequest()
        self.collections[getfocusedIndex()].recentPosition = self.collectionView.contentOffset
        var reloadIndexPaths = [IndexPath(row: getfocusedIndex(), section: 0)]
        self.focusedCollection = collection
        reloadIndexPaths.append(IndexPath(row: getfocusedIndex(), section: 0))
        self.albumPopView.tableView.reloadRows(at: reloadIndexPaths, with: .none)
        self.albumPopView.show(false, duration: 0.2)
        self.updateTitle()
        self.reloadCollectionView()
        self.collectionView.contentOffset = collection.recentPosition
    }
    
    // Asset Request
    fileprivate func requestCloudDownload(asset: TLPHAsset, indexPath: IndexPath) {
        if asset.state != .complete {
            var asset = asset
            asset.state = .ready
            guard let phAsset = asset.phAsset else { return }
            let requestId = self.photoLibrary.cloudImageDownload(asset: phAsset, progressBlock: { [weak self] (progress) in
                guard let `self` = self else { return }
                if asset.state == .ready {
                    asset.state = .progress
                    if let index = self.selectedAssets.index(where: { $0.phAsset == phAsset }) {
                        self.selectedAssets[index] = asset
                    }
                    guard self.collectionView.indexPathsForVisibleItems.contains(indexPath) else { return }
                    guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
                    cell.indicator?.startAnimating()
                }
            }, completionBlock: { [weak self] image in
                guard let `self` = self else { return }
                asset.state = .complete
                if let index = self.selectedAssets.index(where: { $0.phAsset == phAsset }) {
                    self.selectedAssets[index] = asset
                }
                self.cloudRequestIds.removeValue(forKey: indexPath)
                guard self.collectionView.indexPathsForVisibleItems.contains(indexPath) else { return }
                guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
                cell.imageView?.image = image
                cell.indicator?.stopAnimating()
            })
            if requestId > 0 {
                self.cloudRequestIds[indexPath] = requestId
            }
        }
    }
    
    fileprivate func cancelCloudRequest(indexPath: IndexPath) {
        guard let requestId = self.cloudRequestIds[indexPath] else { return }
        self.cloudRequestIds.removeValue(forKey: indexPath)
        self.photoLibrary.cancelPHImageRequest(requestId: requestId)
    }
    
    fileprivate func cancelAllCloudRequest() {
        for (_,requestId) in self.cloudRequestIds {
            self.photoLibrary.cancelPHImageRequest(requestId: requestId)
        }
        self.cloudRequestIds.removeAll()
    }
    
    fileprivate func cancelAllImageAssets() {
        for (_,requestId) in self.requestIds {
            self.photoLibrary.cancelPHImageRequest(requestId: requestId)
        }
        self.requestIds.removeAll()
    }
    
    // User Action
    func titleTap() {
        guard collections.count > 0 else { return }
        self.albumPopView.show(self.albumPopView.isHidden)
    }
    
    @IBAction func cancelButtonTap() {
        self.dismiss(done: false)
    }
    
    @IBAction func doneButtonTap() {
        self.dismiss(done: true)
    }
    
    fileprivate func dismiss(done: Bool) {
        if done {
            self.delegate?.dismissPhotoPicker(withPHAssets: self.selectedAssets.flatMap{ $0.phAsset })
            self.delegate?.dismissPhotoPicker(withTLPHAssets: self.selectedAssets)
            self.completionWithTLPHAssets?(self.selectedAssets)
            self.completionWithPHAssets?(self.selectedAssets.flatMap{ $0.phAsset })
        }else {
            self.delegate?.photoPickerDidCancel()
            self.didCancel?()
        }
        self.dismiss(animated: true) { [weak self] _ in
            self?.delegate?.dismissComplete()
            self?.dismissCompletion?()
        }
    }
    fileprivate func maxCheck() -> Bool {
        if let max = self.configure.maxSelectedAssets, max <= self.selectedAssets.count {
            self.delegate?.didExceedMaximumNumberOfSelection(picker: self)
            self.didExceedMaximumNumberOfSelection?(self)
            return true
        }
        return false
    }
}

// MARK: - TLPhotoLibraryDelegate
extension TLPhotosPickerViewController: TLPhotoLibraryDelegate {
    func loadCameraRollCollection(collection: TLAssetsCollection) {
        if let focused = self.focusedCollection, focused == collection {
            focusCollection(collection: collection)
        }
        self.collections = [collection]
        self.indicator.stopAnimating()
        self.reloadCollectionView()
        self.reloadTableView()
    }
    
    func loadCompleteAllCollection(collections: [TLAssetsCollection]) {
        self.collections = collections
        self.reloadTableView()
    }
    
    func focusCollection(collection: TLAssetsCollection) {
        self.focusedCollection = collection
        self.updateTitle()
    }
}

// MARK: - Camera Picker
extension TLPhotosPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    fileprivate func showCamera() {
        guard !maxCheck() else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = (info[UIImagePickerControllerOriginalImage] as? UIImage) {
            var placeholderAsset: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: { [weak self] (sucess, error) in
                if sucess, let `self` = self, let identifier = placeholderAsset?.localIdentifier {
                    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return }
                    var result = TLPHAsset(asset: asset)
                    result.selectedOrder = self.selectedAssets.count + 1
                    self.selectedAssets.append(result)
                    self.dismiss(done: true)
                }
            })
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionView Scroll Delegate
extension TLPhotosPickerViewController {
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            videoCheck()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        videoCheck()
    }
    
    fileprivate func videoCheck() {
        func play(asset: (IndexPath,TLPHAsset)) {
            if self.playRequestId?.indexPath != asset.0 {
                playVideo(asset: asset.1, indexPath: asset.0)
            }
        }
        guard self.allowedVideo || self.allowedLivePhotos else { return }
        guard self.playRequestId == nil else { return }
        guard let boundAssets = (getVisibleBoundAsset()?.filter{ $0.1.type != .photo  }) else { return }
        if let firstSelectedVideoAsset = (boundAssets.filter{ getSelectedAssets($0.1) != nil }.first) {
            play(asset: firstSelectedVideoAsset)
        }else if let firstVideoAsset = boundAssets.first {
            play(asset: firstVideoAsset)
        }
        
    }
}
// MARK: - Video & LivePhotos Control PHLivePhotoViewDelegate
extension TLPhotosPickerViewController: PHLivePhotoViewDelegate {
    fileprivate func stopPlay() {
        guard let playRequest = self.playRequestId else { return }
        self.playRequestId = nil
        guard let cell = self.collectionView.cellForItem(at: playRequest.indexPath) as? TLPhotoCollectionViewCell else { return }
        cell.stopPlay()
    }
    
    fileprivate func playVideo(asset: TLPHAsset, indexPath: IndexPath) {
        stopPlay()
        guard self.allowedVideo || self.allowedLivePhotos else { return }
        guard let phAsset = asset.phAsset else { return }
        if asset.type == .video {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            let requestId = self.photoLibrary.videoAsset(asset: phAsset, completionBlock: { (playerItem, info) in
                DispatchQueue.main.sync { [weak cell] _ in
                    guard let cell = cell, cell.player == nil else { return }
                    let player = AVPlayer(playerItem: playerItem)
                    cell.player = player
                    player.play()
                }
            })
            if requestId > 0 {
                self.playRequestId = (indexPath,requestId)
            }
        }else if asset.type == .livePhoto, self.allowedLivePhotos {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            let requestId = self.photoLibrary.livePhotoAsset(asset: phAsset, size: self.thumbnailSize, completionBlock: { (livePhoto) in
                cell.livePhotoView?.isHidden = false
                cell.livePhotoView?.livePhoto = livePhoto
                cell.livePhotoView?.startPlayback(with: .hint)
            })
            if requestId > 0 {
                self.playRequestId = (indexPath,requestId)
            }
        }
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoView.startPlayback(with: .hint)
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
    }
}


// UICollectionView delegate & datasource
extension TLPhotosPickerViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching {
    fileprivate func getVisibleBoundAsset() -> [(IndexPath,TLPHAsset)]? {
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted(by: { $0.0.row < $0.1.row })
        guard let first = visibleIndexPaths.first?.row, let last = visibleIndexPaths.last?.row else { return nil }
        guard let boundAssets = self.focusedCollection?.assets[first...last] else { return nil }
        return boundAssets.enumerated().flatMap{ (index,asset) -> (IndexPath,TLPHAsset) in
            return (IndexPath(row: index+first, section: 0), asset)
        }
    }
    
    fileprivate func getSelectedAssets(_ asset: TLPHAsset) -> TLPHAsset? {
        if let index = self.selectedAssets.index(where: { $0.phAsset == asset.phAsset }) {
            return self.selectedAssets[index]
        }
        return nil
    }
    
    fileprivate func orderUpdateCells() {
        guard let visibleAssets = getVisibleBoundAsset() else { return }
        for (indexPath,asset) in visibleAssets {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            if let selectedAsset = getSelectedAssets(asset) {
                cell.selectedAsset = true
                cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
            }else {
                cell.selectedAsset = false
            }
        }
    }
    
    //Delegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard var asset = self.focusedCollection?.assets[indexPath.row] else { return }
        if asset.camera {
            if Platform.isSimulator {
                print("not supported by the simulator.")
                return
            }else {
                showCamera()
                return
            }
        }
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
        cell.popScaleAnim()
        if let index = self.selectedAssets.index(where: { $0.phAsset == asset.phAsset }) {
        //deselect
            self.selectedAssets.remove(at: index)
            self.selectedAssets = self.selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
                var asset = asset
                asset.selectedOrder = offset + 1
                return asset
            })
            self.orderUpdateCells()
            cancelCloudRequest(indexPath: indexPath)
            if self.playRequestId?.indexPath == indexPath {
                stopPlay()
            }
        }else {
        //select
            guard !maxCheck() else { return }
            asset.selectedOrder = self.selectedAssets.count + 1
            self.selectedAssets.append(asset)
            requestCloudDownload(asset: asset, indexPath: indexPath)
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(asset.selectedOrder)"
            if asset.type != .photo {
                playVideo(asset: asset, indexPath: indexPath)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath == self.playRequestId?.indexPath, let cell = cell as? TLPhotoCollectionViewCell {
            self.playRequestId = nil
            cell.stopPlay()
        }
        guard let requestId = self.requestIds[indexPath] else { return }
        self.requestIds.removeValue(forKey: indexPath)
        self.photoLibrary.cancelPHImageRequest(requestId: requestId)
    }
    
    //Datasource
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let nibName = self.configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: nibName, for: indexPath) as! TLPhotoCollectionViewCell
        cell.configure = self.configure
        cell.imageView?.image = self.placeholderThumbnail
        guard let focusAssets = self.focusedCollection?.assets else { return cell }
        let asset = focusAssets[indexPath.row]
        cell.isCameraCell = asset.camera && self.usedCameraButton
        if cell.isCameraCell {
            cell.imageView?.image = self.cameraImage
            return cell
        }
        if let selectedAsset = getSelectedAssets(asset) {
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
        }else{
            cell.selectedAsset = false
        }
        if asset.state == .progress {
            cell.indicator?.startAnimating()
        }else {
            cell.indicator?.stopAnimating()
        }
        if let phAsset = asset.phAsset {
            if self.usedPrefetch {
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isNetworkAccessAllowed = true
                self.photoLibrary.imageAsset(asset: phAsset, size: self.thumbnailSize, options: options) { [weak cell] image in
                    cell?.imageView?.image = image
                }
            }else {
                queue.async { [weak self, weak cell] _ in
                    guard let `self` = self else { return }
                    let requestId = self.photoLibrary.imageAsset(asset: phAsset, size: self.thumbnailSize, completionBlock: { image in
                        cell?.imageView?.image = image
                        if self.allowedVideo {
                            cell?.durationView?.isHidden = asset.type != .video
                            cell?.duration = asset.type == .video ? phAsset.duration : nil
                        }
                        self.requestIds.removeValue(forKey: indexPath)
                    })
                    if requestId > 0 {
                        self.requestIds[indexPath] = requestId
                    }
                }
            }
            if self.allowedLivePhotos {
                cell.liveBadgeImageView?.image = asset.type == .livePhoto ? PHLivePhotoView.livePhotoBadgeImage(options: .overContent) : nil
                cell.livePhotoView?.delegate = asset.type == .livePhoto ? self : nil
            }
        }
        cell.alpha = 0
        UIView.transition(with: cell, duration: 0.1, options: .curveEaseIn, animations: {
            cell.alpha = 1
        }, completion: nil)
        return cell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.focusedCollection?.assets.count ?? 0
    }
    
    //Prefetch
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if self.usedPrefetch {
            queue.async { [weak self] _ in
                guard let `self` = self, let focusAssets = self.focusedCollection?.assets else { return }
                if indexPaths.count <= focusAssets.count {
                    self.photoLibrary.imageManager.startCachingImages(for: indexPaths.flatMap{ focusAssets[$0.item].phAsset }, targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if self.usedPrefetch {
            for indexPath in indexPaths {
                guard let requestId = self.requestIds[indexPath] else { continue }
                self.photoLibrary.cancelPHImageRequest(requestId: requestId)
                self.requestIds.removeValue(forKey: indexPath)
            }
            queue.async { [weak self] _ in
                guard let `self` = self, let focusAssets = self.focusedCollection?.assets else { return }
                if indexPaths.count <= focusAssets.count {
                    self.photoLibrary.imageManager.stopCachingImages(for: indexPaths.flatMap{ focusAssets[$0.item].phAsset }, targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)
                }
            }
        }
    }
}

// MARK: - UITableView datasource & delegate
extension TLPhotosPickerViewController: UITableViewDelegate,UITableViewDataSource {
    //delegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.focused(collection: self.collections[indexPath.row])
    }
    
    //datasource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.collections.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TLCollectionTableViewCell", for: indexPath) as! TLCollectionTableViewCell
        let collection = self.collections[indexPath.row]
        cell.thumbImageView.image = collection.thumbnail
        cell.titleLabel.text = collection.title
        cell.subTitleLabel.text = "\(collection.assets.count)"
        if let phAsset = (collection.assets.filter{ !$0.camera }.first?.phAsset), collection.thumbnail == nil {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 80*scale, height: 80*scale)
            self.photoLibrary.imageAsset(asset: phAsset, size: size, completionBlock: { [weak cell] image in
                cell?.thumbImageView.image = image
            })
        }
        cell.accessoryType = getfocusedIndex() == indexPath.row ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
}
