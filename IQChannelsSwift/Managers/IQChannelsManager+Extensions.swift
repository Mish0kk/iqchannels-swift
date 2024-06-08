//
//  IQChannelsManager+Extensinos.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 10.05.2024.
//

import PhotosUI
import SDWebImage
import Combine

//MARK: - Private Methods
extension IQChannelsManager {
    
    func setupCombine(){
        $authResults.sink { [weak self] results in
            Task { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    let items = self.getChatItems(from: results)
                    if items.count == 1, let item = items.first,
                       let authResult = results.first(where: { $0.channel == item.channel } ){
                        self.selectedChat = (authResult, item.chatType)
                    } else {
                        self.listViewModel?.chatsInfo = items
                    }
                }
            }
        }.store(in: &subscriptions)
        
        $selectedChat.sink { [weak self] (chat) in
            Task { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    if let self, let chat {
                        listViewModel?.chatToPresentListener.send(getDetailViewController(for: chat))
                        listenToUnread()
                        loadMessages()
                    }
                }
            }
        }.store(in: &subscriptions)
        
        $state.receive(on: DispatchQueue.main).sink { [weak self] state in
            guard let self else { return }
            
            baseViewModels.setState(state)
        }.store(in: &subscriptions)
        
        $messages.receive(on: DispatchQueue.main).sink { [weak self] messages in
            guard let self else { return }
            
            detailViewModel?.messages = messages.reversed()
        }.store(in: &subscriptions)
    }
    
    func setupImageManager(){
        SDWebImageManager.shared.optionsProcessor = SDWebImageOptionsProcessor(block: { url, options, context in
            SDWebImageOptionsResult(options: .allowInvalidSSLCertificates, context: context)
        })
    }
    
    private func getDetailViewController(for chat: (auth: AuthResult, chatType: IQChatType)) -> IQChatDetailViewController {
        let viewModel = IQChatDetailViewModel()
        detailViewModel = viewModel
        viewModel.backDismisses = authResults.count == 1
        viewModel.state = state
        viewModel.client = chat.auth.auth.client
        viewModel.messages = messages.reversed()
        return IQChatDetailViewController(viewModel: viewModel, output: self)
    }
    
    func getChatItems(from results: [AuthResult]) -> [IQChatItemModel] {
        results.map { (channel, auth) -> [IQChatItemModel] in
            guard let client = auth.client else { return [] }
            
            return client.chatTypes.map { .init(channel: channel, info: client.multiChatsInfo, chatType: $0) }
        }.flatMap {$0}
    }
    
    func closeCurrentChat() {
        guard let networkManager = currentNetworkManager else { return }
        
        networkManager.stopUnreadListeners()
        networkManager.stopListenToEvents()
        self.messages = []
        self.selectedChat = nil
        self.detailViewModel = nil
        self.readMessages = []
        self.lastLocalID = 0
        self.unsentMessages = []
        self.typingTimer?.invalidate()
        self.typingTimer = nil
        self.typingSentDate = nil
    }
    
    func clear() {
        closeCurrentChat()
        clearAuth()
        (SDWebImageManager.shared.imageCache as? SDImageCache)?.clearMemory()
    }
    
    private func listenToEvents(){
        guard !authResults.isEmpty, networkStatusManager.isReachable, let selectedChat else { return }
        
        var query = IQListenEventsRequest(chatType: selectedChat.chatType)
        for message in messages where message.eventID ?? 0 > query.lastEventID ?? 0 {
            query.lastEventID = message.eventID
        }
        
        currentNetworkManager?.listenToEvents(request: query) { [weak self] events, error in
            guard let self else { return }
            
            if error != nil {
                DispatchQueue.main.async { [weak self] in
                    self?.currentNetworkManager?.stopListenToEvents()
                    self?.listenToEvents()
                }
            } else {
                applyEvents(events ?? [])
            }
        }
    }
    
    private func applyEvents(_ events: [IQChatEvent]) {
        for event in events {
            switch event.type {
            case .typing:
                messageTyping(event)
            case .messageCreated:
                messageCreated(event)
            case .messageRead:
                messageRead(event)
            case .deleteMessages:
                messagesRemoved(event)
            default: break
            }
        }
    }
    
    func openFileInBrowser(_ file: IQFile) {
        guard let url = file.url else { return }
        
        UIApplication.shared.open(url)
    }
    
}

