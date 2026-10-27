import XCTest
@testable import IQChannelsSwift

final class AnalyticsSenderTests: XCTestCase {

    func testForbidden403DisablesSenderUntilReset() async {
        let transport = MockTransport(script: [.failure(.init(statusCode: 403, code: "forbidden"))])
        let sender = Self.makeSender(transport)

        await sender.send(Self.event())

        let disabled = await sender.disabled
        XCTAssertTrue(disabled, "403 + forbidden должен отключить отправку")
        XCTAssertEqual(transport.sent.count, 1)

        await sender.send(Self.event())
        XCTAssertEqual(transport.sent.count, 1, "после отключения события не отправляются")
    }

    func testOther403IsClientErrorAndDropped() async {
        let transport = MockTransport(script: [.failure(.init(statusCode: 403, code: "unauthorized"))])
        let sender = Self.makeSender(transport)

        await sender.send(Self.event())

        let disabled = await sender.disabled
        XCTAssertFalse(disabled)
        XCTAssertEqual(transport.sent.count, 1, "клиентская ошибка не ретраится")
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 0)
    }

    func test422DroppedWithoutRetry() async {
        let transport = MockTransport(script: [.failure(.init(statusCode: 422, code: "invalid"))])
        let sender = Self.makeSender(transport)

        await sender.send(Self.event())

        XCTAssertEqual(transport.sent.count, 1)
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 0)
    }

    func test5xxRetriedOnceWithSameEventID() async {
        let transport = MockTransport(script: [
            .failure(.init(statusCode: 500, code: nil)),
            .success
        ])
        let sender = Self.makeSender(transport)

        let event = Self.event()
        await sender.send(event)

        XCTAssertEqual(transport.sent.count, 2)
        XCTAssertEqual(transport.sent.map(\.eventID), [event.eventID, event.eventID])
        let disabled = await sender.disabled
        XCTAssertFalse(disabled)
    }

    func test5xxRetryFailureDropsEvent() async {
        let transport = MockTransport(script: [
            .failure(.init(statusCode: 500, code: nil)),
            .failure(.init(statusCode: 503, code: nil))
        ])
        let sender = Self.makeSender(transport)

        await sender.send(Self.event())

        XCTAssertEqual(transport.sent.count, 2, "ровно один повтор")
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 0)
        let disabled = await sender.disabled
        XCTAssertFalse(disabled)
    }

    func testNetworkErrorCachesEventUntilNextSuccess() async {
        let transport = MockTransport(script: [
            .failure(.init(statusCode: nil, code: nil)),
            .success,
            .success
        ])
        let sender = Self.makeSender(transport)

        let cached = Self.event()
        await sender.send(cached)
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 1)

        await sender.send(Self.event())
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 0)

        XCTAssertEqual(transport.sent.count, 3)
        XCTAssertEqual(transport.sent.map(\.eventID).last, cached.eventID, "кэшированное уходит после успеха")
    }

    func testCacheOverflowDropsOldestEvent() async {
        let transport = MockTransport(script: [
            .failure(.init(statusCode: nil, code: nil)),
            .failure(.init(statusCode: nil, code: nil)),
            .failure(.init(statusCode: nil, code: nil)),
            .failure(.init(statusCode: nil, code: nil))
        ])
        let sender = Self.makeSender(transport)

        let oldest = Self.event()
        await sender.send(oldest)
        await sender.send(Self.event())
        await sender.send(Self.event())
        await sender.send(Self.event())

        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 3)
        let cacheIDs = await sender.pendingCacheEventIDs
        XCTAssertFalse(cacheIDs.contains(oldest.eventID), "переполнение отбрасывает старейшее")
    }

    func testDisabledByServerClearsCache() async {
        let transport = MockTransport(script: [
            .failure(.init(statusCode: nil, code: nil)),
            .failure(.init(statusCode: nil, code: nil)),
            .failure(.init(statusCode: 403, code: "forbidden"))
        ])
        let sender = Self.makeSender(transport)

        await sender.send(Self.event())
        await sender.send(Self.event())
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 2)

        await sender.send(Self.event())

        let disabled = await sender.disabled
        XCTAssertTrue(disabled)
        await XCTAssertEqualAsync(await sender.pendingCacheCount(), 0)
    }

    // MARK: - Helpers

    private static func makeSender(_ transport: IQAnalyticsTransport) -> IQAnalyticsSender {
        IQAnalyticsSender(transport: transport, delay: { _ in })
    }

    private static func event() -> IQAnalyticsEvent {
        IQAnalyticsEvent.make(
            type: .screenView,
            channelAuth: IQClientAuth(client: nil, session: nil, analytics: nil),
            source: nil,
            payload: nil
        )
    }

    private func XCTAssertEqualAsync<T: Equatable>(_ expression1: @autoclosure () async -> T, _ expression2: T,
                                                   file: StaticString = #filePath, line: UInt = #line) async {
        let value = await expression1()
        XCTAssertEqual(value, expression2, file: file, line: line)
    }
}

