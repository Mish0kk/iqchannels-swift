//
//  IQAnalyticsConfig.swift
//  IQChannelsSwift
//

import Foundation

enum IQAnalyticsEventType: String, Encodable {
    case screenView = "screen_view"
    case channelEnter = "channel_enter"
    case sourceAttribution = "source_attribution"
    case offerRead = "offer_read"
    case offerSkipped = "offer_skipped"
    case linkClick = "link_click"
}

struct IQAnalyticsConfig: Decodable {
    var enabled: Bool?
    var events: [String]?
    var viewabilityThresholdMs: Int?

    enum CodingKeys: String, CodingKey {
        case enabled
        case events
        case viewabilityThresholdMs = "viewability_threshold_ms"
    }

    static let defaultThresholdMs = 1500

    func allows(_ type: IQAnalyticsEventType) -> Bool {
        (enabled ?? false) && (events ?? []).contains(type.rawValue)
    }

    var thresholdMs: Int {
        let value = viewabilityThresholdMs ?? 0
        return value > 0 ? value : Self.defaultThresholdMs
    }
}
