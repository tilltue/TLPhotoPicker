//
//  TLPhotopickerDataSourcesProtocol.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 21/01/2019.
//

import Foundation
import Photos

public protocol TLPhotopickerDataSourcesProtocol {
    func customLayout(layout: UICollectionViewFlowLayout) -> UICollectionViewFlowLayout
    func registerSupplementView(collectionView: UICollectionView)
    func supplementIdentifier(kind: String) -> String
    func configure(supplement view: UICollectionReusableView, collection: PHAssetCollection)
}

public extension TLPhotopickerDataSourcesProtocol {
    open func customLayout(layout: UICollectionViewFlowLayout) -> UICollectionViewFlowLayout {
        return layout
    }
}
