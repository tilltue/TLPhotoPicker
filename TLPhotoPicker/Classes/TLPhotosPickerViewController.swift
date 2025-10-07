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
import UniformTypeIdentifiers

open class TLPhotosPickerViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet open var navigationBar: UINavigationBar!
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
    @IBOutlet open var photosButton: UIBarButtonItem!

    // MARK: - Public Properties (API Compatibility)
    public weak var delegate: TLPhotosPickerViewControllerDelegate? = nil
    public weak var logDelegate: TLPhotosPickerLogDelegate? = nil

    /// Selected assets - public API maintained for backward compatibility
    open var selectedAssets: [TLPHAsset] {
        get { return state.selectedAssets }
        set { state.selectedAssets = newValue }
    }

    /// Configuration - synced with state
    public var configure: TLPhotosPickerConfigure {
        get { return state.configure }
        set { state.configure = newValue }
    }

    public var customDataSouces: TLPhotopickerDataSourcesProtocol? = nil

    // MARK: - Service Layer (Eager initialization for thread safety and debugging)
    private let state: TLPhotosPickerState
    private let selectionService: TLPhotoSelectionService
    private let libraryService: TLPhotoLibraryService

    // MARK: - Adapters
    private lazy var collectionViewAdapter: TLCollectionViewAdapter = {
        let adapter = TLCollectionViewAdapter(
            state: state,
            selectionService: selectionService,
            libraryService: libraryService
        )
        adapter.viewController = self
        return adapter
    }()

    private lazy var cameraService: TLCameraService = {
        let service = TLCameraService(
            state: state,
            selectionService: selectionService,
            presentingViewController: self
        )
        service.handleNoCameraPermissions = { [weak self] in
            guard let self = self else { return }
            self.delegate?.handleNoCameraPermissions(picker: self)
            self.handleNoCameraPermissions?(self)
        }
        service.logDelegate = self.logDelegate
        return service
    }()

    private lazy var videoPlayerService: TLVideoPlayerService = {
        let service = TLVideoPlayerService(
            state: state,
            selectionService: selectionService,
            photoLibrary: photoLibrary,
            collectionView: collectionView
        )
        return service
    }()

    // MARK: - Configuration Accessors
    private var usedCameraButton: Bool {
        return state.configure.usedCameraButton
    }
    private var previewAtForceTouch: Bool {
        return state.configure.previewAtForceTouch
    }
    private var allowedVideo: Bool {
        return state.configure.allowedVideo
    }
    private var usedPrefetch: Bool {
        get { return state.configure.usedPrefetch }
        set { state.configure.usedPrefetch = newValue }
    }
    private var allowedLivePhotos: Bool {
        get { return state.configure.allowedLivePhotos }
        set { state.configure.allowedLivePhotos = newValue }
    }

    // MARK: - Legacy Callbacks (maintained for compatibility)
    @objc open var canSelectAsset: ((PHAsset) -> Bool)? = nil
    @objc open var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var handleNoAlbumPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var handleNoCameraPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var dismissCompletion: (() -> Void)? = nil
    private var completionWithPHAssets: (([PHAsset]) -> Void)? = nil
    private var completionWithTLPHAssets: (([TLPHAsset]) -> Void)? = nil
    private var didCancel: (() -> Void)? = nil

    // MARK: - State Accessors (for backward compatibility with extensions)
    var collections: [TLAssetsCollection] {
        get { return state.collections }
        set { state.collections = newValue }
    }
    var focusedCollection: TLAssetsCollection? {
        get { return state.focusedCollection }
        set { state.focusedCollection = newValue }
    }
    var requestIDs: SynchronizedDictionary<IndexPath, PHImageRequestID> {
        get { return state.requestIDs }
        set { state.requestIDs = newValue }
    }
    var playRequestID: (indexPath: IndexPath, requestID: PHImageRequestID)? {
        get { return state.playRequestID }
        set { state.playRequestID = newValue }
    }

    // MARK: - Legacy Properties (kept for existing extensions)
    var photoLibrary = TLPhotoLibrary()
    var queue = DispatchQueue(label: "tilltue.photos.pikcker.queue")
    var queueForGroupedBy = DispatchQueue(label: "tilltue.photos.pikcker.queue.for.groupedBy", qos: .utility)
    var thumbnailSize = CGSize.zero
    var placeholderThumbnail: UIImage? = nil
    var cameraImage: UIImage? = nil
    
    deinit {
        //print("deinit TLPhotosPickerViewController")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init() {
        // Initialize services eagerly for thread safety and debugging
        self.state = TLPhotosPickerState(configure: TLPhotosPickerConfigure())
        self.selectionService = TLPhotoSelectionService(state: state)
        self.libraryService = TLPhotoLibraryService(state: state)

        super.init(nibName: "TLPhotosPickerViewController", bundle: TLBundle.bundle())

        // Configure service delegates after super.init
        self.selectionService.delegate = self.delegate
    }
    
    @objc convenience public init(withPHAssets: (([PHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        self.completionWithPHAssets = withPHAssets
        self.didCancel = didCancel
    }
    
    convenience public init(withTLPHAssets: (([TLPHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        self.completionWithTLPHAssets = withTLPHAssets
        self.didCancel = didCancel
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.configure.supportedInterfaceOrientations
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.forceTouchCapability == .available && self.previewAtForceTouch {
            registerForPreviewing(with: self, sourceView: collectionView)
        }

        updateUserInterfaceStyle()
    }
    
    private func updateUserInterfaceStyle() {
        if #available(iOS 13.0, *) {
            let userInterfaceStyle = self.traitCollection.userInterfaceStyle
            let image = TLBundle.podBundleImage(named: "pop_arrow")
            let subImage = TLBundle.podBundleImage(named: "arrow")
            if userInterfaceStyle.rawValue == 2 {
                self.popArrowImageView.image = image?.colorMask(color: .systemBackground)
                self.subTitleArrowImageView.image = subImage?.colorMask(color: .white)
                self.view.backgroundColor = .black
                self.collectionView.backgroundColor = .black
            } else {
                self.popArrowImageView.image = image?.colorMask(color: .white)
                self.subTitleArrowImageView.image = subImage
                self.view.backgroundColor = .white
                self.collectionView.backgroundColor = .white
            }
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.videoPlayerService.stopPlay()
    }
    
    private func loadPhotos(limitMode: Bool) {
        self.libraryService.configurePhotoLibrary(limitMode: limitMode, delegate: self)
        self.libraryService.fetchCollections(configure: self.configure)
    }
    
    private func handleDeniedAlbumsAuthorization() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.handleNoAlbumPermissions(picker: self)
            self.handleNoAlbumPermissions?(self)
        }
    }

    private func processAuthorization(status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            requestAuthorization()
        case .limited:
            loadPhotos(limitMode: true)
        case .authorized:
            loadPhotos(limitMode: false)
        case .restricted, .denied:
            handleDeniedAlbumsAuthorization()
        @unknown default:
            break
        }
    }
    
    private func requestAuthorization() {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for:  .readWrite) { [weak self] status in
                self?.processAuthorization(status: status)
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                self?.processAuthorization(status: status)
            }
        }
    }
    
    private func checkAuthorization() {
        if #available(iOS 14.0, *) {
            let status = PHPhotoLibrary.authorizationStatus(for:  .readWrite)
            processAuthorization(status: status)
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            processAuthorization(status: status)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        checkAuthorization()
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
            checkAuthorization()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            self.thumbnailSize = CGSize.zero
    }
    
    private func findIndexAndReloadCells(phAsset: PHAsset) {
        if
            self.configure.groupByFetch != nil,
            let indexPath = self.focusedCollection?.findIndex(phAsset: phAsset)
        {
            self.collectionView.reloadItems(at: [indexPath])
            return
        }
        if
            var index = self.focusedCollection?.fetchResult?.index(of: phAsset),
            let focused = self.focusedCollection,
            index != NSNotFound
        {
            index += (focused.useCameraButton) ? 1 : 0
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    open func deselectWhenUsingSingleSelectedMode() {
        if
            self.configure.singleSelectedMode == true,
            let selectedPHAsset = self.selectedAssets.first?.phAsset
        {
            self.selectedAssets.removeAll()
            findIndexAndReloadCells(phAsset: selectedPHAsset)
        }
    }
    
    open func maxCheck() -> Bool {
        deselectWhenUsingSingleSelectedMode()
        if let max = self.configure.maxSelectedAssets, max <= self.selectedAssets.count {
            self.delegate?.didExceedMaximumNumberOfSelection(picker: self)
            self.didExceedMaximumNumberOfSelection?(self)
            return true
        }
        return false
    }
}

// MARK: - UI & UI Action
extension TLPhotosPickerViewController {
    
    @objc public func registerNib(nibName: String, bundle: Bundle) {
        self.collectionView.register(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier: nibName)
    }
    
    private func centerAtRect(image: UIImage?, rect: CGRect, bgColor: UIColor = UIColor.white) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        bgColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        image.draw(in: CGRect(x:rect.size.width/2 - image.size.width/2, y:rect.size.height/2 - image.size.height/2, width:image.size.width, height:image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    private func initItemSize() {
        guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        let count = CGFloat(self.configure.numberOfColumn)
        let width = floor((self.view.frame.size.width - (self.configure.minimumInteritemSpacing * (count-1))) / count)
        self.thumbnailSize = CGSize(width: width, height: width)
        layout.itemSize = self.thumbnailSize
        layout.minimumInteritemSpacing = self.configure.minimumInteritemSpacing
        layout.minimumLineSpacing = self.configure.minimumLineSpacing
        self.collectionView.collectionViewLayout = layout
        self.placeholderThumbnail = centerAtRect(image: self.configure.placeholderIcon, rect: CGRect(x: 0, y: 0, width: width, height: width))
        self.cameraImage = centerAtRect(image: self.configure.cameraIcon, rect: CGRect(x: 0, y: 0, width: width, height: width), bgColor: self.configure.cameraBgColor)

        // Configure adapter and video service with UI elements
        self.collectionViewAdapter.configure(
            thumbnailSize: self.thumbnailSize,
            placeholderThumbnail: self.placeholderThumbnail,
            cameraImage: self.cameraImage
        )
        self.videoPlayerService.thumbnailSize = self.thumbnailSize
    }
    
    @objc open func makeUI() {
        registerNib(nibName: "TLPhotoCollectionViewCell", bundle: TLBundle.bundle())
        if let nibSet = self.configure.nibSet {
            registerNib(nibName: nibSet.nibName, bundle: nibSet.bundle)
        }
        if let nibSet = self.configure.cameraCellNibSet {
            registerNib(nibName: nibSet.nibName, bundle: nibSet.bundle)
        }
        self.indicator.startAnimating()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(titleTap))
        self.titleView.addGestureRecognizer(tapGesture)
        self.titleLabel.text = self.configure.customLocalizedTitle["Camera Roll"]
        self.subTitleLabel.text = self.configure.tapHereToChange
        self.cancelButton.title = self.configure.cancelTitle
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)]
        self.doneButton.setTitleTextAttributes(attributes, for: .normal)
        self.doneButton.title = self.configure.doneTitle
        self.emptyView.isHidden = true
        self.emptyImageView.image = self.configure.emptyImage
        self.emptyMessageLabel.text = self.configure.emptyMessage

        // Setup CollectionView Adapter
        self.collectionView.delegate = self.collectionViewAdapter
        self.collectionView.dataSource = self.collectionViewAdapter
        if #available(iOS 10.0, *), self.usedPrefetch {
            self.collectionView.isPrefetchingEnabled = true
            self.collectionView.prefetchDataSource = self.collectionViewAdapter
        } else {
            self.usedPrefetch = false
        }

        // Setup TableView (Album selection)
        self.albumPopView.tableView.delegate = self
        self.albumPopView.tableView.dataSource = self
        self.popArrowImageView.image = TLBundle.podBundleImage(named: "pop_arrow")
        self.subTitleArrowImageView.image = TLBundle.podBundleImage(named: "arrow")
        if #available(iOS 9.0, *), self.allowedLivePhotos {
        } else {
            self.allowedLivePhotos = false
        }
        self.customDataSouces?.registerSupplementView(collectionView: self.collectionView)
        self.navigationBar.delegate = self
        updateUserInterfaceStyle()
    }
    
    private func updatePresentLimitedLibraryButton() {
        if #available(iOS 14.0, *), self.photoLibrary.limitMode && self.configure.preventAutomaticLimitedAccessAlert {
            self.customNavItem.rightBarButtonItems = [self.doneButton, self.photosButton]
        } else {
            self.customNavItem.rightBarButtonItems = [self.doneButton]
        }
    }
    
    private func updateTitle() {
        guard self.focusedCollection != nil else { return }
        self.titleLabel.text = self.focusedCollection?.title
        updatePresentLimitedLibraryButton()
    }
    
    private func reloadCollectionView() {
        guard self.focusedCollection != nil else {
            return
        }
        if let groupedBy = self.configure.groupByFetch, self.usedPrefetch == false {
            queueForGroupedBy.async { [weak self] in
                self?.focusedCollection?.reloadSection(groupedBy: groupedBy)
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            }
        }else {
            self.collectionView.reloadData()
        }
    }
    
    private func reloadTableView() {
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
    
    private func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    func getfocusedIndex() -> Int {
        guard let focused = self.focusedCollection, let result = self.collections.firstIndex(where: { $0 == focused }) else { return 0 }
        return result
    }

    private func getCollection(section: Int) -> PHAssetCollection? {
        guard section < self.collections.count else {
            return nil
        }
        return self.collections[section].phAssetCollection
    }

    func focused(collection: TLAssetsCollection) {
        func resetRequest() {
            cancelAllImageAssets()
        }
        resetRequest()
        self.collections[getfocusedIndex()].recentPosition = self.collectionView.contentOffset
        var reloadIndexPaths = [IndexPath(row: getfocusedIndex(), section: 0)]
        self.focusedCollection = collection
        self.focusedCollection?.fetchResult = self.photoLibrary.fetchResult(collection: collection, configure: self.configure)
        reloadIndexPaths.append(IndexPath(row: getfocusedIndex(), section: 0))
        self.albumPopView.tableView.reloadRows(at: reloadIndexPaths, with: .none)
        self.albumPopView.show(false, duration: self.configure.popup.duration)
        self.updateTitle()
        self.reloadCollectionView()
        self.collectionView.contentOffset = collection.recentPosition
    }
    
    private func cancelAllImageAssets() {
        self.requestIDs.forEach{ (indexPath, requestID) in
            self.photoLibrary.cancelPHImageRequest(requestID: requestID)
        }
        self.requestIDs.removeAll()
    }
    
    // User Action
    @objc func titleTap() {
        guard collections.count > 0 else { return }
        self.albumPopView.show(self.albumPopView.isHidden, duration: self.configure.popup.duration)
    }
    
    @IBAction open func cancelButtonTap() {
        self.videoPlayerService.stopPlay()
        self.dismiss(done: false)
    }

    @IBAction open func doneButtonTap() {
        self.videoPlayerService.stopPlay()
        self.dismiss(done: true)
    }
    
    @IBAction open func limitButtonTap() {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        }
    }
    
    private func dismiss(done: Bool) {
        var shouldDismiss = true
        if done {
            #if swift(>=4.1)
            self.delegate?.dismissPhotoPicker(withPHAssets: self.selectedAssets.compactMap{ $0.phAsset })
            #else
            self.delegate?.dismissPhotoPicker(withPHAssets: self.selectedAssets.flatMap{ $0.phAsset })
            #endif
            self.delegate?.dismissPhotoPicker(withTLPHAssets: self.selectedAssets)
            shouldDismiss = self.delegate?.shouldDismissPhotoPicker(withTLPHAssets: self.selectedAssets) ?? true
            self.completionWithTLPHAssets?(self.selectedAssets)
            #if swift(>=4.1)
            self.completionWithPHAssets?(self.selectedAssets.compactMap{ $0.phAsset })
            #else
            self.completionWithPHAssets?(self.selectedAssets.flatMap{ $0.phAsset })
            #endif
        }else {
            self.delegate?.photoPickerDidCancel()
            self.didCancel?()
        }
        if shouldDismiss {
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.dismissComplete()
                self?.dismissCompletion?()
            }
        }
    }
    
    private func canSelect(phAsset: PHAsset) -> Bool {
        if let closure = self.canSelectAsset {
            return closure(phAsset)
        }else if let delegate = self.delegate {
            return delegate.canSelectAsset(phAsset: phAsset)
        }
        return true
    }
    
    private func focusFirstCollection() {
        if self.focusedCollection == nil, let collection = self.collections.first {
            self.focusedCollection = collection
            self.updateTitle()
            self.reloadCollectionView()
        }
    }
}

