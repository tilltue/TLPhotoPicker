import UIKit
import Photos
import PhotosUI

open class TLAssetPreviewViewController: UIViewController {
    
    fileprivate var player: AVPlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    
    fileprivate let imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    fileprivate let livePhotoView = PHLivePhotoView()

    open var asset: PHAsset? {
        didSet {
            guard let asset = self.asset else {
                livePhotoView.livePhoto = nil
                imageView.image = nil
                return
            }

            updatePreferredContentSize(for: asset, isPortrait: UIApplication.shared.orientation?.isPortrait == true)
            
            if asset.mediaType == .image {
                previewImage(from: asset)
            } else {
                previewVideo(from: asset)
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = imageView.bounds
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let asset = self.asset {
            updatePreferredContentSize(for: asset, isPortrait: size.height > size.width)
        }
    }

    deinit {
        player?.pause()
    }
}

private extension TLAssetPreviewViewController {
    func setupViews() {
        view.backgroundColor = .previewBackground
        view.addAligned(imageView)
        view.addAligned(livePhotoView)
    }
    
    func fetchImage(for asset: PHAsset, canHandleDegraded: Bool = true, completion: @escaping ((UIImage?) -> Void)) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFit,
            options: options,
            resultHandler: { (image, info) in
                if !canHandleDegraded {
                    if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                }
                completion(image)
        })
    }
    
    func updatePreferredContentSize(for asset: PHAsset, isPortrait: Bool) {
        guard asset.pixelWidth != 0 && asset.pixelHeight != 0 else { return }
        
        let contentScale: CGFloat = 1
        let assetWidth = CGFloat(asset.pixelWidth)
        let assetHeight = CGFloat(asset.pixelHeight)
        let assetRatio = assetHeight / assetWidth
        let screenWidth = isPortrait ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
        let screenHeight = isPortrait ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let screenRatio = screenHeight / screenWidth
        
        if assetRatio > screenRatio {
            let scale = screenHeight / assetHeight
            preferredContentSize = CGSize(width: assetWidth * scale * contentScale, height: assetHeight * scale * contentScale)
        } else {
            let scale = screenWidth / assetWidth
            preferredContentSize = CGSize(width: assetWidth * scale * contentScale, height: assetHeight * scale * contentScale)
        }
    }
    
    func previewVideo(from asset: PHAsset) {
        livePhotoView.isHidden = true
        PHCachingImageManager.default().requestAVAsset(
            forVideo: asset,
            options: nil,
            resultHandler: { (avAsset, audio, info) in
                DispatchQueue.main.async { [weak self] in
                    self?.imageView.isHidden = false
                    
                    if let avAsset = avAsset {
                        let playerItem = AVPlayerItem(asset: avAsset)
                        let player = AVPlayer(playerItem: playerItem)
                        let playerLayer = AVPlayerLayer(player: player)
                        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                        playerLayer.masksToBounds = true
                        playerLayer.frame = self?.imageView.bounds ?? .zero
                        
                        self?.imageView.layer.addSublayer(playerLayer)
                        self?.playerLayer = playerLayer
                        self?.player = player
                        
                        player.play()
                    } else {
                        self?.previewPhoto(from: asset)
                    }
                }
        })
    }

    func previewImage(from asset: PHAsset) {
        imageView.isHidden = true
        livePhotoView.isHidden = false
        
        if asset.mediaSubtypes == .photoLive {
            previewLivePhoto(from: asset)
        } else {
            previewPhoto(from: asset)
        }
    }
    
    func previewLivePhoto(from asset: PHAsset) {
        
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        PHCachingImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFill,
            options: options,
            resultHandler: { [weak self] (livePhoto, info) in
                if let livePhoto = livePhoto, info?[PHImageErrorKey] == nil {
                    self?.livePhotoView.livePhoto = livePhoto
                    self?.livePhotoView.startPlayback(with: .full)
                } else {
                    self?.previewPhoto(from: asset)
                }
        })
    }
    
    func previewPhoto(from asset: PHAsset) {
        imageView.isHidden = false
        fetchImage(for: asset, canHandleDegraded: false, completion: { self.imageView.image = $0 })
    }
}

private extension UIColor {
    static var previewBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
}

private extension UIView {
    func addAligned(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private extension UIApplication {
    var orientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            return windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation
        } else {
            return statusBarOrientation
        }
    }
}
