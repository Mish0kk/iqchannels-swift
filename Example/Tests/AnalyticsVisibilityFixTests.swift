import XCTest
@testable import IQChannelsSwift

final class AnalyticsVisibilityGateTests: XCTestCase {

    func testUpdateShowsNewlyVisibleAndHidesGone() {
        var gate = IQAnalyticsVisibilityGate()

        let first = gate.update(currentlyVisible: [1, 2])
        XCTAssertEqual(Set(first.shown), [1, 2])
        XCTAssertTrue(first.hidden.isEmpty)
        XCTAssertEqual(gate.visibleIDs, [1, 2])

        let second = gate.update(currentlyVisible: [2, 3])
        XCTAssertEqual(Set(second.shown), [3])
        XCTAssertEqual(Set(second.hidden), [1])
    }

    func testEmptyReportsHideAll() {
        var gate = IQAnalyticsVisibilityGate()
        _ = gate.update(currentlyVisible: [1, 2])

        let update = gate.update(currentlyVisible: [])

        XCTAssertEqual(Set(update.hidden), [1, 2])
        XCTAssertTrue(gate.visibleIDs.isEmpty)
    }

    func testResetReShowsStillVisibleOffers() {
        var gate = IQAnalyticsVisibilityGate()
        _ = gate.update(currentlyVisible: [1, 2])

        gate.reset()
        XCTAssertTrue(gate.visibleIDs.isEmpty, "после сброса (фон/возврат) состояние видимости чистое")

        let reupdate = gate.update(currentlyVisible: [1, 2])
        XCTAssertEqual(Set(reupdate.shown), [1, 2], "повторно видимые предложения снова репортятся показом")
    }

    func testUnchangedVisibleSetReportsNothing() {
        var gate = IQAnalyticsVisibilityGate()
        _ = gate.update(currentlyVisible: [1])

        let update = gate.update(currentlyVisible: [1])

        XCTAssertTrue(update.shown.isEmpty)
        XCTAssertTrue(update.hidden.isEmpty)
    }
}

@MainActor
final class AnalyticsOfferTrackerLifecycleTests: XCTestCase {

    func testSameContextTwiceDoesNotRecreateTracker() {
        let lifecycle = IQAnalyticsOfferTrackerLifecycle()
        let context = (channel: "a", thresholdMs: 1500)

        let first = lifecycle.refresh(context: context)
        let second = lifecycle.refresh(context: context)

        guard case .recreated(let trackerA) = first else {
            return XCTFail("первый refresh должен создать трекер")
        }
        guard case .unchanged(let trackerB) = second else {
            return XCTFail("повторный refresh с тем же каналом не должен пересоздавать")
        }
        XCTAssertTrue(trackerA === trackerB)
    }

    func testChannelChangeRecreatesTrackerWithNewThreshold() {
        let lifecycle = IQAnalyticsOfferTrackerLifecycle()

        guard case .recreated = lifecycle.refresh(context: (channel: "a", thresholdMs: 1500)) else {
            return XCTFail("ожидается создание")
        }

        guard case .recreated(let newTracker) = lifecycle.refresh(context: (channel: "b", thresholdMs: 700)) else {
            return XCTFail("смена канала должна пересоздать трекер")
        }
        XCTAssertEqual(lifecycle.channel, "b")
        XCTAssertEqual(newTracker.thresholdMs, 700)
    }

    func testNilContextKeepsCurrentState() {
        let lifecycle = IQAnalyticsOfferTrackerLifecycle()

        let initial = lifecycle.refresh(context: (channel: "a", thresholdMs: 1500))
        guard case .recreated = initial else { return XCTFail("ожидается создание") }

        let afterNil = lifecycle.refresh(context: nil)

        if case .recreated = afterNil {
            return XCTFail("nil-контекст (нет канала/конфига) не должен пересоздавать трекер")
        }
        XCTAssertEqual(lifecycle.channel, "a")
    }
}
