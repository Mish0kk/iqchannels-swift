//
//  IQAnalyticsEvent.swift
//  IQChannelsSwift
//

import Foundation

enum IQAnalyticsJSONValue: Encodable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }
}

enum IQAnalyticsSkipReason: String {
    case scrolledPast = "scrolled_past"
    case leftChannel = "left_channel"
    case appBackground = "app_background"
}

enum IQAnalyticsLink {

    static func trackingID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        for item in queryItems where item.name == "iq_ref" {
            guard let value = item.value, !value.isEmpty else { return nil }
            return value
        }
        return nil
    }
}

struct IQAnalyticsEvent: Encodable {
    var event: IQAnalyticsEventType
    var eventID: String
    var sessionID: String
    var clientIntegrationID: String
    var projectID: Int
    var deviceID: String
    var platform: String
    var appVersion: String
    var timestamp: String
    var clientTZ: String?
    var source: String?
    var payload: [String: IQAnalyticsJSONValue]?

    enum CodingKeys: String, CodingKey {
        case event
        case eventID = "event_id"
        case sessionID = "session_id"
        case clientIntegrationID = "client_integration_id"
        case projectID = "project_id"
        case deviceID = "device_id"
        case platform
        case appVersion = "app_version"
        case timestamp
        case clientTZ = "client_tz"
        case source
        case payload
    }

    static func make(
        type: IQAnalyticsEventType,
        channelAuth: IQClientAuth,
        source: String?,
        payload: [String: IQAnalyticsJSONValue]?
    ) -> IQAnalyticsEvent {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return IQAnalyticsEvent(
            event: type,
            eventID: UUID().uuidString.lowercased(),
            sessionID: IQAnalyticsIdentity.sessionID,
            clientIntegrationID: channelAuth.client?.crmClientID ?? "",
            projectID: channelAuth.client?.projectID ?? 0,
            deviceID: IQAnalyticsIdentity.deviceID(),
            platform: "ios",
            appVersion: IQChannelsVersion.current,
            timestamp: formatter.string(from: Date()),
            clientTZ: TimeZone.current.identifier,
            source: source,
            payload: payload
        )
    }

    static func screenViewPayload(channelCount: Int, unreadTotal: Int) -> [String: IQAnalyticsJSONValue] {
        [
            "screen": .string("chat_list"),
            "channel_count": .int(channelCount),
            "unread_total": .int(unreadTotal)
        ]
    }

    static func channelEnterPayload(
        name: String?,
        type: IQChatType,
        channelID: Int?,
        unreadInChannel: Int
    ) -> [String: IQAnalyticsJSONValue] {
        var payload: [String: IQAnalyticsJSONValue] = [
            "channel_type": .string(type.rawValue),
            "unread_in_channel": .int(unreadInChannel)
        ]
        if let name, !name.isEmpty {
            payload["channel_name"] = .string(name)
        }
        if let channelID {
            payload["channel_id"] = .int(channelID)
        }
        return payload
    }

    static func offerReadPayload(
        messageID: Int?,
        channelID: Int?,
        visibleDurationMs: Int
    ) -> [String: IQAnalyticsJSONValue] {
        var payload: [String: IQAnalyticsJSONValue] = [
            "visible_duration_ms": .int(visibleDurationMs)
        ]
        if let messageID {
            payload["message_id"] = .int(messageID)
        }
        if let channelID {
            payload["channel_id"] = .int(channelID)
        }
        return payload
    }

    static func offerSkippedPayload(
        messageID: Int?,
        channelID: Int?,
        reason: IQAnalyticsSkipReason
    ) -> [String: IQAnalyticsJSONValue] {
        var payload: [String: IQAnalyticsJSONValue] = [
            "skip_reason": .string(reason.rawValue)
        ]
        if let messageID {
            payload["message_id"] = .int(messageID)
        }
        if let channelID {
            payload["channel_id"] = .int(channelID)
        }
        return payload
    }

    static func linkClickPayload(
        trackingID: String,
        messageID: Int?,
        channelID: Int?
    ) -> [String: IQAnalyticsJSONValue] {
        var payload: [String: IQAnalyticsJSONValue] = [
            "tracking_id": .string(trackingID)
        ]
        if let messageID {
            payload["message_id"] = .int(messageID)
        }
        if let channelID {
            payload["channel_id"] = .int(channelID)
        }
        return payload
    }
}
