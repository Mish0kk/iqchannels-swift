//
//  IQDatabaseMessage.swift
//  Pods
//
//  Created by Mikhail Zinkov on 27.12.2024.
//

import Foundation
import SQLite

struct IQDatabaseMessage {
    let uid: Int
    let messageID: Int
    let localID: Int?
    let fileID: String?
    let chatID: Int?
    let createdAt: Int?
    let userID: Int?
    let clientID: Int?
    let ratingID: Int?
    let payload: String?
    let text: String?
    let author: String?
    let isRead: Bool?
    let replyToMessageID: Int?
    let botpressPayload: String?
    let isDropDown: Bool?
    let disableFreeText: Bool?
    let isSystem: Bool?
    let actions: String?
    let singleChoices: String?
    let chatType: String?
    let channel: String?
    let eventID: Int?
    let client: String?
    let user: String?
    let file: String?
    let rating: String?
    let upload: String?
    let error: Bool
    let transferToChannel: String?
}








extension IQMessage {
    func toDatabaseMessage() -> IQDatabaseMessage {
        return IQDatabaseMessage(
            uid: 0,
            messageID: self.messageID,
            localID: self.localID,
            fileID: self.fileID,
            chatID: self.chatID,
            createdAt: self.createdAt,
            userID: self.userID,
            clientID: self.clientID,
            ratingID: self.ratingID,
            payload: self.payload?.rawValue,
            text: self.text,
            author: self.author?.toJSONString(),
            isRead: self.isRead,
            replyToMessageID: self.replyToMessageID,
            botpressPayload: self.botpressPayload,
            isDropDown: self.isDropDown,
            disableFreeText: self.disableFreeText,
            isSystem: self.isSystem,
            actions: self.actions?.toJSONString(),
            singleChoices: self.singleChoices?.toJSONString(),
            chatType: self.chatType?.rawValue,
            channel: self.channel,
            eventID: self.eventID,
            client: self.client?.toJSONString(),
            user: self.user?.toJSONString(),
            file: self.file?.toJSONString(),
            rating: self.rating?.toJSONString(),
            upload: self.upload,
            error: self.error,
            transferToChannel: self.transferToChannel?.toJSONString(),
        )
    }
}

extension Encodable {
    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}










extension IQMessage {
    init(from databaseMessage: IQDatabaseMessage) {
        self.messageID = databaseMessage.messageID
        self.localID = databaseMessage.localID ?? 0
        self.fileID = databaseMessage.fileID
        self.chatID = databaseMessage.chatID
        self.createdAt = databaseMessage.createdAt
        self.userID = databaseMessage.userID
        self.clientID = databaseMessage.clientID
        self.ratingID = databaseMessage.ratingID
        self.payload = IQMessagePayloadType(rawValue: databaseMessage.payload ?? "")
        self.text = databaseMessage.text ?? ""
        self.author = IQAuthorType.fromJSONString(databaseMessage.author)
        self.isRead = databaseMessage.isRead
        self.replyToMessageID = databaseMessage.replyToMessageID
        self.botpressPayload = databaseMessage.botpressPayload
        self.isDropDown = databaseMessage.isDropDown
        self.disableFreeText = databaseMessage.disableFreeText
        self.isSystem = databaseMessage.isSystem ?? false
        self.actions = [IQAction].fromJSONString(databaseMessage.actions)
        self.singleChoices = [IQSingleChoice].fromJSONString(databaseMessage.singleChoices)
        self.chatType = IQChatType(rawValue: databaseMessage.chatType ?? "") ?? IQChatType.chat
        self.channel = databaseMessage.channel
        self.eventID = databaseMessage.eventID
        self.client = IQClient.fromJSONString(databaseMessage.client)
        self.user = IQUser.fromJSONString(databaseMessage.user)
        self.file = IQFile.fromJSONString(databaseMessage.file)
        self.rating = IQRating.fromJSONString(databaseMessage.rating)
        self.upload = databaseMessage.upload
        self.error = databaseMessage.error
    }
}
extension Decodable {
    static func fromJSONString(_ json: String?) -> Self? {
        guard let json = json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
