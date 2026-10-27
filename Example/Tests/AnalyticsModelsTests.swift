import XCTest
@testable import IQChannelsSwift

final class AnalyticsModelsTests: XCTestCase {

    func testClientAuthDecodesAnalyticsBlockAndClientIdentity() throws {
        let json = """
        {"Client":{"Id":1,"ProjectId":307,"CRMClientId":"101","ChannelId":42},"Session":{"Id":9,"Token":"t"},"analytics":{"enabled":true,"events":["screen_view","link_click"],"viewability_threshold_ms":800}}
        """.data(using: .utf8)!

        let auth = try IQJSONDecoder().decode(IQClientAuth.self, from: json)

        XCTAssertEqual(auth.client?.id, 1)
        XCTAssertEqual(auth.client?.projectID, 307)
        XCTAssertEqual(auth.client?.crmClientID, "101")
        XCTAssertEqual(auth.client?.channelID, 42)
        XCTAssertEqual(auth.analytics?.allows(.screenView), true)
        XCTAssertEqual(auth.analytics?.allows(.linkClick), true)
        XCTAssertEqual(auth.analytics?.allows(.offerRead), false)
        XCTAssertEqual(auth.analytics?.thresholdMs, 800)
    }

    func testAnalyticsBlockAbsentMeansNil() throws {
        let json = """
        {"Client":{"Id":1,"ProjectId":307},"Session":{"Id":9}}
        """.data(using: .utf8)!

        let auth = try IQJSONDecoder().decode(IQClientAuth.self, from: json)

        XCTAssertNil(auth.analytics)
        XCTAssertNil(auth.client?.crmClientID)
    }

    func testConfigDisabledAllowsNothing() throws {
        let config = try decodeConfig(#"{"enabled":false,"events":["screen_view"]}"#)

        XCTAssertFalse(config.allows(.screenView))
    }

    func testConfigWithoutEventsAllowsNothing() throws {
        let config = try decodeConfig(#"{"enabled":true}"#)

        XCTAssertFalse(config.allows(.screenView))
        XCTAssertFalse(config.allows(.channelEnter))
    }

    func testThresholdDefaultsTo1500() throws {
        XCTAssertEqual(try decodeConfig(#"{"enabled":true}"#).thresholdMs, 1500)
        XCTAssertEqual(try decodeConfig(#"{"enabled":true,"viewability_threshold_ms":0}"#).thresholdMs, 1500)
        XCTAssertEqual(try decodeConfig(#"{"enabled":true,"viewability_threshold_ms":700}"#).thresholdMs, 700)
    }

    func testMessageDecodesMailingMessageId() throws {
        let mailing = try decodeMessage(#"{"Id":5,"MailingMessageId":77,"ChatId":42}"#)
        XCTAssertEqual(mailing.mailingMessageID, 77)
        XCTAssertTrue(mailing.isMailingOffer)

        let regular = try decodeMessage(#"{"Id":6,"ChatId":42}"#)
        XCTAssertNil(regular.mailingMessageID)
        XCTAssertFalse(regular.isMailingOffer)
    }

    private func decodeConfig(_ json: String) throws -> IQAnalyticsConfig {
        return try IQJSONDecoder().decode(IQAnalyticsConfig.self, from: json.data(using: .utf8)!)
    }

    private func decodeMessage(_ json: String) throws -> IQMessage {
        return try IQJSONDecoder().decode(IQMessage.self, from: json.data(using: .utf8)!)
    }
}
