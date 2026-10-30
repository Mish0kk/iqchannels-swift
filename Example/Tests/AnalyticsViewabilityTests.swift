import XCTest
@testable import IQChannelsSwift

final class AnalyticsViewabilityTests: XCTestCase {

    func testThresholdReachedByTickEmitsReadWithDuration() {
        var clock: Int64 = 10_000
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 1500, now: { clock })
        var reads: [(id: Int, durationMs: Int)] = []
        tracker.onRead = { reads.append(($0, $1)) }

        tracker.show(id: 5)
        clock += 1000
        tracker.tick()
        XCTAssertTrue(reads.isEmpty, "порог ещё не достигнут")

        clock += 600
        tracker.tick()

        XCTAssertEqual(reads.map(\.id), [5])
        XCTAssertEqual(reads[0].durationMs, 1600, "длительность — до момента достижения порога")
    }

    func testHideBeforeThresholdEmitsSkipOnce() {
        var clock: Int64 = 0
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 1500, now: { clock })
        var skips: [(id: Int, reason: IQAnalyticsSkipReason)] = []
        tracker.onSkipped = { skips.append(($0, $1)) }

        tracker.show(id: 5)
        clock += 700
        tracker.hide(id: 5, reason: .scrolledPast)
        tracker.hide(id: 5, reason: .leftChannel)

        XCTAssertEqual(skits(skills: skips).count, 1)
        XCTAssertEqual(skips[0].reason, .scrolledPast)
    }

    func testReViewAfterSkipCanStillRead() {
        var clock: Int64 = 0
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 1000, now: { clock })
        var reads: [Int] = []
        var skips: [Int] = []
        tracker.onRead = { id, _ in reads.append(id) }
        tracker.onSkipped = { id, _ in skips.append(id) }

        tracker.show(id: 5)
        clock += 100
        tracker.hide(id: 5, reason: .scrolledPast)

        tracker.show(id: 5)
        clock += 1200
        tracker.tick()

        XCTAssertEqual(skips, [5])
        XCTAssertEqual(reads, [5], "повторный просмотр пропущенного предложения даёт прочтение")
    }

    func testReadAndSkipAreMutuallyExclusive() {
        var clock: Int64 = 0
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 500, now: { clock })
        var reads: [Int] = []
        var skips: [Int] = []
        tracker.onRead = { id, _ in reads.append(id) }
        tracker.onSkipped = { id, _ in skips.append(id) }

        tracker.show(id: 5)
        clock += 600
        tracker.tick()
        tracker.hide(id: 5, reason: .leftChannel)
        tracker.show(id: 5)
        tracker.hide(id: 5, reason: .scrolledPast)

        XCTAssertEqual(reads, [5])
        XCTAssertTrue(skips.isEmpty, "после прочтения пропуск не отправляется")
    }

    func testFlushSkipsVisibleWithReasonAndIgnoresNeverShown() {
        var clock: Int64 = 0
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 5000, now: { clock })
        var skips: [(id: Int, reason: IQAnalyticsSkipReason)] = []
        tracker.onSkipped = { skips.append(($0, $1)) }

        tracker.show(id: 1)
        tracker.show(id: 2)
        clock += 100
        tracker.flush(reason: .appBackground)

        XCTAssertEqual(Set(skips.map(\.id)), [1, 2])
        XCTAssertTrue(skips.allSatisfy { $0.reason == .appBackground })
    }

    func testRepeatedShowDoesNotResetTimer() {
        var clock: Int64 = 0
        let tracker = IQAnalyticsViewabilityTracker(thresholdMs: 1000, now: { clock })
        var reads: [(id: Int, durationMs: Int)] = []
        tracker.onRead = { reads.append(($0, $1)) }

        tracker.show(id: 5)
        clock += 800
        tracker.show(id: 5)
        clock += 300
        tracker.tick()

        XCTAssertEqual(reads.map(\.durationMs), [1100], "таймер не сбрасывается повторным show")
    }

    private func skits(skills: [(id: Int, reason: IQAnalyticsSkipReason)]) -> [Int] {
        skills.map(\.id)
    }
}
