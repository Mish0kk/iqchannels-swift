//
//  IQChannelsManager+Output.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 08.05.2024.
//

import Foundation
import PhotosUI

extension IQChannelsManager: IQChannelsManagerListOutput {
    func listControllerDismissChat() {
        guard eventListener?.iqChannelsShouldCloseModule() ?? true else { return }
        listViewModel?.dismissListener.send(())
//        logout()
    }
    
    func listControllerDidAppear() {
        trackScreenView()
    }
    
    func listController(didSelectChat item: IQChatItemModel) {
        guard let authResult = authResults.first(where: { $0.channel == item.channel } ) else { return }
        
        selectedChat = (authResult, item.chatType)
        trackChannelEnter(chat: (authResult, item.chatType), once: false)
    }
}

extension IQChannelsManager: IQChannelsManagerDetailOutput {
    
    func detailController(didSend text: String, files: [DataFile]?, replyToMessage: Int?) {
        sendMessage(text, files: files, replyToMessage: replyToMessage)
    }
    
    func detailController(didResend message: IQMessage) {
        resendMessage(message)
    }
    
    func detailController(didPick items: [(URL?, UIImage?)]) {
        sendFiles(items: items)
    }
    
    func detailControllerDismissChat() {
        guard eventListener?.iqChannelsShouldCloseModule() ?? true else { return }
        
        detailViewModel?.dismissListener.send(())
    }

    func detailControllerDidPop() {
        guard eventListener?.iqChannelsShouldCloseChat() ?? true else { return }
        IQLog.debug(message: "detailControllerDidPop")
        closeCurrentChat()
    }
    
    func detailController(didPick results: [PHPickerResult]) {
        sendImages(result: results)
    }
    
    func detailController(didCancelUpload message: IQMessage) {
        cancelUploadFileMessage(message)
    }
    
    func detailController(didCancelSend message: IQMessage) {
        cancelSendMessage(message)
    }

    func detailController(didDisplayMessageWith id: Int) {
        messageDisplayed(id)
    }
    
    func detailController(didCopyMessage message: IQMessage) {
        UIPasteboard.general.string = message.text
    }
    
    func detailController(didSelect file: IQFile) {
        openFileInBrowser(file)
    }
    
    func detailController(didRate value: Int, ratingID: Int) {
        rate(value: value, ratingID: ratingID)
    }
    
    func detailController(didSendPoll value: Int?, answers: [IQRatingPollClientAnswerInput], ratingID: Int, pollId: Int) {
        sendPoll(value: value, answers: answers, ratingID: ratingID, pollId: pollId)
    }
    
    func detailController(didPollIgnored ratingID: Int, pollId: Int) {
        pollIgnored(ratingID: ratingID, pollId: pollId)
    }
    
    func detailController(didSelect choice: IQSingleChoice) {
        send(choice)
    }
    
    func detailController(didSelect productTap: IQProductTap) {
        acceptOrDeclineProduct(productTap)
    }
    
    func detailController(didSelect action: IQAction) {
        send(action)
    }

    func detailControllerIsTyping() {
        sendTypingEvent()
    }
    
    func detailControllerSelectLanguage(didSelect language: IQLanguage) {
        setLanguage(language)
    }
    
    func detailController(didChangeSegment message: IQMessage) {
        changeSegment(message)
    }

    func detailControllerOfferTrackingContext() async -> (channel: String, thresholdMs: Int)? {
        guard let channel = selectedChat?.auth.channel else { return nil }
        return await analytics.offerTrackingContext(channel: channel)
    }

    func detailController(didReadOffer message: IQMessage, channel: String, visibleDurationMs: Int) {
        let payload = IQAnalyticsEvent.offerReadPayload(
            messageID: message.messageID,
            channelID: message.channelID ?? message.chatID,
            visibleDurationMs: visibleDurationMs
        )
        Task {
            await analytics.track(channel: channel, type: .offerRead, payload: payload)
        }
    }

    func detailController(didSkipOffer message: IQMessage, channel: String, reason: IQAnalyticsSkipReason) {
        let payload = IQAnalyticsEvent.offerSkippedPayload(
            messageID: message.messageID,
            channelID: message.channelID ?? message.chatID,
            reason: reason
        )
        Task {
            await analytics.track(channel: channel, type: .offerSkipped, payload: payload)
        }
    }

    func detailController(didTapLink url: URL, in message: IQMessage?) {
        openLink(url, message: message)
    }
}
