//
//  IQAnalyticsViewabilityTracker.swift
//  IQChannelsSwift
//

import Foundation

struct IQAnalyticsVisibilityGate {

    private(set) var visibleIDs: Set<Int> = []

    mutating func update(currentlyVisible: Set<Int>) -> (shown: [Int], hidden: [Int]) {
        let shown = Array(currentlyVisible.subtracting(visibleIDs))
        let hidden = Array(visibleIDs.subtracting(currentlyVisible))
        visibleIDs = currentlyVisible
        return (shown, hidden)
    }

    mutating func reset() {
        visibleIDs = []
    }
}

@MainActor
final class IQAnalyticsOfferTrackerLifecycle {

    enum RefreshOutcome {
        case none
        case unchanged(IQAnalyticsViewabilityTracker)
        case recreated(IQAnalyticsViewabilityTracker)
    }

    private(set) var tracker: IQAnalyticsViewabilityTracker?
    private(set) var channel: String?

    func refresh(context: (channel: String, thresholdMs: Int)?) -> RefreshOutcome {
        guard let context else { return .none }
        if let tracker, channel == context.channel {
            return .unchanged(tracker)
        }
        let newTracker = IQAnalyticsViewabilityTracker(thresholdMs: context.thresholdMs)
        tracker = newTracker
        channel = context.channel
        return .recreated(newTracker)
    }
}

final class IQAnalyticsViewabilityTracker {

    let thresholdMs: Int
    var onRead: ((Int, Int) -> Void)?
    var onSkipped: ((Int, IQAnalyticsSkipReason) -> Void)?

    private var visibleSince: [Int: Int64] = [:]
    private var read: Set<Int> = []
    private var skipped: Set<Int> = []
    private let now: () -> Int64

    init(
        thresholdMs: Int,
        now: @escaping () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1000) }
    ) {
        self.thresholdMs = thresholdMs
        self.now = now
    }

    func show(id: Int) {
        guard !read.contains(id), visibleSince[id] == nil else { return }
        visibleSince[id] = now()
    }

    func hide(id: Int, reason: IQAnalyticsSkipReason) {
        guard let since = visibleSince[id] else { return }
        visibleSince[id] = nil

        let duration = Int(now() - since)
        if duration >= thresholdMs {
            markRead(id, durationMs: duration)
        } else {
            emitSkipped(id, reason: reason)
        }
    }

    func tick() {
        let current = now()
        for (id, since) in visibleSince {
            let duration = Int(current - since)
            if duration >= thresholdMs {
                visibleSince[id] = nil
                markRead(id, durationMs: duration)
            }
        }
    }

    func flush(reason: IQAnalyticsSkipReason) {
        for id in Array(visibleSince.keys) {
            hide(id: id, reason: reason)
        }
    }

    private func markRead(_ id: Int, durationMs: Int) {
        guard !read.contains(id) else { return }
        read.insert(id)
        onRead?(id, durationMs)
    }

    private func emitSkipped(_ id: Int, reason: IQAnalyticsSkipReason) {
        guard !read.contains(id), !skipped.contains(id) else { return }
        skipped.insert(id)
        onSkipped?(id, reason)
    }
}
