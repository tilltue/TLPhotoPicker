//
//  TLPhotopickerDataSourcesProtocol.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 21/01/2019.
//

import Foundation
import Photos

public protocol TLPhotopickerDataSourcesProtocol {
    func headerReferenceSize(in section: Int) -> CGSize
    func footerReferenceSize(in section: Int) -> CGSize
    func registerSupplementView(collectionView: UICollectionView)
    func supplementIdentifier(kind: String) -> String
    func configure(supplement view: UICollectionReusableView, in section: Int, info: (title: String, assets: [TLPHAsset])?)
}
