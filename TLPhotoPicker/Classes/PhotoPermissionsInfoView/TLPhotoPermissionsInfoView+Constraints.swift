//
//  TLPhotoPermissionsInfoView+Constraints.swift
//
//
//  Created by Viachaslau Holikau on 21.11.24.
//

import UIKit

extension TLPhotoPermissionsInfoView {
    /// Creates layout
    func createLayoutConstraints() {
        NSLayoutConstraint.activate([
            // Content view layout
            contentView.topAnchor.constraint(equalTo: topAnchor,
                                             constant: Layout.contentViewTopConstraintValue),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                constant: Layout.contentViewBottomConstraintValue),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                 constant: Layout.contentViewleadingConstraintValue),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: Layout.contentViewTrailingConstraintValue),

            // infoAndLinkLabel fills the contentView fully
            infoAndLinkLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoAndLinkLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoAndLinkLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoAndLinkLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
