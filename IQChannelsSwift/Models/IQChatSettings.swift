//
//  IQChatSettings.swift
//  Pods
//
//  Created by Mikhail Zinkov on 09.12.2024.
//

struct IQChatSettings: Codable, Equatable {
    var id: Int = 0
    var message: String = "Здравствуйте!"
    var enabled: Bool = true
    var greetFrom: String? = "user"
    var lifetime: Int = 300
    var pseudonym: String? = "Оператор"
    var operatorName: String? = "Оператор"
    var avatarID: String? = ""
    var totalOpenedTickets: Int = 0
    var chatTitle: String = "Чат с оператором"
    var chatSubtitle: String? = nil
    var translations: [IQTranslations]? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, message, enabled, greetFrom, lifetime, pseudonym, totalOpenedTickets, chatTitle, translations, avatarID, operatorName
        case chatSubtitle = "chat_subtitle"
    }
}

struct IQTranslations: Codable, Equatable {
    var id: Int = 0
    var languageCode: String = "ru"
    var projectID: Int = 0
    var translation: String = "Здравствуйте!"
}