// MARK: - TLPhotoLibraryDelegate
extension TLPhotosPickerViewController: TLPhotoLibraryDelegate {
    func loadCameraRollCollection(collection: TLAssetsCollection) {
        self.collections = [collection]
        self.focusFirstCollection()
        self.indicator.stopAnimating()
        self.reloadTableView()
    }
    
    func loadCompleteAllCollection(collections: [TLAssetsCollection]) {
        self.collections = collections
        self.focusFirstCollection()
        let isEmpty = !self.collections.contains(where: { $0.assetCount > 0 })
        self.subTitleStackView.isHidden = isEmpty
        self.emptyView.isHidden = !isEmpty
        self.emptyImageView.isHidden = self.emptyImageView.image == nil
        self.indicator.stopAnimating()
        self.reloadTableView()
        self.registerChangeObserver()
    }
}

// MARK: - Camera Picker (Delegated to TLCameraService)
// Camera capture functionality moved to TLCameraService for better separation of concerns

// MARK: - UICollectionView Scroll Delegate (Delegated to TLVideoPlayerService)
extension TLPhotosPickerViewController {
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            videoPlayerService.videoCheck()
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        videoPlayerService.videoCheck()
    }
}

// MARK: - Video & LivePhotos Control PHLivePhotoViewDelegate
extension TLPhotosPickerViewController: PHLivePhotoViewDelegate {
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoView.isMuted = true
        livePhotoView.startPlayback(with: self.configure.startplayBack)
    }

    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension TLPhotosPickerViewController: PHPhotoLibraryChangeObserver {
    private func getChanges(_ changeInstance: PHChange) -> PHFetchResultChangeDetails<PHAsset>? {
        func isChangesCount<T>(changeDetails: PHFetchResultChangeDetails<T>?) -> Bool {
            guard let changeDetails = changeDetails else {
                return false
            }
            let before = changeDetails.fetchResultBeforeChanges.count
            let after = changeDetails.fetchResultAfterChanges.count
            return before != after
        }
        
        func isAlbumsChanges() -> Bool {
            guard let albums = self.photoLibrary.albums else {
                return false
            }
            let changeDetails = changeInstance.changeDetails(for: albums)
            return isChangesCount(changeDetails: changeDetails)
        }
        
        func isCollectionsChanges() -> Bool {
            for fetchResultCollection in self.photoLibrary.assetCollections {
                let changeDetails = changeInstance.changeDetails(for: fetchResultCollection)
                if isChangesCount(changeDetails: changeDetails) == true {
                    return true
                }
            }
            return false
        }
        
        if isAlbumsChanges() || isCollectionsChanges() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.albumPopView.show(false, duration: self.configure.popup.duration)
                self.libraryService.fetchCollections(configure: self.configure)
            }
            return nil
        }else {
            guard let changeFetchResult = self.focusedCollection?.fetchResult else { return nil }
            guard let changes = changeInstance.changeDetails(for: changeFetchResult) else { return nil }
            return changes
        }
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        var addIndex = 0
        if getfocusedIndex() == 0 {
            addIndex = self.usedCameraButton ? 1 : 0
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let changes = self.getChanges(changeInstance) else {
                return
            }
            
            if changes.hasIncrementalChanges, self.configure.groupByFetch == nil {
                var deletedSelectedAssets = false
                var order = 0
                #if swift(>=4.1)
                self.selectedAssets = self.selectedAssets.enumerated().compactMap({ (offset,asset) -> TLPHAsset? in
                    var asset = asset
                    if let phAsset = asset.phAsset, changes.fetchResultAfterChanges.contains(phAsset) {
                        order += 1
                        asset.selectedOrder = order
                        return asset
                    }
                    deletedSelectedAssets = true
                    return nil
                })
                #else
                self.selectedAssets = self.selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
                    var asset = asset
                    if let phAsset = asset.phAsset, changes.fetchResultAfterChanges.contains(phAsset) {
                        order += 1
                        asset.selectedOrder = order
                        return asset
                    }
                    deletedSelectedAssets = true
                    return nil
                })
                #endif
                if deletedSelectedAssets {
                    self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                    self.reloadCollectionView()
                }else {
                    self.collectionView.performBatchUpdates({ [weak self] in
                        guard let `self` = self else { return }
                        self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                        if let removed = changes.removedIndexes, removed.count > 0 {
                            self.collectionView.deleteItems(at: removed.map { IndexPath(item: $0+addIndex, section:0) })
                        }
                        if let inserted = changes.insertedIndexes, inserted.count > 0 {
                            self.collectionView.insertItems(at: inserted.map { IndexPath(item: $0+addIndex, section:0) })
                        }
                        changes.enumerateMoves { fromIndex, toIndex in
                            self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                         to: IndexPath(item: toIndex, section: 0))
                        }
                    }, completion: { [weak self] (completed) in
                        guard let `self` = self else { return }
                        if completed {
                            if let changed = changes.changedIndexes, changed.count > 0 {
                                self.collectionView.reloadItems(at: changed.map { IndexPath(item: $0+addIndex, section:0) })
                            }
                        }
                    })
                }
            }else {
                self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                self.reloadCollectionView()
            }
            if let collection = self.focusedCollection {
                self.collections[self.getfocusedIndex()] = collection
                self.albumPopView.tableView.reloadRows(at: [IndexPath(row: self.getfocusedIndex(), section: 0)], with: .none)
            }
        }
    }
}

