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

            // Info label layout
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Link label layout
            linkLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor),
            linkLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            linkLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            // Link button layout
            linkButton.leadingAnchor.constraint(equalTo: linkLabel.leadingAnchor),
            linkButton.trailingAnchor.constraint(equalTo: linkLabel.trailingAnchor),
            linkButton.centerYAnchor.constraint(equalTo: linkLabel.centerYAnchor),
            linkButton.heightAnchor.constraint(equalToConstant: Layout.linkButtonHeight)
        ])
    }
}
