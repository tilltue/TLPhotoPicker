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
        public static var textFont = UIFont.systemFont(ofSize: 12,
                                                       weight: .medium)
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

    /// Info label
    private(set) var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Style.textFont
        label.textColor = Style.infoTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Link label
    private(set) var linkLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Style.textFont
        label.textColor = Style.linkTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Link button
    private(set) var linkButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        setup()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    /// Setup initial values and states
    private func setup() {
        linkButton.addTarget(self,
                             action: #selector(linkButtonPressed(_:)),
                             for: .touchUpInside)
    }

    /// Setup UI items
    private func setupUI() {
        backgroundColor = Style.bgColor
        setInfoAndLinkText()

        addSubview(contentView)
        addSubview(linkButton)

        contentView.addSubview(infoLabel)
        contentView.addSubview(linkLabel)

        createLayoutConstraints()
    }

    /// Method used to set info text depending on the photo library access mode
    private func setInfoAndLinkText() {
        switch photoLibraryAccessType {
        case .full:
            break
        case .limited:
            infoLabel.text = photoPermissionsInfoModel.limitedAccessInfoText
            linkLabel.text = photoPermissionsInfoModel.limitedAccessLinkText
        case .noAccess:
            infoLabel.text = photoPermissionsInfoModel.noAccessInfoText
            linkLabel.text = photoPermissionsInfoModel.noAccessLinkText
        }
    }

    // MARK: - Actions

    /// Button that opens photo access options
    ///
    /// - Parameters:
    ///     - button: The link button
    @objc private func linkButtonPressed(_ button: UIButton) {
        delegate?.tlPhotoPermissionsInfoLinkButtonDidPress(photoLibraryAccessType)
    }

}
