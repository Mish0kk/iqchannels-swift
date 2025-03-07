//
//  IQChannelsManager+Extensinos.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 10.05.2024.
//

import PhotosUI
import SDWebImage
import Combine

private var selectedChatSubscription: AnyCancellable?
//MARK: - Private Methods
extension IQChannelsManager {
    
    func setupCombine(){
        $authResults.sink { [weak self] results in
            Task { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    var items = self.getChatItems(from: results)
                    
                    if let chatToOpen = config.chatToOpen,
                       let item = items.first(where: { $0.channel == chatToOpen.channel && $0.chatType == chatToOpen.chatType }) {
                        items = [item]
                    }

                    if items.count == 1, let item = items.first,
                       let authResult = results.first(where: { $0.channel == item.channel } ){
                        self.selectedChat = (authResult, item.chatType)
                    } else if let attachment = config.attachment,
                              let authResult = results.first(where: { $0.channel == attachment.channel }),
                              items.contains(where: { $0.channel == attachment.channel && $0.chatType == attachment.chatType }) {
                        self.listViewModel?.chatsInfo = items
                        self.selectedChat = (authResult, attachment.chatType)
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
    
    func configureCombine(){
        $state.receive(on: DispatchQueue.main).sink { [weak self] state in
            guard let self else { return }
            
            baseViewModels.setState(state)
        }.store(in: &subscriptions)
        
        $messages.receive(on: DispatchQueue.main).sink { [weak self] messages in
            guard let self else { return }
            
            detailViewModel?.messages = messages.reversed()
        }.store(in: &subscriptions)
    }
    
    func setupFileLimits() {
        Task {
            fileLimit = try? await IQNetworkManager.getFileConfig(address: config.address)
        }
    }
    
    func setupImageManager(){
        SDWebImageManager.shared.optionsProcessor = SDWebImageOptionsProcessor(block: { url, options, context in
            SDWebImageOptionsResult(options: .allowInvalidSSLCertificates, context: context)
        })
    }
    
    private func getDetailViewController(for chat: (auth: AuthResult, chatType: IQChatType)) -> IQChatDetailViewController {
        let viewModel = IQChatDetailViewModel()
        detailViewModel = viewModel
        viewModel.backDismisses = getChatItems(from: authResults).count == 1
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
        IQLog.debug(message: "closeCurrentChat")
        
        listViewModel?.popListener.send(())
        
//        networkManager.stopListenToUnread()
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
        didSendAttachments = false
        (SDWebImageManager.shared.imageCache as? SDImageCache)?.clearMemory()
    }
    
    private func sendAttachmentsIfNeeded() {
        guard let attachment = config.attachment, !didSendAttachments else { return }
        
        didSendAttachments = true
        
        let texts = attachment.attachments.compactMap{ if case .text(let text) = $0 { text } else { nil } }
        let files = attachment.attachments.compactMap{ if case let .file(image, filename) = $0 { DataFile(data: image, filename: filename) } else { nil } }
        
        texts.forEach {
            sendMessage($0, files: nil, replyToMessage: nil)
        }
        sendMessage("", files: files, replyToMessage: nil)
    }
    
    private func listenToEvents(){
        guard !authResults.isEmpty, networkStatusManager.isReachable, let selectedChat else { return }
        
        var query = IQListenEventsRequest(chatType: selectedChat.chatType)
        for message in messages where message.eventID ?? 0 > query.lastEventID ?? 0 {
            query.lastEventID = message.eventID
        }
        
        currentNetworkManager?.listenToEvents(request: query, onOpen: { [weak self] in
            self?.sendAttachmentsIfNeeded()
        }) { [weak self] events, error in
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.sendAttachmentsIfNeeded()
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
            case .fileStatusUpdated:
                fileStatusUpdated(event)
            case .ratingIgnored:
                ratingIgnored(event)
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
            rated(index: index, value: value)
        }
    }
    
    func sendPoll(value: Int?, answers: [IQRatingPollClientAnswerInput], ratingID: Int, pollId: Int) {
        Task {
            let error = await currentNetworkManager?.sendPoll(request: .init(ratingPollClientAnswerInput: answers))
            let errorFinish = await currentNetworkManager?.finishPoll(ratingId: ratingID, pollId: pollId, rated: true)
            
            guard error == nil, errorFinish == nil,
                  let index = self.messages.lastIndex(where: { $0.ratingID == ratingID }) else { return }
            rated(index: index, value: value)
        }
    }
    
    func pollIgnored(ratingID: Int, pollId: Int) {
        Task {
            let error = await currentNetworkManager?.finishPoll(ratingId: ratingID, pollId: pollId, rated: false)
            
            guard error == nil,
                  let index = self.messages.lastIndex(where: { $0.ratingID == ratingID }) else { return }
            ignored(index: index)
        }
    }
    
    func ratingIgnored(_ event: IQChatEvent) {
        guard let index = self.messages.lastIndex(where: { $0.ratingID == event.message?.ratingID }) else { return }
        ignored(index: index)
    }
    
    
    func rated(index: Int, value: Int?) {
        messages[index].rating?.state = .rated
        messages[index].rating?.value = value
        messages[index].isSystem = true
    }
    
    func ignored(index: Int) {
        messages[index].rating?.state = .ignored
        messages[index].isSystem = true
    }
    

    
}


//MARK: - Unread
extension IQChannelsManager {
    
    private func listenToUnread(){
        guard networkStatusManager.isReachable else { return }
        
        currentNetworkManager?.listenToUnread { [weak self] value, error in
            guard let self else { return }
            
            if error != nil {
                currentNetworkManager?.stopListenToUnread()
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
    
    public func sendMessage(_ text: String, files: [DataFile]?, replyToMessage: Int?) {
        guard let selectedChat else { return }
        
        if let files {
            var hasNonValidatedFilesText: String? = nil
            let newMessages = files.enumerated().compactMap { index, file -> IQMessage? in
                hasNonValidatedFilesText = validate(file, with: fileLimit)
                if(hasNonValidatedFilesText != nil){
                    return nil
                }
                return IQMessage(dataFile: file, chatType: selectedChat.chatType, localID: nextLocalId(), text: index == 0 ? text : nil, replyMessageID: index == 0 ? replyToMessage : nil)
            }
            
            if hasNonValidatedFilesText != nil {
                DispatchQueue.main.async {
                    self.detailViewModel?.errorListener.send(NSError.clientError(hasNonValidatedFilesText))
                }
                return
            }
            
            messages.append(contentsOf: newMessages)
    
            Task {
                for message in newMessages {
                    await uploadFileMessage(message)
                }
            }
    
        } else {
            let message = IQMessage(text: text, chatType: selectedChat.chatType, localID: nextLocalId(), replyMessageID: replyToMessage)
            messages.append(message)
            Task {
                await sendMessage(message)
            }
        }
    }
    
    public func resendMessage(_ message: IQMessage) {
        Task {
            await sendMessage(message)
        }
    }
    
    
    func sendFiles(items: [(URL?, UIImage?)]) {
        let files: [DataFile] = items.prefix(10).compactMap { (url, image) -> DataFile? in
            if let url {
                defer { url.stopAccessingSecurityScopedResource() }
                guard url.startAccessingSecurityScopedResource(), let data = try? Data(contentsOf: url) else { return nil }
                return .init(data: data, filename: url.lastPathComponent)
            } else if let image {
                guard let data = image.dataRepresentation(withMaxSizeMB: CGFloat(fileLimit?.maxFileSizeMb ?? 10)) else { return nil }
                return .init(data: data, filename: "image.jpeg")
            }
            return nil
        }
        
        selectFiles(files)
    }
    
    func sendImages(result: [PHPickerResult]) {
        Task {
            var files = [DataFile]()
            await result.asyncForEach {
                guard let data = await $0.data(maxSizeInMB: CGFloat(fileLimit?.maxFileSizeMb ?? 10)) else { return }
                let isGif = $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.gif.identifier)
                files.append(.init(data: data, filename: isGif ? "image.gif" : "image.jpeg"))
            }
            
            selectFiles(files)
        }
    }
    
    private func selectFiles(_ files: [DataFile]) {
        if (!files.isEmpty){
            DispatchQueue.main.async {
                self.detailViewModel?.selectedFiles = files
            }
        }
    }
    
    
    
    private func validate(_ file: DataFile, with limits: IQFileConfig?) -> String? {
        guard let limits else { return nil }
        
        let dataMB = file.data.count / 1024 / 1024
        if let size = limits.maxFileSizeMb, dataMB > size {
            return "Превышен максимально допустимый размер файла"
        }
        
        if let maxImageHeight = limits.maxImageHeight,
           let maxImageWidth = limits.maxImageWidth,
           let image = UIImage(data: file.data),
           Int(image.size.height) > maxImageHeight || Int(image.size.width) > maxImageWidth {
            return "Слишком большая ширина или высота изображения"
        }
        
        if let fileExtensions = file.filename.components(separatedBy: ".")[safe: 1] {
            if let allowedExtensions = limits.allowedExtensions,
               !allowedExtensions.contains(fileExtensions) {
                return "Неподдерживаемый тип файла"
            }
            if let forbiddenExtensions = limits.forbiddenExtensions,
               forbiddenExtensions.contains(fileExtensions) {
                return "Запрещенный тип файла"
            }
        }
        return nil
    }
    
    func cancelUploadFileMessage(_ message: IQMessage) {
        cancelSendMessage(message)
        if let taskID = message.file?.taskIdentifier {
            currentNetworkManager?.cancelTask(with: taskID)
        }
    }
    
    func cancelSendMessage(_ message: IQMessage) {
        if let messageIndex = indexOfMyMessage(localID: message.localID) {
            messages.remove(at: messageIndex)
            IQDatabaseManager.shared.deleteMessageByLocalId(message.localID ?? 0)
        }
    }
    
    private func uploadFileMessage(_ message: IQMessage) async {
        guard let networkManager = currentNetworkManager,
              let dataFile = message.file?.dataFile,
              indexOfMyMessage(localID: message.localID) != nil else { return }
        
        IQDatabaseManager.shared.insertMessage(message.toDatabaseMessage())
        
        let response = await networkManager.uploadFile(file: dataFile) { [weak self] taskIdentifier in
            if let index = self?.indexOfMyMessage(localID: message.localID) {
                self?.messages[index].file?.taskIdentifier = taskIdentifier
            }
        }
        
        if response.error != nil {
            if let error = response.error {
                if let index = indexOfMyMessage(localID: message.localID) {
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
                self.detailViewModel?.idOfNewMessage = messageID
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
    
    private func sendMessage(_ message: IQMessage, attempts: Int = 0) async {
        if (!message.error){
            var attempts = attempts
            
            if let index = messages.firstIndex(where: { $0.localID == message.localID }) {
                messages[index] = message
            }
            
            messages.removeAll { $0.newMsgHeader == true }
            IQDatabaseManager.shared.insertMessage(message.toDatabaseMessage())
            
            DispatchQueue.main.async { [self] in
                detailViewModel?.idOfNewMessage = nil
            }
            
            guard let networkManager = currentNetworkManager else { return }
            
            let error = await networkManager.sendMessage(form: .init(message))
            
            if error != nil {
                if networkStatusManager.isReachable && attempts < 4{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                        Task {
                            attempts += 1
                            await self?.sendMessage(message, attempts: attempts)
                        }
                    }
                    print(attempts)
                } else {
                    var errorMessage = message.withError(true)
                    
                    if let index = messages.firstIndex(where: { $0.localID == message.localID }) {
                        messages[index] = errorMessage
                    }
                    
                    IQDatabaseManager.shared.insertMessage(errorMessage.toDatabaseMessage())
                    unsentMessages.append(errorMessage)
                }
            } else {
                unsentMessages.removeAll(where: { $0.id == message.id })
            }
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
        let result = await networkManager.loadMessages(request: .init(chatType: selectedChat.chatType), getSettings: false).result
        let newMessages = (result?.0 ?? [])
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
            
            let result = await networkManager.loadMessages(request: .init(clientId: selectedChat.auth.auth.client?.id, chatType: selectedChat.chatType), getSettings: true)
            DispatchQueue.main.async { self.detailViewModel?.isLoading = false }
            
            if let error = result.error {
                baseViewModels.sendError(error)
                return
            }
            let lifeTime = result.result?.2
            self.systemChat = result.result?.1 ?? false
            let results = (result.result?.0 ?? []).filter { $0.hasValidPayload }
            
            messages = results
            if let lifeTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(lifeTime)) {
                    if let index = self.messages.firstIndex(where: { $0.localID == -1 }) {
                        self.messages.remove(at: index)
                    }
                }
            }
            
            listenToEvents()
            
            await sendUnsendMessages()
            sendPreFillMessages()
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                if let unreadMessage = messages.enumerated().first(where: { (index, message) -> Bool in
                    guard index > 0 else { return false }
                    let prev = self.messages[index - 1]
                    return message.isRead == false && prev.isRead == true && message.author != .system && message.author != .client
                }) {
                    detailViewModel?.idOfNewMessage = unreadMessage.element.messageID
                } else {
                    detailViewModel?.idOfNewMessage = nil
                }
            }
        }
    }
    
    func loadOldMessages() {
        Task {
            isLoadingOldMessages = true
            guard let networkManager = currentNetworkManager, let selectedChat else {
                isLoadingOldMessages = false
                return
            }
            
            var query = IQLoadMessageRequest(chatType: selectedChat.chatType)
            for message in messages {
                guard message.messageID != 0 else { continue }
                query.maxID = message.messageID
                break
            }
            
            let result = await networkManager.loadMessages(request: query, getSettings: false)
            isLoadingOldMessages = false
            
            if let error = result.error {
                baseViewModels.sendError(error)
                return
            }
            
            let newMessages = result.result?.0.filter { indexOfMessage(messageID: $0.messageID) == nil && $0.hasValidPayload } ?? []
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
        
        IQDatabaseManager.shared.insertMessage(message.toDatabaseMessage())
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
    
    private func fileStatusUpdated(_ event: IQChatEvent) {
        Task {
            guard let messageID = event.messageID,
                  var message = message(with: messageID),
                  let fileID = message.fileID,
                  let newFile = try? await currentNetworkManager?.getFile(id: fileID) else { return }
            
            if let index = indexOfMessage(messageID: messageID) {
                message.file?.state = newFile.state
                self.messages[index] = message
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
    
    private func sendUnsendMessages() async {
        let unsentMessagesFromLocalDatabase = IQDatabaseManager.shared.getAllMessages().filter { $0.messageID == 0 && $0.author == "\"client\""}
        
        for unsentMessage in unsentMessagesFromLocalDatabase {
            messages.append(IQMessage(from: unsentMessage))
            if(unsentMessage.file != nil){
                await uploadFileMessage(IQMessage(from: unsentMessage))
            } else {
                await sendMessage(IQMessage(from: unsentMessage))
            }
        }
    }
    
    private func sendPreFillMessages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let preFillMessages = self.config.preFillMessages else { return }
            
            let texts = preFillMessages.textMsg
            let files = preFillMessages.fileMsg
            
            if let texts {
                for text in texts {
                    self.sendMessage(text, files: nil, replyToMessage: nil)
                }
            }
            if let files {
                self.sendMessage("", files: files, replyToMessage: nil)
            }
            self.config.preFillMessages = nil
        }
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
                currentNetworkManager?.stopListenToUnread()
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
