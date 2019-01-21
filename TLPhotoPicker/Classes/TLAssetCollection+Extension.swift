//
//  TLAssetCollection+Extension.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 21/01/2019.
//

import Foundation
import Photos

public enum PHFetchedResultGroupedBy {
    case hour
    case day
    case week
    case month
    case year
}

extension TLAssetsCollection {
    func section(groupedBy: PHFetchedResultGroupedBy) {
        self.fetchResult?.enumerateObjects({ (phAsset, idx, stop) in
            print("test \(idx) ")
            sleep(1)
        })
    }
}
