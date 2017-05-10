//
//  TLPhotoCollectionViewCell.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 5. 3..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import PhotosUI

class TLPlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

class TLPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var playerView: TLPlayerView!
    @IBOutlet var livePhotoView: PHLivePhotoView!
    @IBOutlet var liveBadgeImageView: UIImageView!
    @IBOutlet var durationView: UIView!
    @IBOutlet var videoIconImageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var selectedHeight: NSLayoutConstraint!
    @IBOutlet var orderLabel: UILabel!
    @IBOutlet var orderBgView: UIView!
    
    var configure = TLPhotosPickerConfigure() {
        didSet {
            self.selectedView.layer.borderColor = self.configure.selectedColor.cgColor
            self.orderBgView.backgroundColor = self.configure.selectedColor
            self.videoIconImageView.image = self.configure.videoIcon
        }
    }
    
    var duration: TimeInterval? {
        didSet {
            guard let duration = self.duration else { return }
            self.selectedHeight.constant = -10
            self.durationLabel.text = timeFormatted(timeInterval: duration)
        }
    }
    
    var player: AVPlayer? = nil {
        didSet {
            if self.player == nil {
                self.playerView.playerLayer.player = nil
                NotificationCenter.default.removeObserver(self)
            }else {
                self.playerView.playerLayer.player = self.player
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil, using: { [weak self] (_) in
                    DispatchQueue.main.async {
                        guard let `self` = self else { return }
                        self.player?.seek(to: kCMTimeZero)
                        self.player?.play()
                    }
                })
            }
        }
    }
    
    var selectedAsset: Bool = false {
        willSet(newValue) {
            self.selectedView.isHidden = !newValue
            self.durationView.backgroundColor = newValue ? self.configure.selectedColor : UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
            if !newValue {
                self.orderLabel.text = ""
            }
        }
    }
    
    func timeFormatted(timeInterval: TimeInterval) -> String {
        let seconds: Int = lround(timeInterval)
        var hour: Int = 0
        var minute: Int = Int(seconds/60)
        let second: Int = seconds % 60
        if minute > 59 {
            hour = minute / 60
            minute = minute % 60
            return String(format: "%d:%d:%02d", hour, minute, second)
        } else {
            return String(format: "%d:%02d", minute, second)
        }
    }
    
    func popScaleAnim() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        }
    }
    
    func stopPlay() {
        if let player = self.player {
            player.pause()
            self.player = nil
        }
        self.livePhotoView.isHidden = true
        self.livePhotoView.stopPlayback()
    }
    
    deinit {
//        print("deinit TLPhotoCollectionViewCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.livePhotoView.isHidden = true
        self.durationView.isHidden = true
        self.selectedView.isHidden = true
        self.selectedView.layer.borderWidth = 10
        self.selectedView.layer.cornerRadius = 15
        self.orderBgView.layer.cornerRadius = 2
        self.videoIconImageView.image = self.configure.videoIcon
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.livePhotoView.isHidden = true
        self.durationView.isHidden = true
        self.durationView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        self.selectedHeight.constant = 10
        self.selectedAsset = false
    }
}
