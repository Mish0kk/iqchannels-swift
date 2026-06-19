//
//  IQChatDetailViewModel.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 08.05.2024.
//

import Foundation
import Combine

class IQChatDetailViewModel: IQBaseViewModel {
    
    // MARK: - PROPERTIES
    @Published var idOfNewMessage: Int?
    @available(*, deprecated, message: "Replace then delete")
    @Published var hidesBackButton = false
    @Published var backDismisses = false
    @Published var messages: [IQMessage] = []
    @Published var inputText: String = ""
    @Published var client: IQClient?
    @Published var session: IQClientSession?
    @Published var typingUser: IQUser?
    @Published var isLoading = false
    @Published var scrollDotHidden = true
    @Published var messageControlShown: Bool = false
    @Published var messageControlInfo: MessageControlInfo? = nil
    @Published var isMessageCopied: Bool = false
    @Published var messageToReply: IQMessage? = nil
    @Published var selectedFiles: [DataFile]? = nil
    @Published var scrollDown: Bool = false
    @Published var chatLabel: String = ""
    @Published var availableLanguages: [IQLanguage]?
    @Published var selectedLanguage: IQLanguage?
    @Published var showBottomTypingBar: Bool = false
    @Published var enableAnimMessages: Bool = true
    @Published var isAnonim: Bool = false
    @Published var greetingSettings: IQGreetingSettings?
    
    
    // MARK: - METHODS
    func showMessageControl(_ controlInfo: MessageControlInfo) {
        messageControlInfo = controlInfo
        messageControlInfo?.currentSnapshot = DefaultSnapshotCreator().makeSnapshot()
        messageControlShown = true
    }
    
    func getMessage(with messageId: Int?) -> IQMessage? {
        guard let messageId else { return nil }
        return messages.first(where: { $0.messageID == messageId })
    }
}
