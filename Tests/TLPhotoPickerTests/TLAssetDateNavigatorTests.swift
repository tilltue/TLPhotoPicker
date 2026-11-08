import XCTest
@testable import TLPhotoPicker

final class TLAssetDateNavigatorTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Newest first, like the picker's default fetch order.
    private func descending(_ dates: [Date?]) -> TLAssetDateNavigator {
        return TLAssetDateNavigator(count: dates.count, ascending: false, calendar: calendar) { dates[$0] }
    }

    private func ascending(_ dates: [Date?]) -> TLAssetDateNavigator {
        return TLAssetDateNavigator(count: dates.count, ascending: true, calendar: calendar) { dates[$0] }
    }

    private lazy var library: [Date?] = [
        date(2026, 11, 8, 20), date(2026, 11, 8, 9),   // 0, 1
        date(2026, 11, 5),                             // 2
        date(2026, 10, 31, 23), date(2026, 10, 1, 0),  // 3, 4
        date(2025, 12, 25),                            // 5
        date(2024, 3, 1),                              // 6
        nil                                            // 7
    ]

    func testDayLookupReturnsFirstAssetOfThatDay() {
        let navigator = descending(library)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 11, 8, 1)), 0)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 11, 5)), 2)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 10, 1, 15)), 4)
    }

    func testDayWithoutAssetsFallsBackToNearestOlderAsset() {
        let navigator = descending(library)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 11, 7)), 2)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2027, 1, 1)), 0)
        // Older than everything clamps to the last index.
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2000, 1, 1)), 7)
    }

    func testDayBoundaryUsesCalendarTimeZone() {
        let navigator = descending(library)
        // 2026-10-31 23:00 KST belongs to Oct 31, not Nov 1.
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 10, 31, 1)), 3)
    }

    func testAscendingOrder() {
        let navigator = ascending(Array(library.reversed()))
        // reversed: nil, 2024-03-01, 2025-12-25, 10-01, 10-31, 11-05, 11-08 09, 11-08 20
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 11, 8)), 6)
        // No asset on Nov 7: ascending lists fall forward to the next newer asset.
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2026, 11, 7)), 6)
        XCTAssertEqual(navigator.firstIndex(ofMonthContaining: date(2026, 10, 15)), 3)
        XCTAssertEqual(navigator.firstIndex(ofDayContaining: date(2030, 1, 1)), 7)
    }

    func testMonthLookup() {
        let navigator = descending(library)
        XCTAssertEqual(navigator.firstIndex(ofMonthContaining: date(2026, 10, 15)), 3)
        XCTAssertEqual(navigator.firstIndex(ofMonthContaining: date(2025, 6, 1)), 6)
    }

    func testMonthSteppingInDisplayOrder() {
        let navigator = descending(library)
        XCTAssertEqual(navigator.nextMonthStart(after: 1), 3)   // Nov -> Oct
        XCTAssertEqual(navigator.nextMonthStart(after: 4), 5)   // Oct -> 2025-12
        XCTAssertEqual(navigator.previousMonthStart(before: 4), 0)
        XCTAssertNil(navigator.previousMonthStart(before: 1))
        XCTAssertEqual(navigator.nextMonthStart(after: 6), 7)   // to the undated asset
        XCTAssertNil(navigator.nextMonthStart(after: 7))
    }

    func testYearStarts() {
        let years = descending(library).yearStarts()
        XCTAssertEqual(years.map { $0.year }, [2026, 2025, 2024])
        XCTAssertEqual(years.map { $0.index }, [0, 5, 6])
        let ascendingYears = ascending(Array(library.reversed()).filter { $0 != nil }).yearStarts()
        XCTAssertEqual(ascendingYears.map { $0.year }, [2024, 2025, 2026])
        XCTAssertEqual(ascendingYears.map { $0.index }, [0, 1, 2])
    }

    func testMonthSpanCountsCalendarMonths() {
        XCTAssertEqual(descending([date(2026, 4, 1), date(2026, 3, 31)]).monthSpan(), 2)
        XCTAssertEqual(descending([date(2026, 11, 8), date(2025, 11, 8)]).monthSpan(), 13)
        XCTAssertEqual(descending([]).monthSpan(), 0)
    }

    func testMonthSpanIgnoresUndatedAssets() {
        // The default library has undated assets at the old end; they must not disable snapping.
        XCTAssertEqual(descending(library).monthSpan(), 33)
        XCTAssertEqual(ascending(Array(library.reversed())).monthSpan(), 33)
        XCTAssertEqual(descending([nil, nil]).monthSpan(), 0)
    }

    func testEmptyList() {
        let navigator = descending([])
        XCTAssertNil(navigator.firstIndex(ofDayContaining: Date()))
        XCTAssertTrue(navigator.yearStarts().isEmpty)
    }

    func testLargeLibraryUsesLogarithmicLookups() {
        let count = 100_000
        let newest = date(2026, 11, 8)
        var lookups = 0
        let navigator = TLAssetDateNavigator(count: count, ascending: false, calendar: calendar) { index in
            lookups += 1
            return newest.addingTimeInterval(-Double(index) * 3600)
        }
        _ = navigator.firstIndex(ofDayContaining: date(2020, 1, 1))
        XCTAssertLessThan(lookups, 40)
    }
}
