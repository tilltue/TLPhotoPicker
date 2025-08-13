//
//  TLPhotoPermissionsInfoView.swift
//
//
//  Created by Viachaslau Holikau on 20.11.24.
//

import UIKit

/// TLPhotoPermissionsInfo View delegate
public protocol TLPhotoPermissionsInfoViewDelegate: AnyObject {
    /// Notifies that the link button has been pressed
    ///
    /// - Parameters:
    ///     - photoLibraryAccessType: The access type of the Photo library
    func tlPhotoPermissionsInfoLinkButtonDidPress(_ photoLibraryAccessType: TLPhotoLibraryAccessType)
}

/// Enum of photo library access types
public enum TLPhotoLibraryAccessType {
    /// Full access
    case full
    /// Limited access
    case limited
    /// No access
    case noAccess
}

/// Class to display the photo permissions info view
open class TLPhotoPermissionsInfoView: UIView {

    // MARK: - Style

    /// Structure containing variables associated with this class
    public struct Style {
        /// Color of the view
        public static var bgColor = UIColor.white
        /// Text font
        public static var textFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        /// Color of the info text
        public static var infoTextColor = UIColor.black
        /// Color of the link text
        public static var linkTextColor = UIColor(red: 37 / 255,
                                                  green: 128 / 255,
                                                  blue: 235 / 255,
                                                  alpha: 1)
    }

    // MARK: - Layout configuration

    /// Layout specific configuration
    public struct Layout {
        public static var linkButtonHeight: CGFloat = 35
        /// Value of the top constraint of the content view
        public static var contentViewTopConstraintValue: CGFloat = 14
        /// Value of the leading constraint of the content view
        public static var contentViewleadingConstraintValue: CGFloat = 24
        /// Value of the trailing constraint of the content view
        public static var contentViewTrailingConstraintValue: CGFloat = -24
        /// Value of the bottom constraint of the content view
        public static var contentViewBottomConstraintValue: CGFloat = -50
    }

    // MARK: - Properties

    /// Content view
    private(set) var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Single label with info text + link
    private(set) var infoAndLinkLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Style.textFont
        label.textColor = Style.infoTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()

    /// The object that acts as the delegate of the TLPhotoPermissionsInfoView
    public weak var delegate: TLPhotoPermissionsInfoViewDelegate?

    /// Photo library access mode
    public var photoLibraryAccessType: TLPhotoLibraryAccessType {
        didSet {
            setInfoAndLinkText()
        }
    }

    /// The model of the photo permissions info
    private var photoPermissionsInfoModel: TLPhotoPermissionsInfoModel

    // MARK: - Init

    /// Creates a photo permissions info view
    ///
    /// - Parameters:
    ///     - photoLibraryAccessType: The access type of the Photo library
    ///     - photoPermissionsInfoModel: The model of the photo permissions info view
    public init(photoLibraryAccessType: TLPhotoLibraryAccessType,
                photoPermissionsInfoModel: TLPhotoPermissionsInfoModel) {
        self.photoLibraryAccessType = photoLibraryAccessType
        self.photoPermissionsInfoModel = photoPermissionsInfoModel
        super.init(frame: .zero)
        setupUI()
        setupGesture()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = Style.bgColor
        addSubview(contentView)
        contentView.addSubview(infoAndLinkLabel)

        createLayoutConstraints()
        setInfoAndLinkText()
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:)))
        infoAndLinkLabel.addGestureRecognizer(tapGesture)
    }

    // MARK: - Text Setup
    /// Method used to set info text depending on the photo library access mode
    private func setInfoAndLinkText() {
        let infoText: String
        let linkText: String

        switch photoLibraryAccessType {
        case .full:
            // Assuming no info or link for full access, empty or customize as needed
            infoAndLinkLabel.attributedText = nil
            return
        case .limited:
            infoText = photoPermissionsInfoModel.limitedAccessInfoText
            linkText = photoPermissionsInfoModel.limitedAccessLinkText
        case .noAccess:
            infoText = photoPermissionsInfoModel.noAccessInfoText
            linkText = photoPermissionsInfoModel.noAccessLinkText
        }

        let fullText = infoText + " " + linkText

        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: Style.textFont,
                .foregroundColor: Style.infoTextColor
            ])

        if let linkRange = fullText.range(of: linkText) {
            let nsRange = NSRange(linkRange, in: fullText)
            attributedString.addAttributes([
                .foregroundColor: Style.linkTextColor
            ], range: nsRange)
        }

        infoAndLinkLabel.attributedText = attributedString
    }

    // MARK: - Gesture Handler

    @objc private func handleTapOnLabel(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let attributedText = label.attributedText else { return }

        let linkText: String = {
            switch photoLibraryAccessType {
            case .full: return ""
            case .limited: return photoPermissionsInfoModel.limitedAccessLinkText
            case .noAccess: return photoPermissionsInfoModel.noAccessLinkText
            }
        }()

        guard !linkText.isEmpty,
              let text = attributedText.string as String?,
              let linkRange = text.range(of: linkText) else { return }

        let nsRange = NSRange(linkRange, in: text)

        // Setup TextKit components for precise tap detection
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        let location = gesture.location(in: label)

        // Find character index tapped
        let characterIndex = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil)

        // Check if tap was inside link range
        if NSLocationInRange(characterIndex, nsRange) {
            delegate?.tlPhotoPermissionsInfoLinkButtonDidPress(photoLibraryAccessType)
        }
    }
}