//MARK: - APNs
extension IQChannelsManager {
    
    func pushToken(_ data: Data?) {
        guard let data else { return }
        
        let token = data.map { String(format: "%02.2hhX", $0) }.joined()
        sendApnsToken(token)
    }
    
    private func sendApnsToken(_ apnsToken: String) {
        Task {
            guard let currentNetworkManager else { return }
            
            let error = await currentNetworkManager.pushToken(token: apnsToken)
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.sendApnsToken(apnsToken)
                }
            }
        }
    }
    
}

//MARK: - Typing
extension IQChannelsManager {
    
    func sendTypingEvent() {
        let debounceTime = 1.5
        if let typingSentDate, (Date().timeIntervalSince1970 - typingSentDate.timeIntervalSince1970) < debounceTime {
            return
        }
        typingSentDate = .init()
        
        Task {
            let _ = await currentNetworkManager?.sendTypingEvent()
        }
    }
    
    private func messageTyping(_ event: IQChatEvent) {
        guard event.actor != .client,
              let user = event.user else { return }
                
        if detailViewModel?.typingUser != nil{
            typingTimer?.fireDate = (typingTimer?.fireDate ?? .init()).addingTimeInterval(2)
        } else {
            setTypingUser(user)
        }
    }
    
    private func setTypingUser(_ user: IQUser) {
        DispatchQueue.main.async { [self] in
            detailViewModel?.typingUser = user
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] timer in
                timer.invalidate()
                self?.typingTimer = nil
                self?.detailViewModel?.typingUser = nil
            })
        }
    }
    
}

//MARK: - Rating
extension IQChannelsManager {
    
    func rate(value: Int, ratingID: Int) {
        Task {
            let error = await currentNetworkManager?.rate(value: value, ratingID: ratingID)
            guard error == nil,
                  let index = self.messages.lastIndex(where: { $0.ratingID == ratingID }) else { return }
            
            messages[index].rating?.state = .rated
        }
    }
    
}


//MARK: - Unread
extension IQChannelsManager {
    
    private func listenToUnread(){
        guard networkStatusManager.isReachable else { return }
        
        currentNetworkManager?.listenToUnread { [weak self] value, error in
            guard let self else { return }
            
            if error != nil {
                currentNetworkManager?.stopUnreadListeners()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.listenToUnread()
                }
            } else {
                unreadListeners.forEach { $0.iqChannelsUnreadDidChange(value ?? 0) }
            }
        }
    }
    
}

//MARK: - Messages
extension IQChannelsManager {
    
    func send(_ action: IQAction) {
        guard let selectedChat else { return }
        
        switch action.action {
        case "Postback", "Say something":
            let message = IQMessage(action: action, chatType: selectedChat.chatType, localID: nextLocalId())
            messages.append(message)
            Task {
                await sendMessage(message)
            }
        case "Open URL":
            guard let url = URL(string: action.url ?? "") else { return }
            
            UIApplication.shared.open(url)
        default: break
        }
        
    }
    
    func send(_ choice: IQSingleChoice) {
        guard let selectedChat else { return }
        
        let message = IQMessage(choice: choice, chatType: selectedChat.chatType, localID: nextLocalId())
        messages.append(message)
        Task {
            await sendMessage(message)
        }
    }
    
    func sendText(_ text: String, replyToMessage: Int?) {
        guard let selectedChat else { return }
                
        let message = IQMessage(text: text, chatType: selectedChat.chatType, localID: nextLocalId(), replyMessageID: replyToMessage)
        messages.append(message)
        Task {
            await sendMessage(message)
        }
    }
    
