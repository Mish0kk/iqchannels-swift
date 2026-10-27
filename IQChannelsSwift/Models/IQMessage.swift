//
//  IQMessage.swift
//  Pods
//
//  Created by Muhammed Aralbek on 12.05.2024.
//  
//

import Foundation

struct IQMessage: Codable, Identifiable, Equatable {
    
    //MARK: - Server side
    var messageID: Int = 0
    var localID: Int?
    var fileID: String?
    var fileIDs: [String]?
    var chatID: Int?
    var createdAt: Int?
    var userID: Int?
    var clientID: Int?
    var ratingID: Int?
    var payload: IQMessagePayloadType?
    var text: String?
    var author: IQAuthorType?
    var isRead: Bool?
    var replyToMessageID: Int?
    var botpressPayload: String?
    var isDropDown: Bool?
    var disableFreeText: Bool?
    var isSystem: Bool = false
    var isReply: Bool = true
    var isAutoGreet: Bool = false
    var actions: [IQAction]?
    var singleChoices: [IQSingleChoice]?
    var product: IQProduct?
    var transferToChannel: IQTransferToChannel?
    
    enum CodingKeys: String, CodingKey {
        case messageID = "id"
        case isRead = "read"
        case payload, text, userID, clientID, fileID, fileIDs, chatID, createdAt, localID, isDropDown, singleChoices, product, actions, replyToMessageID, botpressPayload, disableFreeText, ratingID, author, transferToChannel
    }

    //MARK: - Custom
    /// ID for UI, dont use
    var id: String = UUID().uuidString
    var chatType: IQChatType?
    var eventID: Int?
    var upload: String?
    var error: Bool = false
    var newMsgHeader: Bool = false

    //MARK: - Relations
    var client: IQClient?
    var user: IQUser?
    var file: IQFile?
    var files: [IQFile]?
    var rating: IQRating?

    //MARK: - Computed
    var createdDate: Date {
        if let createdAt {
            return Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000)
        }
        
