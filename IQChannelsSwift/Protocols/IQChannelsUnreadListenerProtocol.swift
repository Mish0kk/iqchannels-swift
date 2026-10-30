//
//  IQChannelsUnreadListenerProtocol.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 24.05.2024.
//

import Foundation

@MainActor
public protocol IQChannelsUnreadListenerProtocol: AnyObject {
    var id: String { get }
    func iqChannelsUnreadDidChange(_ unread: Int)
}

@MainActor
public protocol IQChannelsAdvancedUnreadListenerProtocol: AnyObject {
    var id: String { get }
    func iqChannelsAdvancedUnreadDidChange(_ unread: IQAdvancedUnread)
    func iqChannelsAdvancedUnreadException(_ e: Error)
}

public protocol IQChannelsLinkListenerProtocol: AnyObject {
    var id: String { get }
    func iqChannelsShouldHandleLink(link: String) -> Bool
}


public struct IQAdvancedUnread: Decodable, Equatable {
    public var channels: [Channel]? = nil
}

public struct Channel: Decodable, Equatable {
    public var name: String? = nil
    public var chatType: String? = nil
    public var lastMessage: LastMessage? = nil
    public var unreadCount: Int? = nil
}

public struct LastMessage: Decodable, Equatable {
    public var text: String? = nil
    public var fileID: String? = nil
    public var isSurvey: Bool? = nil
    public var date: String? = nil
    
    static func parseDate(_ raw: String) -> Date? {
        if let interval = TimeInterval(raw) {
            return interval > 1e12 ? Date(timeIntervalSince1970: interval / 1000) : Date(timeIntervalSince1970: interval)
        }
        
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) { return date }
        
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFractional.date(from: raw) { return date }
        
        let parts = raw.split(separator: " ")
        if parts.count >= 2 {
            var normalized = "\(parts[0]) \(parts[1])"
            var fraction = ""
            if let dotIndex = normalized.firstIndex(of: ".") {
                fraction = String(normalized[dotIndex...])
                while fraction.count < 7 { fraction += "0" }
                fraction = String(fraction.prefix(7))
                normalized = String(normalized[..<dotIndex])
            }
            
            if let zonePart = parts.dropFirst(2).first(where: { $0.hasPrefix("+") || $0.hasPrefix("-") }) {
                if !fraction.isEmpty {
                    let zonedFractional = DateFormatter()
                    zonedFractional.locale = Locale(identifier: "en_US_POSIX")
                    zonedFractional.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS Z"
                    if let date = zonedFractional.date(from: "\(normalized)\(fraction) \(zonePart)") { return date }
                }
                let zoned = DateFormatter()
                zoned.locale = Locale(identifier: "en_US_POSIX")
                zoned.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let date = zoned.date(from: "\(normalized) \(zonePart)") { return date }
            }
            
            if !fraction.isEmpty {
                let utcFractional = DateFormatter()
                utcFractional.locale = Locale(identifier: "en_US_POSIX")
                utcFractional.timeZone = TimeZone(identifier: "UTC")
                utcFractional.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
                if let date = utcFractional.date(from: "\(normalized)\(fraction)") { return date }
            }
            
            let utc = DateFormatter()
            utc.locale = Locale(identifier: "en_US_POSIX")
            utc.timeZone = TimeZone(identifier: "UTC")
            utc.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = utc.date(from: normalized) { return date }
        }
        
        if raw.count >= 19 {
            let prefix = String(raw.prefix(19))
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: prefix)
        }
        return nil
    }
    
    static func normalizedDate(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return raw }
        if isServerDateFormat(raw) { return raw }
        guard let date = parseDate(raw) else { return raw }
        return serverDateString(from: date)
    }
    
    static func isServerDateFormat(_ raw: String) -> Bool {
        let pattern = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d+ [+-]\\d{4} .+$"
        return raw.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func serverDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS Z"
        let base = formatter.string(from: date)
        return base + " " + timeZoneShortName(for: TimeZone.current)
    }
    
    static func timeZoneShortName(for timeZone: TimeZone) -> String {
        let candidates = TimeZone.abbreviationDictionary
            .filter { $0.value == timeZone.identifier }
            .map { $0.key }
        if let standard = candidates.first(where: { !$0.hasSuffix("D") }) {
            return standard
        }
        return candidates.sorted().first
            ?? timeZone.abbreviation()
            ?? timeZone.identifier
    }
    
    var withNormalizedDate: LastMessage {
        var copy = self
        copy.date = LastMessage.normalizedDate(date)
        return copy
    }
}

public struct IQAdvancedUnreadResult: Decodable, Equatable {
    public var id: Int? = nil
    public var type: String? = nil
    public var name: String? = nil
    public var chatType: String? = nil
    public var lastMessage: LastMessage? = nil
    public var unreadCount: Int? = nil
}