final class MockTransport: IQAnalyticsTransport {

    enum Outcome {
        case success
        case failure(IQAnalyticsSendError)
    }

    private var script: [Outcome]
    private(set) var sent: [IQAnalyticsEvent] = []
    private(set) var delivered: [IQAnalyticsEvent] = []

    init(script: [Outcome]) {
        self.script = script
    }

    func send(_ event: IQAnalyticsEvent) async -> Result<Void, IQAnalyticsSendError> {
        sent.append(event)
        guard !script.isEmpty else {
            return .failure(IQAnalyticsSendError(statusCode: nil, code: nil))
        }
        switch script.removeFirst() {
        case .success:
            delivered.append(event)
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension IQAnalyticsSender {
    func pendingCacheCount() async -> Int {
        pendingCacheEventIDs.count
    }
}

final class AnalyticsSenderConcurrencyTests: XCTestCase {

    func testConcurrentNetworkFailuresCacheAllEventsWithoutCorruption() async {
        let transport = MockTransport(script: [])
        let sender = IQAnalyticsSender(transport: transport, delay: { _ in })

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    await sender.send(Self.event(number: index))
                }
            }
        }

        let cached = await sender.pendingCacheCount()
        XCTAssertEqual(cached, IQAnalyticsSender.maxCachedEvents, "переполнение отбрасывает старейшие, кэш не ломается")
    }

    func testConcurrentFlushesDoNotDuplicateCachedEvents() async {
        let networkFailure = IQAnalyticsSendError(statusCode: nil, code: nil)
        let transport = MockTransport(script: [
            .failure(networkFailure), .failure(networkFailure), .failure(networkFailure),
            .success, .success, .success
        ])
        let sender = IQAnalyticsSender(transport: transport, delay: { _ in })

        await sender.send(Self.event(number: 0))
        await sender.send(Self.event(number: 1))
        await sender.send(Self.event(number: 2))
        let cached = await sender.pendingCacheCount()
        XCTAssertEqual(cached, 3)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await sender.flushCache() }
            group.addTask { await sender.flushCache() }
        }

        XCTAssertEqual(transport.sent.count, 6, "3 начальные попытки + 3 из флеша, без дублей флеша")
        XCTAssertEqual(transport.delivered.count, 3, "все кэшированные доставлены ровно по одному разу")
        let deliveredIDs = transport.delivered.map(\.eventID)
        XCTAssertEqual(Set(deliveredIDs).count, 3)
        let remaining = await sender.pendingCacheCount()
        XCTAssertEqual(remaining, 0)
    }

    private static func event(number: Int) -> IQAnalyticsEvent {
        IQAnalyticsEvent.make(
            type: .screenView,
            channelAuth: IQClientAuth(client: IQClient(id: number, name: nil, integrationID: nil,
                                                       personalManagerID: nil, personalManagerGroupID: nil,
                                                       multiChatsInfo: nil, projectID: 1, crmClientID: "101",
                                                       channelID: nil),
                                      session: nil, analytics: nil),
            source: nil,
            payload: nil
        )
    }
}
