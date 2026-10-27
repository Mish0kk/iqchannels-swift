import XCTest
@testable import IQChannelsSwift

final class AnalyticsScreenEventsTests: XCTestCase {

    func testTrackChannelEnterOnceSendsSingleEventUntilReset() async {
        let manager = IQAnalyticsManager(isOnline: { true })
        let transport = MockTransport(script: [.success, .success, .success])
        manager.activate(
            results: [Self.result(channel: "a")],
            source: nil,
            transports: ["a": transport]
        )

        await manager.trackChannelEnterOnce(
            channel: "a",
            payload: IQAnalyticsEvent.channelEnterPayload(name: "Канал", type: .chat, channelID: 1, unreadInChannel: 2)
        )
        await manager.trackChannelEnterOnce(
            channel: "a",
            payload: IQAnalyticsEvent.channelEnterPayload(name: "Канал", type: .chat, channelID: 1, unreadInChannel: 2)
        )

        XCTAssertEqual(transport.sent.filter { $0.event == .channelEnter }.count, 1, "одноканальный режим — один вход за сессию")

        manager.reset()
        manager.activate(results: [Self.result(channel: "a")], source: nil, transports: ["a": transport])

        await manager.trackChannelEnterOnce(
            channel: "a",
            payload: IQAnalyticsEvent.channelEnterPayload(name: "Канал", type: .chat, channelID: 1, unreadInChannel: 2)
        )

        XCTAssertEqual(
            transport.sent.filter { $0.event == .channelEnter }.count, 2,
            "новая логин-сессия снова фиксирует вход"
        )
    }

    func testScreenViewPayloadSumsChannelsAndUnread() {
        let items = [
            Self.item(channel: "a", type: .chat),
            Self.item(channel: "a", type: .manager),
            Self.item(channel: "b", type: .info)
        ]
        let unread = [
            Self.channel(name: "a", type: "regular", unread: 2),
            Self.channel(name: "a", type: "personal_manager", unread: 3),
            Self.channel(name: "b", type: "info", unread: 5),
            Self.channel(name: "c", type: "regular", unread: 100)
        ]

        let payload = IQChannelsManager.analyticsScreenViewPayload(items: items, unread: unread)

        XCTAssertEqual(payload["screen"], .string("chat_list"))
        XCTAssertEqual(payload["channel_count"], .int(3))
        XCTAssertEqual(payload["unread_total"], .int(10), "непрочитанные суммируются только по каналам списка")
    }

    func testChannelEnterPayloadFallsBackToChannelNameAndMatchesUnread() {
        let itemNoName = Self.item(channel: "finance", type: .chat)
        let unread = [Self.channel(name: "finance", type: "regular", unread: 4)]

        let payload = IQChannelsManager.analyticsChannelEnterPayload(item: itemNoName, channelID: 42, unread: unread)

        XCTAssertEqual(payload["channel_name"], .string("finance"), "без channelName используется имя канала")
        XCTAssertEqual(payload["channel_type"], .string("regular"))
        XCTAssertEqual(payload["channel_id"], .int(42))
        XCTAssertEqual(payload["unread_in_channel"], .int(4))
    }

    func testChannelEnterPayloadWithoutUnreadEntryIsZero() {
        let item = Self.item(channel: "a", type: .chat)

        let payload = IQChannelsManager.analyticsChannelEnterPayload(item: item, channelID: nil, unread: [])

        XCTAssertEqual(payload["unread_in_channel"], .int(0))
        XCTAssertNil(payload["channel_id"])
    }

    // MARK: - Helpers

    private static func result(channel: String) -> (channel: String, auth: IQClientAuth) {
        let analytics = try! IQJSONDecoder().decode(
            IQAnalyticsConfig.self,
            from: #"{"enabled":true,"events":["channel_enter"]}"#.data(using: .utf8)!
        )
        let client = IQClient(id: 1, name: nil, integrationID: nil, personalManagerID: nil,
                              personalManagerGroupID: nil, multiChatsInfo: nil,
                              projectID: 1, crmClientID: "101", channelID: nil)
        return (channel, IQClientAuth(client: client, session: nil, analytics: analytics))
    }

    private static func item(channel: String, type: IQChatType) -> IQChatItemModel {
        IQChatItemModel(channel: channel, info: IQMultiChatsInfo(channelName: channel == "finance" ? nil : "\(channel)-name"), chatType: type)
    }

    private static func channel(name: String, type: String, unread: Int) -> Channel {
        Channel(name: name, chatType: type, lastMessage: nil, unreadCount: unread)
    }
}
