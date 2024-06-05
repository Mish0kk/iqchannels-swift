//
//  IQChatEvent.swift
//  Pods
//
//  Created by Muhammed Aralbek on 13.05.2024.
//
//

import Foundation

struct IQChatEvent: Decodable {
    var id: Int
    var type: IQChatEventType
    var chatID: Int?
    var messageID: Int?
    var actor: IQAuthorType?
    var clientID: Int?
    var userID: Int?
    var messages: [IQMessage]?
    var client: IQClient?
    var user: IQUser?
    var chat: IQChat?
    var message: IQMessage?
}

