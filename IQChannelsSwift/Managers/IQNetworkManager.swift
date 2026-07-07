//
//  IQNetworkManagers.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 09.05.2024.
//

import Foundation

//var unreadListeners: [IQEventSourceManager] = []

class IQNetworkManager: NSObject, IQNetworkManagerProtocol {
        
    var token: String?
    
    let address: String
    let channel: String
    var customHeaders: [String: String]?
    
    let relationManager: IQRelationManager
    var eventsListener: IQEventSourceManager?
    var advancedUnreadListener: IQEventSourceManager?
    var unreadCount: Int?
    
    lazy var session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    
    init(address: String, channel: String) {
        self.address = address
        self.channel = channel
        self.relationManager = .init(address: address)
    }
    
    func setCustomHeaders(_ headers: [String: String]) {
        self.customHeaders = headers
    }
    
    func cancelTask(with taskIdentifier: Int) {
        Task {
            await session.allTasks.first(where: { $0.taskIdentifier == taskIdentifier } )?.cancel()
        }
    }
    
    func isConnectedToEvents() -> Bool {
        (eventsListener?.eventSource?.isOpen() ?? false)
    }
    
    static func getFileConfig(address: String) async throws -> IQFileConfig {
        let networkManager = IQNetworkManager(address: address, channel: "")
        let path = "/files/config"
        let result = await networkManager.get(path, responseType: IQFileConfig.self)
        if let value = result.result?.value {
            IQLog.debug(message: "getFileConfig: \(value)")
            return value
        }
        let error = result.error ?? NSError.clientError()
        IQLog.error(message: "getFileConfig: \(error)")
        throw error
    }
    
    func listenToEvents(request: IQListenEventsRequest, onOpen: @escaping (() -> Void), callback: @escaping ResponseCallbackClosure<[IQChatEvent]>) {
        var path = "/sse/chats/channel/events/\(channel)"
        path += "?ChatType=\(request.chatType.rawValue)"
        if let lastEventId = request.lastEventID {
            path += "&LastEventId=\(lastEventId)"
        }
        eventsListener = sse(path: path, responseType: [IQChatEvent].self, onOpen: onOpen) { result, error in
            if let error = error {
                callback(nil, error)
                IQLog.error(message: "listenToEvents: \(error)")
                return
            }
            guard let result else {
                callback([], nil)
                return
            }
            
            var events = result.value ?? []
            
            IQLog.debug(message: "listenToEvents: \(events)")
            
            self.relationManager.chatEvents(&events, with: result.relations)
            callback(events, nil)
        }
    }
    
    func listenToAdvancedUnread(callback: @escaping ResponseCallbackClosure<IQAdvancedUnreadResult>) {
        var path = "/sse/chats/channel/unread/multichat"
        
        advancedUnreadListener = sse(path: path, responseType: IQAdvancedUnreadResult.self, onOpen: {}) { result, error in
            if let error = error {
                callback(nil, error)
                IQLog.error(message: "listenToAdvancedUnread: \(error)")
                return
            }
            guard let result else {
                callback(nil, nil)
                return
            }
            
            var events = result.value
            
            IQLog.debug(message: "listenToAdvancedUnread: \(events)")
            
            callback(events, nil)
        }
    }
    
//    func listenToUnread(callback: @escaping ResponseCallbackClosure<Int>) {
//        let path = "/sse/chats/channel/unread/\(channel)"
//        
//        unreadListeners.forEach { $0.close() }
//        unreadListeners.removeAll()
//        
//        unreadListener = sse(path: path, responseType: Int.self, onOpen: {} ){ result, error in
//            if let error = error {
//                callback(nil, error)
//                IQLog.error(message: "listenToUnread: \(error)")
//                return
//            }
//            if result == nil {
//                callback(nil, nil)
//                return
//            }
//            self.unreadCount = result?.value ?? 0
//            IQLog.debug(message: "listenToUnread: \(String(describing: self.unreadCount))")
//            
//            callback(result?.value ?? 0, nil)
//        }
//        
//        if let unreadListener = unreadListener {
//            unreadListeners.append(unreadListener)
//        }
//    }
    
    func stopListenToEvents(){
        eventsListener?.close()
        eventsListener = nil
    }
    
    func stopListenToAdvancedUnread(){
        advancedUnreadListener?.close()
        advancedUnreadListener = nil
    }
    
//    func stopListenToUnread(){
//        unreadListener?.close()
//        unreadListener = nil
//    }
    