    func sendFiles(items: [(URL?, UIImage?)], replyToMessage: Int?) {
        let files: [DataFile] = items.prefix(10).compactMap { (url, image) in
            if let url {
                defer { url.stopAccessingSecurityScopedResource() }
                guard url.startAccessingSecurityScopedResource(), let data = try? Data(contentsOf: url) else { return nil }
                return .init(data: data, filename: url.lastPathComponent)
            } else if let image {
                guard let data = image.dataRepresentation() else { return nil }
                return .init(data: data, filename: "image.jpeg")
            }
            return nil
        }
        
        sendFiles(files, replyToMessage: replyToMessage)
    }
    
    func sendImages(result: [PHPickerResult], replyToMessage: Int?) {
        Task {
            var files = [DataFile]()
            await result.asyncForEach {
                guard let data = await $0.data() else { return }
                let isGif = $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.gif.identifier)
                files.append(.init(data: data, filename: isGif ? "image.gif" : "image.jpeg"))
            }
            
            sendFiles(files, replyToMessage: replyToMessage)
        }
    }
    
    private func sendFiles(_ files: [DataFile], replyToMessage: Int?) {
        guard let selectedChat else { return }
        
        let newMessages = files.enumerated().map { index, file in
            IQMessage(dataFile: file, chatType: selectedChat.chatType, localID: nextLocalId(), replyMessageID: index == 0 ? replyToMessage : nil)
        }
        messages.append(contentsOf: newMessages)
        
        Task {
            for message in newMessages {
                await uploadFileMessage(message)
            }
        }
    }
    
    func cancelUploadFileMessage(_ message: IQMessage) {
        if let messageIndex = indexOfMyMessage(localID: message.localID) {
            messages.remove(at: messageIndex)
        }
        if let taskID = message.file?.taskIdentifier {
            currentNetworkManager?.cancelTask(with: taskID)
        }
    }
    
    private func uploadFileMessage(_ message: IQMessage) async {
        guard let networkManager = currentNetworkManager,
              let dataFile = message.file?.dataFile,
              indexOfMyMessage(localID: message.localID) != nil else { return }
        
        let response = await networkManager.uploadFile(file: dataFile) { [weak self] taskIdentifier in
            if let index = self?.indexOfMyMessage(localID: message.localID) {
                self?.messages[index].file?.taskIdentifier = taskIdentifier
            }
        }
        
        if response.error != nil {
            if let error = response.error, error.iqAppError != nil {
                if let index = indexOfMyMessage(localID: message.localID) {
                    messages.remove(at: index)
                    baseViewModels.sendError(error)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    Task {
                        await self?.uploadFileMessage(message)
                    }
                }
            }
        } else if let file = response.result,
                  let index = indexOfMyMessage(localID: message.localID) {
            messages[index].file = file
            messages[index].fileID = file.id
            Task {
                await sendMessage(messages[index])
            }
        }
    }
    
    func messageDisplayed(_ messageID: Int) {
        markAsRead(messageID)
        
        guard let index = indexOfMessage(messageID: messageID) else { return }
        
        if index == messages.count - 1 {
            DispatchQueue.main.async {
                self.detailViewModel?.scrollDotHidden = true
            }
        }
        
        if !isLoadingOldMessages,
           index <= 15 {
            loadOldMessages()
        }
    }
    
    private func markAsRead(_ messageID: Int ){
        guard !readMessages.contains(messageID),
              let message = messages.first(where: { $0.messageID == messageID }),
              !(message.isRead ?? false), !(message.isMy) else { return }
        
        readMessages.update(with: messageID)
        
        Task {
            let _ = await currentNetworkManager?.sendReadEvent([messageID])
        }
    }
    
    private func markAsReceived(_ messageID: [Int]) {
        let messageIDs = messageID.filter { $0 != 0 }
        
        Task {
            let _ = await currentNetworkManager?.sendReceivedEvent(messageIDs)
        }
    }
    
    private func sendMessage(_ message: IQMessage) async {
        guard let networkManager = currentNetworkManager else { return }
        
        let error = await networkManager.sendMessage(form: .init(message))
        
        if error != nil {
            if networkStatusManager.isReachable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    Task {
                        await self?.sendMessage(message)
                    }
                }
            } else {
                unsentMessages.append(message)
            }
        } else {
            unsentMessages.removeAll(where: { $0.id == message.id })
        }
    }
    
    private func uploadUnsentMessages(){
        guard !unsentMessages.isEmpty else { return }
        
        let messages = unsentMessages.sorted(by: { $0.createdDate < $1.createdDate })
        Task {
            for message in messages {
                await sendMessage(message)
            }
            uploadUnsentMessages()
        }
    }
    
    private func loadMessagesAndMerge() async {
        guard let networkManager = currentNetworkManager, let selectedChat else { return }
        
        networkManager.stopListenToEvents()
        let result = await networkManager.loadMessages(request: .init(chatType: selectedChat.chatType))
        let newMessages = (result.result ?? [])
            .filter { $0.hasValidPayload }
            .filter { indexOfMessage(messageID: $0.messageID) == nil }
        print("Missed messages: ", newMessages.map { $0.text })
        if !newMessages.isEmpty {
            var messages = self.messages
            messages.append(contentsOf: newMessages)
            messages.sort(by: { $0.createdDate < $1.createdDate })
            self.messages = messages
        }
        listenToEvents()
    }
    
    private func loadMessages() {
        Task {
            guard let networkManager = currentNetworkManager, let selectedChat else { return }
            
            messages = []
            networkManager.stopListenToEvents()
            DispatchQueue.main.async { self.detailViewModel?.isLoading = true }
            let result = await networkManager.loadMessages(request: .init(chatType: selectedChat.chatType))
            DispatchQueue.main.async { self.detailViewModel?.isLoading = false }
            if let error = result.error {
                baseViewModels.sendError(error)
                return
            }
            
            let results = (result.result ?? []).filter { $0.hasValidPayload }
            messages = results
            listenToEvents()
        }
    }
    
    func loadOldMessages() {
        Task {
            guard let networkManager = currentNetworkManager, let selectedChat else { return }
            
            var query = IQLoadMessageRequest(chatType: selectedChat.chatType)
            for message in messages {
                guard message.messageID != 0 else { continue }
                query.maxID = message.messageID
                break
            }
            
            
            isLoadingOldMessages = true
            let result = await networkManager.loadMessages(request: query)
            isLoadingOldMessages = false
            
            if let error = result.error {
                baseViewModels.sendError(error)
                return
            }
            
            let newMessages = result.result?.filter { indexOfMessage(messageID: $0.messageID) == nil && $0.hasValidPayload } ?? []
            messages.insert(contentsOf: newMessages, at: 0)
            markAsReceived(newMessages.map { $0.messageID })
        }
    }
    
    private func messageRead(_ event: IQChatEvent) {
        guard let index = indexOfMessage(messageID: event.messageID) else { return }
        var message = messages[index]
        
        guard message.eventID ?? 0 < event.id else { return }
        
        message.isRead = true
        message.eventID = event.id
        
        messages[index] = message
    }
    
    private func messageCreated(_ event: IQChatEvent) {
        guard let message = event.message else { return }
        
        if let index = indexOfMyMessage(localID: message.localID){
            messages[index] = messages[index].merged(with: message)
        } else if message.hasValidPayload, indexOfMessage(messageID: message.messageID) == nil {
            messages.append(message)
            markAsReceived([message.messageID])
            DispatchQueue.main.async {
                self.detailViewModel?.scrollDotHidden = false
            }
        }
    }
    
    private func messagesRemoved(_ event: IQChatEvent) {
        let ids = event.messages?.map({ $0.messageID }).compactMap { indexOfMessage(messageID: $0) } ?? []
        messages.remove(elementsAtIndices: ids)
    }
    
    private func message(with messageID: Int?) -> IQMessage? {
        guard let index = indexOfMessage(messageID: messageID) else { return nil }
        
        return messages[index]
    }
    
    private func indexOfMessage(messageID id: Int?) -> Int? {
        messages.firstIndex(where: { $0.messageID != 0 && $0.messageID == id })
    }
    
    private func indexOfMyMessage(localID id: Int?) -> Int? {
        messages.firstIndex(where: { $0.localID != nil && $0.localID == id })
    }
    
    private func nextLocalId() -> Int {
        var tempLocalId = Int(Date().timeIntervalSince1970 * 1000)
        while tempLocalId <= lastLocalID {
            tempLocalId += 1
        }
        lastLocalID = tempLocalId
        return tempLocalId
    }
    
}

