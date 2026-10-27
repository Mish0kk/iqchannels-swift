import XCTest
@testable import IQChannelsSwift

final class AnalyticsEventTests: XCTestCase {

    private let lowercaseV4UUID = #"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"#

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "iqchannels_analytics_device_id")
        super.tearDown()
    }

    func testEventEncodingMatchesServerContract() throws {
        let event = IQAnalyticsEvent.make(
            type: .channelEnter,
            channelAuth: Self.auth(crmClientID: "101", projectID: 307),
            source: "push",
            payload: IQAnalyticsEvent.channelEnterPayload(
                name: "Персональный менеджер",
                type: .manager,
                channelID: 42,
                unreadInChannel: 3
            )
        )

        let dict = try JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any] ?? [:]

        XCTAssertEqual(Set(dict.keys), [
            "event", "event_id", "session_id", "client_integration_id", "project_id",
            "device_id", "platform", "app_version", "timestamp", "client_tz", "source", "payload"
        ])
        XCTAssertEqual(dict["event"] as? String, "channel_enter")
        XCTAssertEqual(dict["client_integration_id"] as? String, "101")
        XCTAssertEqual(dict["project_id"] as? Int, 307)
        XCTAssertEqual(dict["platform"] as? String, "ios")
        XCTAssertEqual(dict["app_version"] as? String, IQChannelsVersion.current)
        XCTAssertEqual(dict["source"] as? String, "push")
        XCTAssertTrue((dict["event_id"] as? String ?? "").range(of: lowercaseV4UUID, options: .regularExpression) != nil)
        XCTAssertTrue((dict["session_id"] as? String ?? "").range(of: lowercaseV4UUID, options: .regularExpression) != nil)
        XCTAssertTrue((dict["device_id"] as? String ?? "").range(of: lowercaseV4UUID, options: .regularExpression) != nil)
        XCTAssertTrue((dict["timestamp"] as? String ?? "").range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#, options: .regularExpression) != nil)
        XCTAssertFalse((dict["client_tz"] as? String ?? "").isEmpty)

        let payload = dict["payload"] as? [String: Any]
        XCTAssertEqual(payload?["channel_name"] as? String, "Персональный менеджер")
        XCTAssertEqual(payload?["channel_type"] as? String, "personal_manager")
        XCTAssertEqual(payload?["channel_id"] as? Int, 42)
        XCTAssertEqual(payload?["unread_in_channel"] as? Int, 3)
    }

    func testMakeFallsBackToEmptyIntegrationIDAndZeroProject() throws {
        let event = IQAnalyticsEvent.make(
            type: .screenView,
            channelAuth: IQClientAuth(client: IQClient(), session: nil, analytics: nil),
            source: nil,
            payload: nil
        )

        let dict = try JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any] ?? [:]

        XCTAssertEqual(dict["client_integration_id"] as? String, "")
        XCTAssertEqual(dict["project_id"] as? Int, 0)
        XCTAssertNil(dict["source"])
    }

    func testSessionIDStableAndLowercaseV4() {
        XCTAssertTrue(IQAnalyticsIdentity.sessionID.range(of: lowercaseV4UUID, options: .regularExpression) != nil)
        XCTAssertEqual(IQAnalyticsIdentity.sessionID, IQAnalyticsIdentity.sessionID)
    }

    func testDeviceIDPersistedAcrossCalls() {
        let first = IQAnalyticsIdentity.deviceID()
        XCTAssertTrue(first.range(of: lowercaseV4UUID, options: .regularExpression) != nil)
        XCTAssertEqual(IQAnalyticsIdentity.deviceID(), first)
    }

    func testPayloadBuilders() {
        XCTAssertEqual(IQAnalyticsEvent.screenViewPayload(channelCount: 3, unreadTotal: 7), [
            "screen": .string("chat_list"), "channel_count": .int(3), "unread_total": .int(7)
        ])

        XCTAssertEqual(IQAnalyticsEvent.offerReadPayload(messageID: 5, channelID: 42, visibleDurationMs: 1600), [
            "message_id": .int(5), "channel_id": .int(42), "visible_duration_ms": .int(1600)
        ])

        XCTAssertEqual(IQAnalyticsEvent.offerSkippedPayload(messageID: 5, channelID: 42, reason: .scrolledPast), [
            "message_id": .int(5), "channel_id": .int(42), "skip_reason": .string("scrolled_past")
        ])

        XCTAssertEqual(IQAnalyticsEvent.linkClickPayload(trackingID: "abc", messageID: 5, channelID: 42), [
            "tracking_id": .string("abc"), "message_id": .int(5), "channel_id": .int(42)
        ])

        XCTAssertEqual(IQAnalyticsEvent.channelEnterPayload(name: nil, type: .info, channelID: nil, unreadInChannel: 0), [
            "channel_type": .string("info"), "unread_in_channel": .int(0)
        ])
    }

    func testSkipReasonsMatchContract() {
        XCTAssertEqual(IQAnalyticsSkipReason.scrolledPast.rawValue, "scrolled_past")
        XCTAssertEqual(IQAnalyticsSkipReason.leftChannel.rawValue, "left_channel")
        XCTAssertEqual(IQAnalyticsSkipReason.appBackground.rawValue, "app_background")
    }

    private static func auth(crmClientID: String?, projectID: Int?) -> IQClientAuth {
        let client = IQClient(id: 1, name: nil, integrationID: nil, personalManagerID: nil,
                              personalManagerGroupID: nil, multiChatsInfo: nil,
                              projectID: projectID, crmClientID: crmClientID, channelID: 42)
        return IQClientAuth(client: client, session: nil, analytics: nil)
    }
}