    func pushToken(token: String) async -> Error? {
        let path = "/push/channel/apns/\(channel)"
        let params = ["Token": token]
        let response = await post(path, body: params, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendPushToken: \n token: \(token) \n response: \(response)")
        
        return response.error
    }
    
    func sendReceivedEvent(_ messageIDs: [Int]) async -> Error? {
        let path = "/chats/messages/received"
        let response = await post(path, body: messageIDs, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendReceivedEvent: \n messageIDs: \(messageIDs) \n response: \(response)")
        
        return response.error
    }
    
    func sendReadEvent(_ messageIDs: [Int]) async -> Error? {
        let path = "/chats/messages/read"
        let response = await post(path, body: messageIDs, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendReadEvent: \n messageIDs: \(messageIDs) \n response: \(response)")
        
        return response.error
    }
    
    func sendTypingEvent() async -> Error? {
        let path = "/chats/channel/typing/\(channel)"
        let response = await post(path, body: nil, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendTypingEvent: \(response)")
        
        return response.error
    }
    
    func getFile(id: String) async throws -> IQFile? {
        let path = "/files/get_file/\(id)"
        let response = await get(path, responseType: IQFile.self)
        if let error = response.error {
            IQLog.error(message: "getFile: \(error)")
            throw error
        }
        
        IQLog.debug(message: "getFile: success")
        
        return response.result?.value
    }
    
    func openSystemChat() async -> Error? {
        let path = "/chats/channel/system_chats/send/\(channel)"
        let response = await post(path, body: nil, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "openSystemChat: \(response)")
        
        return response.error
    }
    
    func getAvailableLanguages() async -> ResponseCallback<[IQLanguage]> {
        let path = "/widget/localization/\(channel)/languages"
        
        let response = await get(path, responseType: IQLanguageResponse.self)
        
        guard response.error == nil else {
            IQLog.error(message: "getAvailableLanguages: \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let result = response.result, let value = result.value?.languages else { return .init(error: NSError.failedToParseModel(IQLanguageResponse.self)) }
        
        IQLog.debug(message: "getAvailableLanguages: \n success")
        
        return .init(result: value)
    }
    
    func getSignupGreetingSettings() async -> ResponseCallback<IQGreetingSettings> {
        let path = "/widget/greetings/\(channel)"
        let response = await post(path, body: nil, responseType: IQGreetingSettings.self)
        print("!!!!!!!!!!!!!   greetingSettings  response      \(response)")
        
        guard response.error == nil else {
            IQLog.error(message: "getSignupGreetingSettings: \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let result = response.result, let value = result.value else { return .init(error: NSError.failedToParseModel(IQGreetingSettings.self)) }
        
        IQLog.debug(message: "getSignupGreetingSettings: \n success")
        
        print("!!!!!!!!!!!!!   greetingSettings  value      \(value)")
        
        return .init(result: value)
    }
    
    func getChatSettings(request: IQChatSettingsRequest) async -> ResponseCallback<IQChatSettings> {
        let path = "/chats/channel/chat/get_settings/\(channel)"
        let response = await post(path, body: request, responseType: IQChatSettings.self)
        
        guard response.error == nil else {
            IQLog.error(message: "getChatSettings: \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let result = response.result, let value = result.value else { return .init(error: NSError.failedToParseModel(IQChatSettings.self)) }
        
        IQLog.debug(message: "getChatSettings: \n success")
        
        return .init(result: value)
    }
    
    func loadMessages(request: IQLoadMessageRequest, getSettings: Bool, isInfoChat: Bool) async -> ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?)> {
        let path = "/chats/channel/messages/\(channel)"
        let response = await post(path, body: request, responseType: [IQMessage].self)
        
        guard response.error == nil else {
            IQLog.error(message: "loadMessages: \n request: \(request) \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let result = response.result, var value = result.value else { return .init(error: NSError.failedToParseModel([IQMessage].self)) }
        
        var lifeTime: Int?
        var chatTitle: String = "Чат с оператором"
        var systemChat: Bool = false
        var availableLanguages: [IQLanguage]?
        
        let availableLanguagesResponse = await getAvailableLanguages()
        
        if let availableLanguagesResult = availableLanguagesResponse.result{
            availableLanguages = availableLanguagesResult
        }
        
        if(getSettings){
            let chatSettings = await getChatSettings(request: .init(clientId: request.clientId))
            
            if let settings = chatSettings.result{
                chatTitle = settings.chatTitle
                systemChat = settings.enabled == true
                
                if (settings.greetFrom == "bot") {
                    let response = await openSystemChat()
                    if (response != nil) {
                        IQLog.error(message: "openSystemChat: error: \(String(describing: response))")
                        systemChat = false
                    }
                } else{
                    var avatarURL: URL? = nil
                    
                    if let avatarId = settings.avatarID, !avatarId.isEmpty {
                        avatarURL = URL(string: "\(address)/public/api/v1/files/image/\(avatarId)?size=avatar")
                    }
                    
                    IQLog.debug(message: "Auto greet avatarURL:\(String(describing: avatarURL))")
                    
                    if(settings.totalOpenedTickets == 0){
                        value.append(IQMessage(
                            text: settings.message,
                            operatorName: settings.pseudonym ?? "Оператор",
                            avatarID: settings.avatarID,
                            avatarURL: avatarURL,
                            isAutoGreet: true
                        ))
                        lifeTime = settings.lifetime
                    }
                }
            }
        }
        
        let unreadMessages = value.filter { ($0.isRead == nil || $0.isRead == false) && $0.author == .user}
        let unreadMessagesCount = unreadMessages.count
        
        
        if(unreadMessagesCount > 0){
            if let lastMessage = value.last, !(lastMessage.isMy ?? false) {
                value.insert(
                    IQMessage(newMsgHeader: true),
                    at: value.count - unreadMessagesCount
                )
            }
        }
        Task {
            await MainActor.run {
                IQChannelsManager.unreadListeners.forEach { $0.iqChannelsUnreadDidChange(unreadMessagesCount) }
            }
        }
        
        self.relationManager.chatMessages(&value, with: result.relations)
        
        for message in value{
            IQDatabaseManager.shared.insertMessage(message.toDatabaseMessage())
        }
        
        IQLog.debug(message: "loadMessages: \n request: \(request) \n success")
        IQLog.debug(message: "Unread count = \(unreadMessagesCount)")
        IQLog.debug(message: "Unread messages = \(unreadMessages)")
        
        return .init(result: (value, systemChat, lifeTime, chatTitle, availableLanguages))
    }
    
    func rate(value: Int, ratingID: Int) async -> Error? {
        let path = "/ratings/rate"
        let params: [String: Any] = ["ratingId": ratingID, "rating": ["Value": value]]
        let response = await post(path, body: params, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "rate: \n params: \(params) \n response: \(response)")
        
        return response.error
    }
    
    func getBlocker() async -> ResponseCallback<IQInfoChatSettings> {
        let path = "/chats/channel/blocker/\(channel)"
        let response = await post(path, body: [], responseType: IQInfoChatSettingsResponse.self)
        
        guard response.error == nil else {
            IQLog.error(message: "getBlocker: \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        
        guard let result = response.result, let value = result.value else { return .init(error: NSError.failedToParseModel(IQInfoChatSettingsResponse.self)) }
        
        IQLog.debug(message: "IQInfoChatSettingsResponse: \n success")
        
        let infoChatSettings = IQInfoChatSettings(
            blockerText: value.text,
            blockerIcon: relationManager.fileUrl(value.blockerFileID)
        )
        
        return .init(result: infoChatSettings)
    }
    
    func sendPoll(request: IQSendPollRequest) async -> Error? {
        let path = "/ratings/send_poll"
        let response = await post(path, body: request, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendPoll: \n request: \(request) \n response: \(response)")
        
        return response.error
    }
    
    func finishPoll(ratingId: Int, pollId: Int, rated: Bool) async -> Error? {
        let path = "/ratings/finish_poll"
        let params: [String: Any] = ["RatingId": ratingId, "RatingPollId": pollId, "Rated": rated]
        let response = await post(path, body: params, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "finishPoll: \n params: \(params) \n response: \(response)")
        
        return response.error
    }
    
    func uploadFile(file: DataFile, taskIdentifierCallback: TaskIdentifierCallback? = nil) async -> ResponseCallback<IQFile> {
        let path = "/files/upload"
        let isImage = file.filename == "image.jpeg"
        let params = [
            "Type": isImage ? "image" : "file"
        ]
        let files = [
            "File": IQFileUploadRequest(name: file.filename, data: file.data)
        ]
        
        let response = await post(path, multipart: params, files: files, taskIdentifierCallback: taskIdentifierCallback, responseType: IQFile.self)
        
        guard response.error == nil else {
            IQLog.error(message: "uploadFile: \n params: \(params) \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let result = response.result, var file = result.value else { return .init(error: NSError.failedToParseModel([IQMessage].self)) }
        
        IQLog.debug(message: "uploadFile: \n params: \(params) \n success")
        
        relationManager.file(&file, with: result.relations)
        return .init(result: file)
    }
    
    func sendMessage(form: IQMessageForm) async -> Error? {
        let path = "/chats/channel/send/\(channel)"
        let response = await post(path, body: form, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "sendMessage: \n form: \(form) \n result: \(response)")
        
        return response.error
    }
    
    func acceptProduct(form: IQProductForm) async -> Error? {
        let path = "/chats/messages/accept_product"
        let response = await post(path, body: form, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "acceptProduct: \n form: \(form) \n result: \(response)")
        
        return response.error
    }
    
    func declineProduct(form: IQProductForm) async -> Error? {
        let path = "/chats/messages/decline_product"
        let response = await post(path, body: form, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "declineProduct: \n form: \(form) \n result: \(response)")
        
        return response.error
    }
    
    func clientsAuth(token: String) async -> ResponseCallback<IQClientAuth> {
        let path = "/clients/auth"
        let body = IQClientAuthRequest(token: token)
        let response = await post(path, body: body, responseType: IQClientAuth.self)
        
        guard response.error == nil else {
            IQLog.error(message: "Authenticating anonymous: \n body: \(body) \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let auth = response.result?.value else { return .init(error: NSError.failedToParseModel(IQClientAuth.self)) }
        
        IQLog.debug(message: "Authenticating anonymous: \n body: \(body) \n auth: \(auth)")
        
        return .init(result: auth)
    }
    
    func clientsSignup() async -> ResponseCallback<IQClientAuth> {
        let path = "/clients/anonymous/signup"
        let body = IQSignupRequest(channel: channel)
        let response = await post(path, body: body, responseType: IQClientAuth.self)
        
        guard response.error == nil else {
            IQLog.error(message: "clientsSignup: \n body: \(body) \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let auth = response.result?.value else { return .init(error: NSError.failedToParseModel(IQClientAuth.self)) }
        
        IQLog.debug(message: "clientsSignup: \n body: \(body) \n auth: \(auth)")
        
        return .init(result: auth)
    }
    
    func clientsIntegrationAuth(credentials: String) async -> ResponseCallback<IQClientAuth> {
        let path = "/clients/integration_auth"
        let body = IQClientIntegrationAuthRequest(credentials: credentials, channel: channel)
        let response = await post(path, body: body, responseType: IQClientAuth.self)
        
        guard response.error == nil else {
            IQLog.error(message: "Authenticating: \n body: \(body) \n error: \(String(describing: response.error))")
            return .init(error: response.error)
        }
        guard let auth = response.result?.value else { return .init(error: NSError.failedToParseModel(IQClientAuth.self)) }
        
        IQLog.debug(message: "Authenticating: \n body: \(body) \n auth: \(auth)")
        
        return .init(result: auth)
    }
    
    func setLanguage(languageCode: String) async -> Error? {
        let path = "/clients/set_language"
        let params = ["code": languageCode]
        let response = await post(path, body: params, responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "setLanguage: \n languageCode: \(languageCode) \n response: \(response)")
        
        return response.error
    }
    
    func getAdvancedUnread(channels: [String]) async -> Error? {
        let path = "/clients/get_last_messages"
        let params = ["ChannelNames": channels]
        let response = await post(path, body: params, responseType: IQAdvancedUnread.self)
        
        if let result = response.result?.value{
            IQChannelsManager.advancedUnread = result
            Task {
                await MainActor.run {
                    IQChannelsManager.advancedUnreadListeners.forEach { $0.iqChannelsAdvancedUnreadDidChange(result) }
                }
            }
        }
        
        if let error = response.error{
            Task {
                await MainActor.run {
                    IQChannelsManager.advancedUnreadListeners.forEach { $0.iqChannelsAdvancedUnreadException(error) }
                }
            }
        }
        
        IQLog.debug(message: "getAdvancedUnread: \n ChannelNames: \(channels) \n response: \(response)")
        
        return response.error
    }
    
    func changeSegment(messageID: Int) async -> Error? {
        let path = "/chats/messages/\(messageID)/delete_transfer_to_channel_id"
        let response = await post(path, body: [], responseType: IQEmptyResponse.self)
        
        IQLog.debug(message: "changeSegment: \n response: \(response)")
        
        return response.error
    }
}