// MARK: - UITableView datasource & delegate
extension TLPhotosPickerViewController: UITableViewDelegate, UITableViewDataSource {
    //delegate
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.logDelegate?.selectedAlbum(picker: self, title: self.collections[indexPath.row].title, at: indexPath.row)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "TLCollectionTableViewCell", for: indexPath) as! TLCollectionTableViewCell
        let collection = self.collections[indexPath.row]
        cell.titleLabel.text = collection.title
        cell.subTitleLabel.text = "\(collection.fetchResult?.count ?? 0)"
        if let phAsset = collection.getAsset(at: collection.useCameraButton ? 1 : 0) {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 80*scale, height: 80*scale)
            self.photoLibrary.imageAsset(asset: phAsset, size: size, completionBlock: { [weak self] (image,complete) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let cell = tableView.cellForRow(at: indexPath) as? TLCollectionTableViewCell {
                        cell.thumbImageView.image = image
                    }
                }
            })
        }
        cell.accessoryType = getfocusedIndex() == indexPath.row ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension TLPhotosPickerViewController: UIViewControllerPreviewingDelegate {
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard self.previewAtForceTouch == true else { return nil }
        guard let pressingIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let pressingCell = collectionView.cellForItem(at: pressingIndexPath) as? TLPhotoCollectionViewCell else { return nil }
    
        previewingContext.sourceRect = pressingCell.frame
        let previewController = TLAssetPreviewViewController()
        previewController.asset = pressingCell.asset
        
        return previewController
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {}
    
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard self.previewAtForceTouch == true else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                let previewController = TLAssetPreviewViewController()
                previewController.asset = cell.asset
                return previewController
            
            }, actionProvider: { [weak self] suggestedActions in
                guard let self = self else { return nil }
                let isSelected = cell.selectedAsset
                let title = isSelected ? self.configure.deselectMessage : self.configure.selectMessage
                let imageName = isSelected ? "checkmark.circle" : "circle"
                let toggleSelection = UIAction(title: title, image: UIImage(systemName: imageName)) { [weak self] action in
                    self?.toggleSelection(for: cell, at: indexPath)
                }

                return UIMenu(title: "", children: [toggleSelection])
            }
        )
    }
}

