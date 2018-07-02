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
import MobileCoreServices
import UIKit.UIGestureRecognizerSubclass
import SDWebImage

public protocol TLPhotosPickerViewControllerDelegate: class {
    func willDismissPhotoPicker(with phAssets: [PHAsset])
    func willDismissPhotoPicker(with tlphAssets: [TLPHAsset])
    func didDismissPhotoPicker(with phAssets: [PHAsset])
    func didDismissPhotoPicker(with tlphAssets: [TLPHAsset])
    func didCancelPhotoPicker()
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)
}
extension TLPhotosPickerViewControllerDelegate {
    public func willDismissPhotoPicker(with phAssets: [PHAsset]) { }
    public func willDismissPhotoPicker(with tlphAssets: [TLPHAsset]) { }
    public func didDismissPhotoPicker(with phAssets: [PHAsset]) { }
    public func didDismissPhotoPicker(with tlphAssets: [TLPHAsset]) { }
    public func didCancelPhotoPicker() { }
    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) { }
}

public struct TLPhotosPickerConfigure {
    public var defaultCameraRollTitle = "Camera Roll"
    public var tapHereToChange = "Tap here to change"
    public var cancelTitle = "Cancel"
    public var doneTitle = "Done"
    public var emptyMessage = "No albums"
    public var emptyImage: UIImage? = nil
    public var usedCameraButton = true
    public var usedPrefetch = false
    public var allowedLivePhotos = true
    public var allowedVideo = true
    public var allowedVideoRecording = true
    public var maxVideoDuration:TimeInterval? = nil
    public var autoPlay = true
    public var muteAudio = true
    public var mediaType: PHAssetMediaType? = nil
    public var numberOfColumn = 3
    public var itemMinSpacing: CGFloat = 5
    public var singleSelectedMode = false
    public var maxSelectedAssets: Int? = nil
    public var isSwipeSelectionEnabled: Bool = true
    public var isSelectionAnimationEnabled: Bool = true
    public var fetchOption: PHFetchOptions? = nil
    public var selectedColor = UIColor(red: 88/255, green: 144/255, blue: 255/255, alpha: 1.0)
    public var cameraBgColor = UIColor(red: 221/255, green: 223/255, blue: 226/255, alpha: 1)
    public var cameraIcon = TLBundle.podBundleImage(named: "camera")
    public var videoIcon = TLBundle.podBundleImage(named: "video")
    public var placeholderIcon = TLBundle.podBundleImage(named: "insertPhotoMaterial")
    public var nibSet: (nibName: String, bundle:Bundle)? = nil
    public var cameraCellNibSet: (nibName: String, bundle:Bundle)? = nil
    public init() {
        
    }
}

public struct Platform {
    
    public static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
    }
}

open class TLPhotosPickerViewController: UIViewController {
    @IBOutlet open var customNavigationBar: UINavigationBar!
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
    @IBOutlet open var navigationBarTopConstraint: NSLayoutConstraint!
    @IBOutlet open var emptyView: UIView!
    @IBOutlet open var emptyImageView: UIImageView!
    @IBOutlet open var emptyMessageLabel: UILabel!
    
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
    @objc open var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var dismissCompletion: (() -> Void)? = nil
    fileprivate var completionWithPHAssets: (([PHAsset]) -> Void)? = nil
    fileprivate var completionWithTLPHAssets: (([TLPHAsset]) -> Void)? = nil
    fileprivate var didCancel: (() -> Void)? = nil
    
    fileprivate var collections = [TLAssetsCollection]()
    open var customCollection: TLAssetsCollection? = nil {
        didSet {
            if let oldValue = oldValue,
                let index = collections.index(where: { $0.customAssets != nil }) {
                collections.remove(at: index)
            }
            if let newValue = customCollection {
                collections.insert(newValue, at: 0)
                focusCollection(collection: newValue)
            }
        }
    }
    fileprivate var focusedCollection: TLAssetsCollection? = nil
    fileprivate var requestIds = [IndexPath:PHImageRequestID]()
    fileprivate var cloudRequestIds = [IndexPath:PHImageRequestID]()
    fileprivate var playRequestId: (indexPath: IndexPath, requestId: PHImageRequestID)? = nil
    fileprivate var photoLibrary = TLPhotoLibrary()
    fileprivate var queue = DispatchQueue(label: "tilltue.photos.pikcker.queue")
    fileprivate var thumbnailSize = CGSize.zero
    fileprivate var placeholderThumbnail: UIImage? = nil
    fileprivate var cameraImage: UIImage? = nil
    
