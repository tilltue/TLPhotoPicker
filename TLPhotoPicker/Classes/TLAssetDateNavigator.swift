//
//  TLAssetDateNavigator.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2026. 11. 8..
//  Copyright © 2026년 wade.hawk. All rights reserved.
//

import Foundation
import Photos

/// Finds positions in a creation-date sorted asset list without enumerating it.
///
/// Every lookup is a binary search over `dateAt`, so it stays O(log n) even for
/// libraries with tens of thousands of assets. `PHFetchResult.object(at:)` is lazy,
/// which makes this cheap enough to run on every pan gesture update.
struct TLAssetDateNavigator {
    let count: Int
    /// `true` when older assets come first.
    let ascending: Bool
    let calendar: Calendar
    let dateAt: (Int) -> Date?

    init(count: Int, ascending: Bool, calendar: Calendar = .current, dateAt: @escaping (Int) -> Date?) {
        self.count = count
        self.ascending = ascending
        self.calendar = calendar
        self.dateAt = dateAt
    }

    /// Assets without a creation date are treated as the oldest ones.
    func date(at index: Int) -> Date {
        return dateAt(index) ?? .distantPast
    }

    /// The index where assets of `interval` begin in display order.
    ///
    /// When no asset falls into the interval, the nearest older asset is returned
    /// for descending lists and the nearest newer one for ascending lists,
    /// clamped to the last index. Returns `nil` for an empty list.
    func firstIndex(of interval: DateInterval) -> Int? {
        guard count > 0 else { return nil }
        let index: Int
        if ascending {
            index = partitionPoint { self.date(at: $0) >= interval.start }
        } else {
            index = partitionPoint { self.date(at: $0) < interval.end }
        }
        return min(index, count - 1)
    }

    func firstIndex(ofDayContaining date: Date) -> Int? {
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return nil }
        return firstIndex(of: interval)
    }

    func firstIndex(ofMonthContaining date: Date) -> Int? {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
        return firstIndex(of: interval)
    }

    /// The first index of the month block that follows the one containing `index`, in display order.
    func nextMonthStart(after index: Int) -> Int? {
        guard count > 0, index >= 0, index < count,
              let month = calendar.dateInterval(of: .month, for: date(at: index)) else { return nil }
        let next: Int
        if ascending {
            next = partitionPoint { self.date(at: $0) >= month.end }
        } else {
            next = partitionPoint { self.date(at: $0) < month.start }
        }
        return next < count ? next : nil
    }

    /// The first index of the month block that precedes the one containing `index`, in display order.
    func previousMonthStart(before index: Int) -> Int? {
        guard let current = firstIndex(ofMonthContaining: date(at: index)), current > 0 else { return nil }
        return firstIndex(ofMonthContaining: date(at: current - 1))
    }

    /// The number of calendar months spanned by the list.
    func monthSpan() -> Int {
        guard let dated = datedRange() else { return 0 }
        let first = date(at: dated.lowerBound)
        let last = date(at: dated.upperBound)
        guard
              let start = calendar.dateInterval(of: .month, for: min(first, last))?.start,
              let end = calendar.dateInterval(of: .month, for: max(first, last))?.start else { return 0 }
        let months = calendar.dateComponents([.month], from: start, to: end).month ?? 0
        return months + 1
    }

    /// The index range of assets that have a creation date. Undated assets sit at the old end of the list.
    func datedRange() -> ClosedRange<Int>? {
        guard count > 0 else { return nil }
        if ascending {
            let first = partitionPoint { self.date(at: $0) != .distantPast }
            return first < count ? first...(count - 1) : nil
        }
        let end = partitionPoint { self.date(at: $0) == .distantPast }
        return end > 0 ? 0...(end - 1) : nil
    }

    /// The first asset index of every year present in the list, in display order.
    func yearStarts() -> [(year: Int, index: Int)] {
        guard count > 0 else { return [] }
        var result = [(year: Int, index: Int)]()
        var index = 0
        while index < count {
            let date = self.date(at: index)
            guard date != .distantPast, let interval = calendar.dateInterval(of: .year, for: date) else { break }
            result.append((calendar.component(.year, from: date), index))
            // Jump past the current year: the next year starts where its interval ends.
            let next: Int
            if ascending {
                next = partitionPoint { self.date(at: $0) >= interval.end }
            } else {
                next = partitionPoint { self.date(at: $0) < interval.start }
            }
            guard next > index else { break }
            index = next
        }
        return result
    }

    /// The first index for which `predicate` is true, assuming the list is partitioned
    /// so that all `false` results come before all `true` results.
    private func partitionPoint(_ predicate: (Int) -> Bool) -> Int {
        var low = 0
        var high = count
        while low < high {
            let mid = (low + high) / 2
            if predicate(mid) {
                high = mid
            } else {
                low = mid + 1
            }
        }
        return low
    }
}

extension TLAssetDateNavigator {
    /// Returns a navigator only when the fetch result is sorted by creation date,
    /// because the binary search is meaningless for any other order.
    init?(fetchResult: PHFetchResult<PHAsset>?, sortDescriptors: [NSSortDescriptor]?, calendar: Calendar = .current) {
        guard
            let fetchResult = fetchResult,
            let first = sortDescriptors?.first,
            first.key == "creationDate"
        else { return nil }
        self.init(count: fetchResult.count, ascending: first.ascending, calendar: calendar) { index in
            guard index >= 0, index < fetchResult.count else { return nil }
            return fetchResult.object(at: index).creationDate
        }
    }
}
