//
//  CustomDataSources.swift
//  TLPhotoPicker_Example
//
//  Created by wade.hawk on 21/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Photos
import TLPhotoPicker

struct CustomDataSources: TLPhotopickerDataSourcesProtocol {
    func customLayout(layout: UICollectionViewFlowLayout) -> UICollectionViewFlowLayout {
        let layout = layout
        layout.headerReferenceSize = CGSize(width: 320, height: 50)
        layout.footerReferenceSize = CGSize(width: 320, height: 50)
        return layout
    }
    
    func supplementIdentifier(kind: String) -> String {
        if kind == UICollectionView.elementKindSectionHeader {
            return "CustomHeaderView"
        }else {
            return "CustomFooterView"
        }
    }
    
    func registerSupplementView(collectionView: UICollectionView) {
        let headerNib = UINib(nibName: "CustomHeaderView", bundle: Bundle.main)
        collectionView.register(headerNib,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "CustomHeaderView")
        let footerNib = UINib(nibName: "CustomFooterView", bundle: Bundle.main)
        collectionView.register(footerNib,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: "CustomFooterView")
    }
    
    func configure(supplement view: UICollectionReusableView, collection: PHAssetCollection) {
        if let reuseView = view as? CustomHeaderView {
            reuseView.titleLabel.text = "Header"
        }else if let reuseView = view as? CustomFooterView {
            reuseView.titleLabel.text = "Footer"
        }
    }
}
