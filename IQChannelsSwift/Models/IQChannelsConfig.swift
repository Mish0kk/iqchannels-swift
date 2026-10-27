//
//  IQChannelsConfig.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 08.05.2024.
//

import Foundation

public struct IQChannelsConfig {
    
    public typealias ChatToOpen = (channel: String, chatType: IQChatType)
    
    var address: String
    var channels: [String]
    var chatToOpen: ChatToOpen?
    var styleJson: Data?
    var languageJson: Data?
    var disableUnreadBadge: Bool = false
    var logging: Bool = false
    var attachment: IQAttachment? = nil
    var preFillMessages: IQPreFillMessages? = nil
    var showBottomTypingBar: Bool = false
    var useRussianTrustedRootCA: Bool = false
    var urlSession: URLSession?
    var source: String? = nil

    public init(address: String,
                channels: [String],
                chatToOpen: ChatToOpen? = nil,
                styleJson: Data? = nil,
                languageJson: Data? = nil,
                attachment: IQAttachment? = nil,
                disableUnreadBadge: Bool = false,
                logging: Bool = false,
                preFillMessages: IQPreFillMessages? = nil,
                showBottomTypingBar: Bool = false,
                useRussianTrustedRootCA: Bool = false,
                urlSession: URLSession? = nil,
                source: String? = nil) {
        self.address = address
        self.channels = channels
        self.chatToOpen = chatToOpen
        self.styleJson = styleJson
        self.languageJson = languageJson
        self.attachment = attachment
        self.disableUnreadBadge = disableUnreadBadge
        self.logging = logging
        self.preFillMessages = preFillMessages
        self.showBottomTypingBar = showBottomTypingBar
        self.useRussianTrustedRootCA = useRussianTrustedRootCA
        self.urlSession = urlSession
        self.source = source
    }

}
