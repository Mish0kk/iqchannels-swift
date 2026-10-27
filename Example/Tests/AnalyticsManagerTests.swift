import XCTest
@testable import IQChannelsSwift

final class AnalyticsManagerTests: XCTestCase {

    func testNoAnalyticsBlockSendsNothing() async {
        let manager = Self.makeManager()
        let transportA = MockTransport(script: [])
        manager.activate(
            results: [Self.result(channel: "a", config: nil)],
            source: nil,
            transports: ["a": transportA]
        )

        await manager.track(channel: "a", type: .screenView, payload: nil)

        XCTAssertTrue(transportA.sent.isEmpty, "без блока analytics события не отправляются")
    }

    func testDisabledConfigSendsNothing() async {
        let manager = Self.makeManager()
        let transport = MockTransport(script: [])
        manager.activate(
            results: [Self.result(channel: "a", config: #"{"enabled":false,"events":["screen_view"]}"#)],
            source: nil,
            transports: ["a": transport]
        )

        await manager.track(channel: "a", type: .screenView, payload: nil)

        XCTAssertTrue(transport.sent.isEmpty)
    }

    func testTrackRoutesToOwningChannelOnly() async {
        let manager = Self.makeManager()
        let transportA = MockTransport(script: [.success])
        let transportB = MockTransport(script: [.success])
        manager.activate(
            results: [
                Self.result(channel: "a", config: #"{"enabled":true,"events":["screen_view"]}"#),
                Self.result(channel: "b", config: #"{"enabled":true,"events":["screen_view"]}"#)
            ],
            source: nil,
            transports: ["a": transportA, "b": transportB]
        )

        await manager.track(channel: "a", type: .screenView, payload: nil)

        XCTAssertEqual(transportA.sent.count, 1)
        XCTAssertTrue(transportB.sent.isEmpty)
    }

    func testTrackGatedWhenOffline() async {
        let manager = Self.makeManager(online: false)
        let transport = MockTransport(script: [])
        manager.activate(
            results: [Self.result(channel: "a", config: #"{"enabled":true,"events":["screen_view"]}"#)],
            source: nil,
            transports: ["a": transport]
        )

        await manager.track(channel: "a", type: .screenView, payload: nil)

        XCTAssertTrue(transport.sent.isEmpty, "офлайн — события не генерируются")
    }

    func testForbiddenOnOneChannelDoesNotDisableOther() async {
        let manager = Self.makeManager()
        let transportA = MockTransport(script: [
            .failure(.init(statusCode: 403, code: "forbidden")),
            .failure(.init(statusCode: 403, code: "forbidden"))
        ])
        let transportB = MockTransport(script: [.success, .success])
        manager.activate(
            results: [
                Self.result(channel: "a", projectID: 1, config: Self.fullConfig),
                Self.result(channel: "b", projectID: 2, config: Self.fullConfig)
            ],
            source: nil,
            transports: ["a": transportA, "b": transportB]
        )

        await manager.track(channel: "a", type: .screenView, payload: nil)
        await manager.track(channel: "b", type: .screenView, payload: nil)

        XCTAssertEqual(transportA.sent.count, 1)
        XCTAssertEqual(transportB.sent.count, 1, "403 канала a не отключает канал b")
    }

    func testSourceAttributionSentOncePerActivationPerProject() async {
        let manager = Self.makeManager()
        let transportA = MockTransport(script: [.success, .success, .success])
        let transportB = MockTransport(script: [.success, .success, .success])
        let results = [
            Self.result(channel: "a", projectID: 7, config: Self.fullConfig),
            Self.result(channel: "b", projectID: 7, config: Self.fullConfig)
        ]

        func attributionTotal() -> Int {
            (transportA.sent + transportB.sent).filter { $0.event == .sourceAttribution }.count
        }

        manager.activate(results: results, source: "push", transports: ["a": transportA, "b": transportB])

        let firstSent = await waitUntil { attributionTotal() == 1 }
        XCTAssertTrue(firstSent, "source_attribution уходит один раз на проект")

        manager.activate(results: results, source: "push", transports: ["a": transportA, "b": transportB])

        let secondSent = await waitUntil { attributionTotal() == 2 }
        XCTAssertTrue(
            secondSent,
            "новая активация (новая логин-сессия) шлёт source_attribution снова, тоже один раз на проект"
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    func testSourceAttributionSkippedWithoutSource() async {
        let manager = Self.makeManager()
        let transport = MockTransport(script: [.success])
        manager.activate(
            results: [Self.result(channel: "a", config: Self.fullConfig)],
            source: nil,
            transports: ["a": transport]
        )

        XCTAssertTrue(transport.sent.filter { $0.event == .sourceAttribution }.isEmpty)
    }

    func testResetReactivatesDisabledChannel() async {
        let manager = Self.makeManager()
        let disabledTransport = MockTransport(script: [.failure(.init(statusCode: 403, code: "forbidden"))])
        let freshTransport = MockTransport(script: [.success])

        manager.activate(
            results: [Self.result(channel: "a", config: Self.fullConfig)],
            source: nil,
            transports: ["a": disabledTransport]
        )
        await manager.track(channel: "a", type: .screenView, payload: nil)
        XCTAssertFalse(manager.allows(channel: "a", type: .screenView), "403 отключил канал до конца сессии")

        manager.reset()
        manager.activate(
            results: [Self.result(channel: "a", config: Self.fullConfig)],
            source: nil,
            transports: ["a": freshTransport]
        )
        await manager.track(channel: "a", type: .screenView, payload: nil)

        XCTAssertEqual(freshTransport.sent.count, 1, "после reset и новой активации канал снова шлёт")
    }

    // MARK: - Helpers

    private static let fullConfig =
        #"{"enabled":true,"events":["screen_view","channel_enter","source_attribution""#
        + #","offer_read","offer_skipped","link_click"],"viewability_threshold_ms":1500}"#

    private static func makeManager(online: Bool = true) -> IQAnalyticsManager {
        IQAnalyticsManager(isOnline: { online })
    }

    private static func result(
        channel: String, projectID: Int = 1, config: String?
    ) -> (channel: String, auth: IQClientAuth) {
        let data = config.flatMap { Data($0.utf8) }
        let analytics = data.flatMap { try? IQJSONDecoder().decode(IQAnalyticsConfig.self, from: $0) }
        let client = IQClient(
            id: 1, name: nil, integrationID: nil, personalManagerID: nil,
            personalManagerGroupID: nil, multiChatsInfo: nil,
            projectID: projectID, crmClientID: "101", channelID: 42
        )
        return (channel, IQClientAuth(client: client, session: nil, analytics: analytics))
    }
}