//MARK: - Auth
extension IQChannelsManager {
    
    private func clearAuth(){
        networkManagers.forEach { (key, _) in
            networkManagers[key]?.token = nil
        }
        authResults = []
        authAttempt = 0
        state = .loggedOut
        loginType = nil
        listViewModel = nil
    }
    
    func auth(_ loginType: IQLoginType) {
        self.loginType = loginType
        guard authResults.isEmpty,
              networkStatusManager.isReachable else { return }
        
        Task{
            authAttempt += 1
            if authAttempt == 1 {
                state = .authenticating
            }
            
            var errors = [Error?]()
            var results = [(String, IQClientAuth?)]()
            await networkManagers.asyncForEach { (channel, networkManager) in
                let response: ResponseCallback<IQClientAuth>
                switch loginType {
                case .anonymous:
                    if let token = storageManager.anonymousTokens?[channel] {
                        response = await networkManager.clientsAuth(token: token)
                    } else {
                        response = await networkManager.clientsSignup()
                    }
                case let .credentials(credential):
                    response = await networkManager.clientsIntegrationAuth(credentials: credential)
                }
                errors.append(response.error)
                results.append((channel, response.result))
            }
            
            if let error = errors.compactMap({$0}).first{
                self.auth(loginType, failedWith: error)
            } else {
                self.auth(loginType, succeededWith: results)
            }
        }
    }
    
