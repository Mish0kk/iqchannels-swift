//
//  IQRelationManager.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 09.05.2024.
//

import Foundation

class IQRelationManager {
    
    let address: String
    
    init(address: String) {
        self.address = address
    }
    
    func map(_ map: inout IQRelationMap) {
        chats(&map.chats, with: map)
        files(&map.files, with: map)
        users(&map.users, with: map)
        var messages = map.chatMessages.map { $0.value }
        chatMessages(&messages, with: map)
        messages.forEach {
            map.chatMessages.updateValue($0, forKey: $0.messageID)
        }
    }
    
    func mapFromRelations(_ relations: IQRelations?) -> IQRelationMap {
        var map = IQRelationMap(relations: relations)
        self.map(&map)
        return map
    }
    
    func chats(_ chatsToMap: inout [Int: IQChat], with map: IQRelationMap) {
        for (key, chatToMap) in chatsToMap {
            chatsToMap[key]?.client = map.clients[chatToMap.clientID]
            chatsToMap[key]?.channel = map.channels[chatToMap.channelID]
        }
    }
    
    func chatMessages(_ messages: inout [IQMessage], with map: IQRelationMap?) {
        for (key, message) in messages.enumerated() {
            if let userId = message.userID { messages[key].user = map?.users[userId] }
            if let fileId = message.fileID { messages[key].file = map?.files[fileId] }
            if let clientId = message.clientID { messages[key].client = map?.clients[clientId] }
            if let ratingId = message.ratingID {
                messages[key].rating = map?.ratings[ratingId]
            }
        }
    }
    
    func chatEvents(_ events: inout [IQChatEvent], with map: IQRelationMap?) {
        for (index, event) in events.enumerated() {
            if let clientId = event.clientID { events[index].client = map?.clients[clientId] }
            if let userId = event.userID { events[index].user = map?.users[userId] }
            if let chatId = event.chatID { events[index].chat = map?.chats[chatId] }
            if let messageId = event.messageID { events[index].message = map?.chatMessages[messageId] }
            events[index].message?.eventID = event.id
        }
    }
    
    func files(_ files: inout [String: IQFile], with map: IQRelationMap) {
        for (key, _) in files {
            self.file(&files[key]!, with: map)
        }
    }
    
    func file(_ file: inout IQFile, with map: IQRelationMap?) {
        if let fileId = file.id {
            file.url = fileUrl(fileId)
            file.imagePreviewUrl = fileImageUrl(fileId, size: .preview)
        }
    }
    
    func fileUrl(_ fileId: String?) -> URL? {
        guard let fileId else { return nil }
        
        var cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedAddress.hasPrefix("/") {
            cleanedAddress = String(cleanedAddress.dropFirst())
        }
        if cleanedAddress.hasSuffix("/") {
            cleanedAddress = String(cleanedAddress.dropLast())
        }
        let urlString = "\(cleanedAddress)/public/api/v1/files/get/\(fileId)"
        return URL(string: urlString)
    }
    
    func fileImageUrl(_ fileId: String, size: IQFileImageSize) -> URL? {
        var cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedAddress.hasPrefix("/") {
            cleanedAddress = String(cleanedAddress.dropFirst())
        }
        if cleanedAddress.hasSuffix("/") {
            cleanedAddress = String(cleanedAddress.dropLast())
        }
        let urlString = "\(cleanedAddress)/public/api/v1/files/image/\(fileId)?size=\(size.rawValue)"
        return URL(string: urlString)
    }
    
    func users(_ users: inout [Int: IQUser], with map: IQRelationMap) {
        for (key, user) in users {
            if let avatarId = user.avatarID {
                users[key]?.avatarURL = fileImageUrl(avatarId, size: .avatar)
            }
        }
    }
    
}