    fileprivate var swipeSelectionIsAddingSelections = false
    fileprivate var swipeSelectionSelectionFirstIndex = 0
    fileprivate var swipeSelectionSelectionLastIndex = 0
    fileprivate var selectedAssetsBeforeSwipeSelection = [TLPHAsset]()
    
    deinit {
        //print("deinit TLPhotosPickerViewController")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                self?.initPhotoLibrary()
            }
        }
    }
    
    public init() {
        super.init(nibName: "TLPhotosPickerViewController", bundle: Bundle(for: TLPhotosPickerViewController.self))
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                self?.initPhotoLibrary()
            }
        }
    }
    
    @objc convenience public init(with didChoosePHAssets: (([PHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        self.completionWithPHAssets = didChoosePHAssets
        self.didCancel = didCancel
    }
    
    convenience public init(with didChoosePHAssets: (([TLPHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        self.completionWithTLPHAssets = didChoosePHAssets
        self.didCancel = didCancel
    }
    
    convenience public init(with collection: TLAssetsCollection? = nil) {
        self.init()
        self.customCollection = collection
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
        if self.thumbnailSize == CGSize.zero {
            initItemSize()
        }
        if #available(iOS 11.0, *) {
        } else if self.navigationBarTopConstraint.constant == 0 {
            self.navigationBarTopConstraint.constant = 20
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.photoLibrary.delegate == nil {
            initPhotoLibrary()
        }
    }
}

// MARK: - UI & UI Action
extension TLPhotosPickerViewController {
    
    @objc public func registerNib(nibName: String, bundle: Bundle) {
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
        layout.minimumLineSpacing = self.configure.itemMinSpacing
        layout.minimumInteritemSpacing = self.configure.itemMinSpacing
        let count = CGFloat(self.configure.numberOfColumn)
        let width = (self.view.frame.size.width-(self.configure.itemMinSpacing*(count-1)))/count
        self.thumbnailSize = CGSize(width: width, height: width)
        layout.itemSize = self.thumbnailSize
        self.collectionView.collectionViewLayout = layout
        self.placeholderThumbnail = centerAtRect(image: self.configure.placeholderIcon, rect: CGRect(x: 0, y: 0, width: width, height: width))
        self.cameraImage = centerAtRect(image: self.configure.cameraIcon, rect: CGRect(x: 0, y: 0, width: width, height: width), bgColor: self.configure.cameraBgColor)
    }
    
    @objc open func makeUI() {
        registerNib(nibName: "TLPhotoCollectionViewCell", bundle: Bundle(for: TLPhotoCollectionViewCell.self))
        if let nibSet = self.configure.nibSet {
            registerNib(nibName: nibSet.nibName, bundle: nibSet.bundle)
        }
        if let nibSet = self.configure.cameraCellNibSet {
            registerNib(nibName: nibSet.nibName, bundle: nibSet.bundle)
        }
        self.customNavigationBar.isTranslucent = false
        self.indicator.startAnimating()
        self.titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTap)))
        self.titleLabel.text = self.configure.defaultCameraRollTitle
        self.subTitleLabel.text = self.configure.tapHereToChange
        self.cancelButton.title = self.configure.cancelTitle
        self.doneButton.title = self.configure.doneTitle
        self.doneButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)], for: .normal)
        self.emptyView.isHidden = true
        self.emptyImageView.image = self.configure.emptyImage
        self.emptyMessageLabel.text = self.configure.emptyMessage
        self.albumPopView.tableView.delegate = self
        self.albumPopView.tableView.dataSource = self
        self.popArrowImageView.image = TLBundle.podBundleImage(named: "pop_arrow")
        self.subTitleArrowImageView.image = TLBundle.podBundleImage(named: "arrow")
        if (self.configure.isSwipeSelectionEnabled) {
            let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
            swipeGesture.delegate = self
            self.collectionView.addGestureRecognizer(swipeGesture)
        }
        if #available(iOS 10.0, *), self.usedPrefetch {
            self.collectionView.isPrefetchingEnabled = true
            self.collectionView.prefetchDataSource = self
        } else {
            self.usedPrefetch = false
        }
        if #available(iOS 9.0, *), self.allowedLivePhotos {
        } else {
            self.allowedLivePhotos = false
        }
    }
    
    fileprivate func updateTitle() {
        guard self.focusedCollection != nil else { return }
        self.titleLabel.text = self.focusedCollection?.title
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
            self.photoLibrary.fetchCollection(configure: self.configure)
        }else{
            //self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
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
        self.focusedCollection?.fetchResult = self.photoLibrary.fetchResult(collection: collection, maxVideoDuration:self.configure.maxVideoDuration, options: self.configure.fetchOption)
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
            let requestId = TLPhotoLibrary.cloudImageDownload(asset: phAsset, progressBlock: { [weak self] (progress) in
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
    @objc func titleTap() {
        guard collections.count > 0 else { return }
        self.albumPopView.show(self.albumPopView.isHidden)
    }
    
    @IBAction open func cancelButtonTap() {
        self.stopPlay()
        self.dismiss(done: false)
    }
    
    @IBAction open func doneButtonTap() {
        self.stopPlay()
        self.dismiss(done: true)
    }
    
    fileprivate func dismiss(done: Bool) {
        if done {
            self.delegate?.willDismissPhotoPicker(with: self.selectedAssets.flatMap{ $0.phAsset })
            self.delegate?.willDismissPhotoPicker(with: self.selectedAssets)
        }
        self.dismiss(animated: true) { [weak self] in
            if let _self = self {
                if done {
                    _self.delegate?.didDismissPhotoPicker(with: _self.selectedAssets.flatMap{ $0.phAsset })
                    _self.delegate?.didDismissPhotoPicker(with: _self.selectedAssets)
                    _self.completionWithTLPHAssets?(_self.selectedAssets)
                    _self.completionWithPHAssets?(_self.selectedAssets.flatMap{ $0.phAsset })
                } else {
                    _self.delegate?.didCancelPhotoPicker()
                    _self.didCancel?()
                }
                _self.dismissCompletion?()
            }
        }
    }
    
    fileprivate func maxCheck() -> Bool {
        if self.configure.singleSelectedMode {
            self.selectedAssets.removeAll()
            self.orderUpdateCells()
        }
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
        var allCollections = [collection]
        if let customCollection = self.customCollection {
            allCollections.insert(customCollection, at: 0)
            self.focusCollection(collection: customCollection)
        } else {
            self.focusCollection(collection: collection)
        }
        self.collections = allCollections
        self.indicator.stopAnimating()
        self.reloadCollectionView()
        self.reloadTableView()
    }
    
    func loadCompleteAllCollection(collections: [TLAssetsCollection]) {
        var allCollections = collections
        if let customCollection = self.customCollection {
            allCollections.insert(customCollection, at: 0)
        }
        self.focusCollection(collection: allCollections.first)
        self.collections = allCollections
        let isEmpty = self.collections.count == 0
        self.subTitleStackView.isHidden = isEmpty
        self.emptyView.isHidden = !isEmpty
        self.emptyImageView.isHidden = self.emptyImageView.image == nil
        self.indicator.stopAnimating()
        self.reloadTableView()
        self.registerChangeObserver()
    }
    
    public func focusCollection(collection: TLAssetsCollection?) {
        self.focusedCollection = collection
        self.updateTitle()
        self.reloadCollectionView()
    }
}

// MARK: - Camera Picker
extension TLPhotosPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate func showCamera() {
        guard !maxCheck() else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        if self.configure.allowedVideoRecording {
            picker.mediaTypes.append(kUTTypeMovie as String)
            if let duration = self.configure.maxVideoDuration {
                picker.videoMaximumDuration = duration
            }
        }
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
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
                }
            })
        }
        else if (info[UIImagePickerControllerMediaType] as? String) == kUTTypeMovie as String {
            var placeholderAsset: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: info[UIImagePickerControllerMediaURL] as! URL)
                placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
            }) { [weak self] (sucess, error) in
                if sucess, let `self` = self, let identifier = placeholderAsset?.localIdentifier {
                    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return }
                    var result = TLPHAsset(asset: asset)
                    result.selectedOrder = self.selectedAssets.count + 1
                    self.selectedAssets.append(result)
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionView Scroll Delegate
extension TLPhotosPickerViewController {
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            videoCheck()
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        videoCheck()
    }
    
    fileprivate func videoCheck() {
        func play(asset: (IndexPath,TLPHAsset)) {
            if self.playRequestId?.indexPath != asset.0 {
                playVideo(asset: asset.1, indexPath: asset.0)
            }
        }
        guard self.configure.autoPlay else { return }
        guard self.playRequestId == nil else { return }
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })
        let boundAssets = visibleIndexPaths.flatMap{ indexPath -> (IndexPath,TLPHAsset)? in
            guard let asset = self.focusedCollection?.getTLAsset(at: indexPath.row),asset.phAsset?.mediaType == .video else { return nil }
            return (indexPath,asset)
        }
        if let firstSelectedVideoAsset = (boundAssets.filter{ getSelectedAssets($0.1) != nil }.first) {
            play(asset: firstSelectedVideoAsset)
        } else if let firstVideoAsset = boundAssets.first {
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
        guard let phAsset = asset.phAsset else { return }
        if asset.type == .video {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            let requestId = self.photoLibrary.videoAsset(asset: phAsset, completionBlock: { (playerItem, info) in
                DispatchQueue.main.sync { [weak self, weak cell] in
                    guard let `self` = self, let cell = cell, cell.player == nil else { return }
                    let player = AVPlayer(playerItem: playerItem)
                    cell.player = player
                    player.play()
                    player.isMuted = self.configure.muteAudio
                }
            })
            if requestId > 0 {
                self.playRequestId = (indexPath,requestId)
            }
        } else if asset.type == .livePhoto {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            let requestId = self.photoLibrary.livePhotoAsset(asset: phAsset, size: self.thumbnailSize, completionBlock: { (livePhoto,complete) in
                cell.livePhotoView?.isHidden = false
                cell.livePhotoView?.livePhoto = livePhoto
                cell.livePhotoView?.isMuted = true
                cell.livePhotoView?.startPlayback(with: .hint)
            })
            if requestId > 0 {
                self.playRequestId = (indexPath,requestId)
            }
        }
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoView.isMuted = true
        livePhotoView.startPlayback(with: .hint)
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension TLPhotosPickerViewController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard getfocusedIndex() == 0 else { return }
        guard let changeFetchResult = self.focusedCollection?.fetchResult else { return }
        guard let changes = changeInstance.changeDetails(for: changeFetchResult) else { return }
        let addIndex = self.usedCameraButton ? 1 : 0
        DispatchQueue.main.sync {
            if changes.hasIncrementalChanges {
                self.collectionView.performBatchUpdates({ [weak self] in
                    self?.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        self?.collectionView.deleteItems(at: removed.map { IndexPath(item: $0+addIndex, section:0) })
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        self?.collectionView.insertItems(at: inserted.map { IndexPath(item: $0+addIndex, section:0) })
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        self?.collectionView.reloadItems(at: changed.map { IndexPath(item: $0+addIndex, section:0) })
                    }
                })
            } else {
                self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - UICollectionView delegate & datasource
extension TLPhotosPickerViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching {
    
    fileprivate func getSelectedAssets(_ asset: TLPHAsset) -> TLPHAsset? {
        if let index = self.selectedAssets.index(where: { $0 == asset }) {
            return self.selectedAssets[index]
        }
        return nil
    }
    
    fileprivate func orderUpdateCells() {
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { continue }
            guard let asset = self.focusedCollection?.getTLAsset(at: indexPath.row) else { continue }
            if let selectedAsset = getSelectedAssets(asset) {
                cell.selectedAsset = true
                cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
            } else {
                cell.selectedAsset = false
            }
        }
    }
    
    fileprivate func selectIndexPath(_ indexPath: IndexPath, asset: TLPHAsset) {
        guard !self.selectedAssets.contains(asset) else { return }
        guard !maxCheck() else { return }
        asset.selectedOrder = self.selectedAssets.count + 1
        self.selectedAssets.append(asset)
        if self.collectionView.indexPathsForVisibleItems.contains(indexPath),
            let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell {
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(asset.selectedOrder)"
        }
        //requestCloudDownload(asset: asset, indexPath: indexPath)
        if asset.type != .photo, self.configure.autoPlay {
            playVideo(asset: asset, indexPath: indexPath)
        }
    }
    
    fileprivate func deselectIndexPath(_ indexPath: IndexPath, asset: TLPHAsset) {
        guard let removeIndex = self.selectedAssets.index(where: { $0 == asset }) else {
            return
        }
        self.selectedAssets.remove(at: removeIndex)
        self.selectedAssets = self.selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
            asset.selectedOrder = offset + 1
            return asset
        })
        if self.collectionView.indexPathsForVisibleItems.contains(indexPath),
            let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell {
            cell.selectedAsset = false
            self.orderUpdateCells()
        }
        //cancelCloudRequest(indexPath: indexPath)
        if self.playRequestId?.indexPath == indexPath {
            stopPlay()
        }
    }
    
    //Delegate
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collection = self.focusedCollection, let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
        if collection.useCameraButton && indexPath.row == 0 {
            if Platform.isSimulator {
                print("not supported by the simulator.")
                return
            } else {
                if let _ = self.configure.cameraCellNibSet?.nibName {
                    cell.selectedCell()
                } else {
                    showCamera()
                }
                return
            }
        }
        guard let asset = collection.getTLAsset(at: indexPath.row) else { return }
        if self.selectedAssets.contains(asset) {
            deselectIndexPath(indexPath, asset: asset)
        } else {
            selectIndexPath(indexPath, asset: asset)
        }
        if self.configure.isSelectionAnimationEnabled {
            cell.popScaleAnim()
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TLPhotoCollectionViewCell {
            cell.endDisplayingCell()
            if indexPath == self.playRequestId?.indexPath {
                self.playRequestId = nil
                cell.stopPlay()
            }
        }
        guard let requestId = self.requestIds[indexPath] else { return }
        self.requestIds.removeValue(forKey: indexPath)
        self.photoLibrary.cancelPHImageRequest(requestId: requestId)
    }
    
    //Datasource
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        func makeCell(nibName: String) -> TLPhotoCollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: nibName, for: indexPath) as! TLPhotoCollectionViewCell
            cell.configure = self.configure
            cell.imageView?.image = self.placeholderThumbnail
            return cell
        }
        let nibName = self.configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
        var cell = makeCell(nibName: nibName)
        guard let collection = self.focusedCollection else { return cell }
        cell.isCameraCell = collection.useCameraButton && indexPath.row == 0
        if cell.isCameraCell {
            if let nibName = self.configure.cameraCellNibSet?.nibName {
                cell = makeCell(nibName: nibName)
            } else{
                cell.imageView?.image = self.cameraImage
            }
            cell.willDisplayCell()
            return cell
        }
        guard let asset = collection.getTLAsset(at: indexPath.row) else { return cell }
        if let selectedAsset = getSelectedAssets(asset) {
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
        } else{
            cell.selectedAsset = false
        }
        if asset.state == .progress {
            cell.indicator?.startAnimating()
        } else {
            cell.indicator?.stopAnimating()
        }
        if let customCollection = customCollection, collection == customCollection {
            if let image = asset.fullResolutionImage {
                cell.imageView?.image = image
            } else if let url = asset.url {
                cell.imageView?.sd_setImage(with: url,
                                            placeholderImage: self.configure.placeholderIcon,
                                            options: [.continueInBackground, .allowInvalidSSLCertificates, .highPriority],
                                            completed: { (image, error, type, url) -> Void in
                                                asset.fullResolutionImage = image
                })
            }
        } else if let phAsset = asset.phAsset {
            if self.usedPrefetch {
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isNetworkAccessAllowed = true
                let requestId = self.photoLibrary.imageAsset(asset: phAsset, size: self.thumbnailSize, options: options) { [weak cell] (image,complete) in
                    DispatchQueue.main.async {
                        if self.requestIds[indexPath] != nil {
                            if let currentCell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell,
                                currentCell != cell {
                                cell = currentCell
                            }
                            cell?.imageView?.image = image
                            if complete {
                                self.requestIds.removeValue(forKey: indexPath)
                            }
                        }
                    }
                }
                if requestId > 0 {
                    self.requestIds[indexPath] = requestId
                }
            } else {
                queue.async { [weak self, weak cell] in
                    guard let `self` = self else { return }
                    let requestId = self.photoLibrary.imageAsset(asset: phAsset, size: self.thumbnailSize, completionBlock: { (image,complete) in
                        DispatchQueue.main.async {
                            if self.requestIds[indexPath] != nil {
                                if let currentCell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell,
                                   currentCell != cell {
                                    cell = currentCell
                                }
                                cell?.imageView?.image = image
                                if self.allowedVideo {
                                    cell?.durationView?.isHidden = asset.type != .video
                                    cell?.duration = asset.type == .video ? phAsset.duration : nil
                                }
                                if complete {
                                    self.requestIds.removeValue(forKey: indexPath)
                                }
                            }
                        }
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
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.focusedCollection?.count ?? 0
    }
    
    //Prefetch
    open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if self.usedPrefetch {
            queue.async { [weak self] in
                guard let `self` = self, let collection = self.focusedCollection else { return }
                if indexPaths.count <= collection.count,let first = indexPaths.first?.row, let last = indexPaths.last?.row {
                    guard let assets = collection.getAssets(at: first...last) else { return }
                    let scale = max(UIScreen.main.scale,2)
                    let targetSize = CGSize(width: self.thumbnailSize.width*scale, height: self.thumbnailSize.height*scale)
                    self.photoLibrary.imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
                }
            }
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if self.usedPrefetch {
            for indexPath in indexPaths {
                guard let requestId = self.requestIds[indexPath] else { continue }
                self.photoLibrary.cancelPHImageRequest(requestId: requestId)
                self.requestIds.removeValue(forKey: indexPath)
            }
            queue.async { [weak self] in
                guard let `self` = self, let collection = self.focusedCollection else { return }
                if indexPaths.count <= collection.count,let first = indexPaths.first?.row, let last = indexPaths.last?.row {
                    guard let assets = collection.getAssets(at: first...last) else { return }
                    let scale = max(UIScreen.main.scale,2)
                    let targetSize = CGSize(width: self.thumbnailSize.width*scale, height: self.thumbnailSize.height*scale)
                    self.photoLibrary.imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
                }
            }
        }
    }
}

// MARK: - UITableView datasource & delegate
extension TLPhotosPickerViewController: UITableViewDelegate,UITableViewDataSource {
    
    //delegate
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.focused(collection: self.collections[indexPath.row])
    }
    
    //datasource
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.collections.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "TLCollectionTableViewCell", for: indexPath) as! TLCollectionTableViewCell
        let collection = self.collections[indexPath.row]
        cell.thumbImageView.image = collection.thumbnail
        cell.titleLabel.text = collection.title
        cell.subTitleLabel.text = "\(collection.customAssets?.count ?? collection.fetchResult?.count ?? 0)"
        if let phAsset = collection.getAsset(at: collection.useCameraButton ? 1 : 0), collection.thumbnail == nil {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 80*scale, height: 80*scale)
            self.photoLibrary.imageAsset(asset: phAsset, size: size, completionBlock: { [weak cell] (image,complete) in
                DispatchQueue.main.async {
                    if let currentCell = tableView.cellForRow(at: indexPath) as? TLCollectionTableViewCell,
                        currentCell != cell {
                        cell = currentCell
                    }
                    cell?.thumbImageView.image = image
                }
            })
        }
        cell.accessoryType = getfocusedIndex() == indexPath.row ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - Swipe Selection
extension TLPhotosPickerViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc fileprivate func handleSwipeGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state != .began && gesture.state != .changed {
            return
        }
        guard let collection = self.focusedCollection else {
            return
        }
        let currLocation = gesture.location(in: collectionView)
        // If no cell is selected
        guard let currIndexPath = collectionView.indexPathForItem(at: currLocation) else {
            return
        }
        let currIndex = currIndexPath.row
        guard let asset = collection.getTLAsset(at: currIndex) else {
            return
        }
        switch (gesture.state) {
        case .began:
            let velocity = gesture.velocity(in: collectionView)
            // Only horizontal
            if abs(velocity.x) < abs(velocity.y) {
                gesture.state = .cancelled
                return
            } else {
                collectionView.panGestureRecognizer.state = .cancelled
            }
            selectedAssetsBeforeSwipeSelection = self.selectedAssets
            swipeSelectionSelectionFirstIndex = currIndex
            swipeSelectionSelectionLastIndex = currIndex
            if self.selectedAssets.contains(asset) {
                swipeSelectionIsAddingSelections = false
                self.deselectIndexPath(currIndexPath, asset: asset)
            } else {
                swipeSelectionIsAddingSelections = true
                self.selectIndexPath(currIndexPath, asset: asset)
            }
        case .changed:
            if currIndex == swipeSelectionSelectionLastIndex {
                return
            }
            // Prepare old/new ranges
            let oldRange = min(swipeSelectionSelectionFirstIndex,swipeSelectionSelectionLastIndex)...max(swipeSelectionSelectionFirstIndex,swipeSelectionSelectionLastIndex)
            let newRange = min(swipeSelectionSelectionFirstIndex,currIndex)...max(swipeSelectionSelectionFirstIndex,currIndex)
            // Collect indexes to restore or apply
            let indexesToRestore = oldRange.filter { !newRange.contains($0) }
            let indexesToApply = newRange.filter { !oldRange.contains($0) }
            // Do restore or apply
            if currIndex > swipeSelectionSelectionFirstIndex {
                indexesToApply.map { self.updateSwipeSelection($0, true) }
            } else {
                indexesToApply.reversed().map { self.updateSwipeSelection($0, true) }
            }
            indexesToRestore.map { self.updateSwipeSelection($0, false) }
            // Remember the new last index
            swipeSelectionSelectionLastIndex = currIndex
        default:
            break
        }
    }
    
    fileprivate func updateSwipeSelection(_ i: Int, _ isApply: Bool) {
        guard let collection = self.focusedCollection else {
            return
        }
        guard let asset = collection.getTLAsset(at: i) else {
            return
        }
        let wasSelected = self.selectedAssetsBeforeSwipeSelection.contains(asset)
        if isApply {
            if self.swipeSelectionIsAddingSelections && !wasSelected {
                self.selectIndexPath(IndexPath(row: i, section: 0), asset: asset)
            } else if !self.swipeSelectionIsAddingSelections && wasSelected {
                self.deselectIndexPath(IndexPath(row: i, section: 0), asset: asset)
            }
        } else {
            let isSelected = self.selectedAssets.contains(asset)
            if wasSelected && !isSelected {
                self.selectIndexPath(IndexPath(row: i, section: 0), asset: asset)
            } else if !wasSelected && isSelected {
                self.deselectIndexPath(IndexPath(row: i, section: 0), asset: asset)
            }
        }
    }
}
