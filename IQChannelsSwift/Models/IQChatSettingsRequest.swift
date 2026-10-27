//
//  IQChatSettingsRequest.swift
//  Pods
//
//  Created by Mikhail Zinkov on 09.12.2024.
//

struct IQChatSettingsRequest: Encodable {
    var clientId: Int?
    var chatType: IQChatType?
}
