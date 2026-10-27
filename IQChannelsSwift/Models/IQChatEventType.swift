//
//  IQChatEventType.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 14.05.2024.
//

import Foundation

enum IQChatEventType: String, Decodable {
    case invalid = ""
    case chatCreated = "chat_created"
    case chatOpened = "chat_opened"
    case chatClosed = "chat_closed"
    case closeSystemChat = "close-system-chat"
    case fileStatusUpdated = "file_updated"
    case typing
    case messageCreated = "message_created"
    case systemMessageCreated = "system_message_created"
    case messageReceived = "message_received"
    case messageRead = "message_read"
    case deleteMessages = "delete-messages"
    case ratingIgnored = "rating_ignored"
    case chatSubtitleChanged = "chat_subtitle_changed"
    
    init(from decoder: any Decoder) throws {
        self = try IQChatEventType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .invalid
    }
}