        return Date()
    }
    
    var isSent: Bool {
        messageID != 0
    }
    
    /// For File messages see IQFile.isLoading
    var isLoading: Bool {
        !isSent && !(isRead ?? false)
    }
    
    var isPendingRatingMessage: Bool {
        return rating?.state == .pending || rating?.state == .poll
    }
    
    var isMessageReplied: Bool {
        return replyToMessageID != nil
    }
    
    var hasValidPayload: Bool {
        payload != nil && payload != .invalid && file?.type != .invalid
    }
    
    var senderName: String {
        switch author {
        case .anonymous:
            return IQLanguageTexts.model.senderNameAnonym ?? "Аноним"
        case .client:
            return client?.name ?? ""
        case .user:
            return user?.displayName ?? ""
        case .system:
            return IQLanguageTexts.model.senderNameSystem ?? "Система"
        case nil:
            return ""
        }
    }
    
    var isMy: Bool? {
        switch author {
        case .client:
            return true
        case .user:
            return false
        default:
            return nil
        }
    }
    
    var messageText: String {
        if let file {
            switch file.type {
            case .file: return file.name ?? ""
            case .image: return "Image"
            default: return ""
            }
        }
        
        if let rating {
            
            var toValue: Int?
            if let questions = rating.ratingPoll?.questions {
                toValue = questions
                    .filter { $0.asTicketRating == true }
                    .compactMap { $0.scale?.toValue }
                    .first
            }
        
            switch rating.state {
            case .pending: return IQLanguageTexts.model.ratingStatePending ?? "Пожалуйста, оцените качество консультации"
            case .ignored: return IQLanguageTexts.model.ratingStateIgnored ?? "Без оценки оператора"
//            case .rated, .finished: return "\(IQLanguageTexts.model.ratingStateRated ?? "Оценка оператора") \(rating.value ?? 0)/\(toValue ?? 5)"
            case .rated, .finished:
                let value = rating.value ?? 0
                let maxValue = toValue ?? 5
                let template = IQLanguageTexts.model.ratingStateRated ?? "Оценка оператора {{client_rating}} из {{max_rating}}"
                
                let text = template
                    .replacingOccurrences(of: "{{client_rating}}", with: "\(value)")
                    .replacingOccurrences(of: "{{max_rating}}", with: "\(maxValue)")
                
                return text
            default: return ""
            }
        }
        
        if payload == nil || payload == .invalid {
            return IQLanguageTexts.model.invalidMesssage ?? "Неподдерживаемый тип сообщения"
        }
        
        return text ?? ""
    }
    
    //MARK: - INIT
    init(text: String, localID: Int, clientID: Int?) {
        self.text = text
        self.isRead = true
        self.localID = localID
        self.clientID = clientID
        self.payload = .text
        self.author = .client
        self.isReply = false
        self.createdAt = Int(Date().timeIntervalSince1970 * 1000)
    }
    init(text: String, chatType: IQChatType, clientID: Int?, localID: Int, replyMessageID: Int?) {
        self.init(localID: localID, clientID: clientID, chatType: chatType, replyMessageID: replyMessageID)
        self.text = text
        self.isRead = false
        self.payload = .text
    }
    
    init(dataFile: DataFile, chatType: IQChatType, clientID: Int?, localID: Int, text: String?, replyMessageID: Int?) {
        self.init(localID: localID, clientID: clientID, chatType: chatType, replyMessageID: replyMessageID)
        self.payload = .file
        self.text = text
        self.isRead = false
        self.file = IQFile(dataFile: dataFile)
    }
    
    init(action: IQAction, chatType: IQChatType, clientID: Int?, localID: Int) {
        self.init(localID: localID, clientID: clientID, chatType: chatType, replyMessageID: nil)
        self.payload = .text
        self.isRead = false
        self.text = action.title
        self.botpressPayload = action.payload
    }
    
    init(choice: IQSingleChoice, chatType: IQChatType, clientID: Int?, localID: Int) {
        self.init(localID: localID, clientID: clientID, chatType: chatType, replyMessageID: nil)
        self.payload = .text
        self.isRead = false
        self.text = choice.title
        self.botpressPayload = choice.value
    }
    
    init(text: String, operatorName: String, avatarID: String?, avatarURL: URL?, isAutoGreet: Bool = false) {
        self.author = .user
        self.createdAt = Int(Date().timeIntervalSince1970 * 1000)
        self.localID = -1
        self.text = text
        self.isRead = true
        self.isReply = false
        self.payload = .text
        self.isAutoGreet = isAutoGreet
        self.user = IQUser(id: 0, displayName: operatorName, avatarID: avatarID, avatarURL: avatarURL)
    }
    
    init(newMsgHeader: Bool) {
        self.author = .system
        self.createdAt = Int(Date().timeIntervalSince1970 * 1000)
        self.localID = 0
        self.payload = .text
        self.isRead = true
        self.newMsgHeader = true
        self.isSystem = true
    }
    
    private init(localID: Int, clientID: Int?, chatType: IQChatType, replyMessageID: Int?) {
        self.author = .client
        self.isRead = true
        self.clientID = clientID
        self.replyToMessageID = replyMessageID
        self.createdAt = Int(Date().timeIntervalSince1970 * 1000)
        self.localID = localID
        self.chatType = chatType
    }
    
    //MARK: - Methods
    
    mutating func merged(with message: IQMessage) -> IQMessage {
        var copy = self
        // Ids
        copy.messageID = message.messageID
        copy.eventID = message.eventID

        // Payload
        copy.payload = message.payload
        copy.text = message.text
        copy.fileID = message.fileID
        copy.replyToMessageID = message.replyToMessageID
        copy.botpressPayload = message.botpressPayload
        copy.author = message.author

        // Relations
        copy.user = message.user
        copy.client = message.client
        copy.file = message.file
        copy.files = message.files
        copy.rating = message.rating
        return copy
    }

}


extension IQMessage {
    func withError(_ error: Bool) -> IQMessage {
        var copy = self
        copy.error = error
        return copy
    }
    
    func withRead(_ isRead: Bool) -> IQMessage {
        var copy = self
        copy.isRead = isRead
        return copy
    }
}