extension TLPhotosPickerViewController {
    func selectCameraCell(_ cell: TLPhotoCollectionViewCell) {
        if Platform.isSimulator {
            print("not supported by the simulator.")
        } else {
            if configure.cameraCellNibSet?.nibName != nil {
                cell.selectedCell()
            } else {
                cameraService.showCameraIfAuthorized()
            }
            logDelegate?.selectedCameraCell(picker: self)
        }
    }
    
    func toggleSelection(for cell: TLPhotoCollectionViewCell, at indexPath: IndexPath) {
        guard let collection = focusedCollection, var asset = collection.getTLAsset(at: indexPath), let phAsset = asset.phAsset else { return }
        
        cell.popScaleAnim()
        
        if let index = selectedAssets.firstIndex(where: { $0.phAsset == asset.phAsset }) {
        //deselect
            logDelegate?.deselectedPhoto(picker: self, at: indexPath.row)
            selectedAssets.remove(at: index)
            #if swift(>=4.1)
            selectedAssets = selectedAssets.enumerated().compactMap({ (offset,asset) -> TLPHAsset? in
                var asset = asset
                asset.selectedOrder = offset + 1
                return asset
            })
            #else
            selectedAssets = selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
                var asset = asset
                asset.selectedOrder = offset + 1
                return asset
            })
            #endif
            cell.selectedAsset = false
            cell.stopPlay()
            collectionViewAdapter.orderUpdateCells(in: collectionView)
            if playRequestID?.indexPath == indexPath {
                videoPlayerService.stopPlay()
            }
        } else {
        //select
            logDelegate?.selectedPhoto(picker: self, at: indexPath.row)
            guard !maxCheck(), canSelect(phAsset: phAsset) else { return }
            
            asset.selectedOrder = selectedAssets.count + 1
            selectedAssets.append(asset)
            cell.selectedAsset = true
            cell.orderLabel?.text = "\(asset.selectedOrder)"

            if asset.type != .photo, configure.autoPlay {
                videoPlayerService.playVideo(asset: asset, at: indexPath)
            }
        }

    }
}

extension TLPhotosPickerViewController: UINavigationBarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension Array where Element == PopupConfigure {
    var duration: TimeInterval {
        var result: TimeInterval = 0.1
        forEach {
            if case let .animation(duration) = $0 {
                result = duration
            }
        }
        return result
    }
}

extension UIImage {
    public func colorMask(color:UIColor) -> UIImage {
        var result: UIImage?
        let rect = CGRect(x:0, y:0, width:size.width, height:size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        if let c = UIGraphicsGetCurrentContext() {
            self.draw(in: rect)
            c.setFillColor(color.cgColor)
            c.setBlendMode(.sourceAtop)
            c.fill(rect)
            result = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return result ?? self
    }
}