    private func auth(_ type: IQLoginType, succeededWith results: [(channel: String, auth: IQClientAuth?)]) {
        guard results.allSatisfy({ $0.auth?.client != nil && $0.auth?.session != nil }) else {
            self.auth(type, failedWith: nil)
            return
        }
        
        let results = Array(zip(results.map { $0.channel }, results.compactMap { $0.auth }))
        
        results.forEach { (channel, auth) in
            guard let token = auth.session?.token else { return }
            
            networkManagers[channel]?.token = token
            if type == .anonymous {
                if storageManager.anonymousTokens != nil {
                    storageManager.anonymousTokens?.updateValue(token, forKey: channel)
                } else {
                    storageManager.anonymousTokens = [channel: token]
                }
            }
        }
        authResults = results
        authAttempt = 0
        state = .authenticated
    }
    
    private func auth(_ type: IQLoginType, failedWith error: Error?) {
        authResults = []
        state = networkStatusManager.isReachable ? .loggedOut : .awaitingNetwork
        if networkStatusManager.isReachable {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                let isAuthError = error?.iqIsAuthError ?? false
                self?.auth(isAuthError ? .anonymous : type)
            }
        }
    }
    
}

//MARK: - Network Status
extension IQChannelsManager: IQNetworkStatusManagerDelegate {
    
    func networkStatusChanged(_ status: IQNetworkStatus) {
        Task {
            guard status != .notReachable else {
                state = .awaitingNetwork
                currentNetworkManager?.stopListenToEvents()
                currentNetworkManager?.stopUnreadListeners()
                return
            }
            
            if !authResults.isEmpty {
                state = .authenticated
                await loadMessagesAndMerge()
                listenToUnread()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.uploadUnsentMessages()
                }
            } else if let loginType, state != .authenticating {
                authAttempt = 0
                auth(loginType)
            }
        }
    }
    
}
