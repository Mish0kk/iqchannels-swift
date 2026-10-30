//
//  IQAnalyticsIdentity.swift
//  IQChannelsSwift
//

import Foundation

enum IQAnalyticsIdentity {

    static let sessionID: String = UUID().uuidString.lowercased()

    private static let deviceIDKey = "iqchannels_analytics_device_id"

    static func deviceID() -> String {
        if let stored = UserDefaults.standard.string(forKey: deviceIDKey) {
            return stored
        }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: deviceIDKey)
        return id
    }
}
