import XCTest
@testable import IQChannelsSwift

final class SseRecoveryTests: XCTestCase {

    private final class NetworkMock: IQNetworkManagerProtocol {
        var token: String?

        private(set) var listenRequests: [IQListenEventsRequest] = []
        private(set) var subscriptions: [(onOpen: () -> Void, callback: ResponseCallbackClosure<[IQChatEvent]>)] = []
        private(set) var loadMessagesRequests: [IQLoadMessageRequest] = []
        private(set) var sentForms: [IQMessageForm] = []
        var sendMessageResult: Error?

        private var loadMessagesResults: [ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)>] = []
        private var holdNext = false
        private var heldLoadMessages: [CheckedContinuation<ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)>, Never>] = []

        func enqueueLoadMessages(_ result: ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)>) {
            loadMessagesResults.append(result)
        }

        func holdNextLoadMessages() {
            holdNext = true
        }

        func resolveHeldLoadMessages(_ result: ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)>) {
            heldLoadMessages.forEach { $0.resume(returning: result) }
            heldLoadMessages.removeAll()
        }

        private var holdSends = false
        private var heldSends: [CheckedContinuation<Error?, Never>] = []

        func holdNextSendMessage() {
            holdSends = true
        }

        func resolveHeldSends(_ error: Error?) {
            heldSends.forEach { $0.resume(returning: error) }
            heldSends.removeAll()
        }

        func emit(_ events: [IQChatEvent]) {
            subscriptions.last?.callback(events, nil)
        }

        func isConnectedToEvents() -> Bool { true }
        func setCustomHeaders(_ headers: [String: String]) {}
        func resetSessionIfNeeded() {}
        func cancelTask(with taskIdentifier: Int) {}

        func listenToEvents(
            request: IQListenEventsRequest,
            onOpen: @escaping (() -> Void),
            callback: @escaping ResponseCallbackClosure<[IQChatEvent]>
        ) {
            listenRequests.append(request)
            subscriptions.append((onOpen, callback))
        }

        func stopListenToEvents() {
            subscriptions.removeAll()
        }

        func listenToAdvancedUnread(callback: @escaping ResponseCallbackClosure<IQAdvancedUnreadResult>) {}
        func stopListenToAdvancedUnread() {}
        func pushToken(token: String) async -> Error? { nil }
        func sendReceivedEvent(_ messageIDs: [Int]) async -> Error? { nil }
        func sendReadEvent(_ messageIDs: [Int]) async -> Error? { nil }
        func sendTypingEvent() async -> Error? { nil }
        func sendAnalyticsEvent(_ event: IQAnalyticsEvent) async -> ResponseCallback<IQResult<IQEmptyResponse>> { .init() }
        func getFile(id: String) async throws -> IQFile? { nil }
        func loadMessages(request: IQLoadMessageRequest, getSettings: Bool, isInfoChat: Bool, language: String?) async -> ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)> {
            loadMessagesRequests.append(request)
            if holdNext {
                holdNext = false
                return await withCheckedContinuation { continuation in
                    heldLoadMessages.append(continuation)
                }
            }
            return loadMessagesResults.isEmpty
                ? .init(result: ([], false, nil, "", nil, nil))
                : loadMessagesResults.removeFirst()
        }
        func getBlocker() async -> ResponseCallback<IQInfoChatSettings> { .init() }
        func rate(value: Int, ratingID: Int) async -> Error? { nil }
        func sendPoll(request: IQSendPollRequest) async -> Error? { nil }
        func finishPoll(ratingId: Int, pollId: Int, rated: Bool) async -> Error? { nil }
        func uploadFile(file: DataFile, taskIdentifierCallback: TaskIdentifierCallback?) async -> ResponseCallback<IQFile> { .init() }
        func sendMessage(form: IQMessageForm) async -> Error? {
            sentForms.append(form)
            if holdSends {
                return await withCheckedContinuation { continuation in
                    heldSends.append(continuation)
                }
            }
            return sendMessageResult
        }
        func acceptProduct(form: IQProductForm) async -> Error? { nil }
        func declineProduct(form: IQProductForm) async -> Error? { nil }
        func clientsAuth(token: String) async -> ResponseCallback<IQClientAuth> { .init() }
        func clientsSignup() async -> ResponseCallback<IQClientAuth> { .init() }
        func clientsIntegrationAuth(credentials: String) async -> ResponseCallback<IQClientAuth> { .init() }
        func getSignupGreetingSettings() async -> ResponseCallback<IQGreetingSettings> { .init() }
        func setLanguage(languageCode: String) async -> Error? { nil }
        func getAvailableLanguages() async -> ResponseCallback<[IQLanguage]> { .init(result: []) }
        func changeSegment(messageID: Int) async -> Error? { nil }
        func getAdvancedUnread(channels: [String]) async -> Error? { nil }
    }

    private func makeManager(mock: NetworkMock) -> IQChannelsManager {
        let config = IQChannelsConfig(address: "http://127.0.0.1:1", channels: ["support"])
        let manager = IQChannelsManager(configuration: config)
        manager.networkManagers["support"] = mock
        manager.authResults = [(channel: "support", auth: IQClientAuth(client: IQClient(), session: nil, analytics: nil))]
        return manager
    }

    private func waitUntil(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 6,
        _ message: String = "condition"
    ) -> Bool {
        let exp = expectation(description: message)
        func tick() {
            if condition() { exp.fulfill(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: tick)
        }
        tick()
        wait(for: [exp], timeout: timeout)
        return condition()
    }

    private func historyMessage(id: Int) -> IQMessage {
        var message = IQMessage(text: "history \(id)", chatType: .chat, clientID: 11, localID: 0, replyMessageID: nil)
        message.messageID = id
        return message
    }

    private func operatorMessage(id: Int) -> IQMessage {
        var message = IQMessage(text: "operator \(id)", operatorName: "Оператор", avatarID: nil, avatarURL: nil)
        message.messageID = id
        return message
    }

    private func dropConnection(mock: NetworkMock) {
        guard !mock.subscriptions.isEmpty else { return }
        mock.subscriptions.first?.callback(nil, NSError(domain: "test.sse", code: 1))
    }

    func testReconnectOpenMergesMissedOperatorMessage() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41), operatorMessage(id: 50)], false, nil, "", nil, nil)))

        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 1 }, "initial subscription"))

        dropConnection(mock: mock)
        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 2 }, timeout: 8, "reconnect subscription"))
        mock.subscriptions.last?.onOpen()

        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 50 } }, timeout: 5, "missed message merged"))
        XCTAssertEqual(mock.listenRequests.count, 2, "merge не должен рестартить SSE-подписку")
        XCTAssertEqual(mock.loadMessagesRequests.count, 2)
    }

    func testReconnectOpenConfirmsPendingByLocalId() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([], false, nil, "", nil, nil)))

        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 1 }, "initial subscription"))

        manager.sendMessage("привет", files: nil, replyToMessage: nil)
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 0 && $0.localID != nil } }, "pending row appended"))
        let localID = manager.messages.first { $0.messageID == 0 }?.localID
        guard let localID else {
            XCTFail("pending row has no localID")
            return
        }

        var echo = IQMessage(text: "привет", chatType: .chat, clientID: 11, localID: localID, replyMessageID: nil)
        echo.messageID = 42
        mock.enqueueLoadMessages(.init(result: ([echo], false, nil, "", nil, nil)))

        dropConnection(mock: mock)
        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 2 }, timeout: 8, "reconnect subscription"))
        mock.subscriptions.last?.onOpen()

        XCTAssertTrue(waitUntil(
            { manager.messages.first { $0.localID == localID }?.messageID == 42 },
            timeout: 5,
            "pending confirmed by merge"
        ))
        XCTAssertFalse(manager.messages.first { $0.localID == localID }?.error ?? true)
    }

    func testReplayedKnownMessageNotDuplicated() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 1 }, "initial subscription"))

        mock.subscriptions.first?.callback(
            [IQChatEvent(id: 1, type: .messageCreated, message: operatorMessage(id: 41))],
            nil
        )
        mock.subscriptions.first?.callback(
            [IQChatEvent(id: 2, type: .messageCreated, message: operatorMessage(id: 41))],
            nil
        )

        XCTAssertEqual(manager.messages.filter { $0.messageID == 41 }.count, 1)
    }

    func testFirstOpenDoesNotRefetchHistory() {
        let mock = NetworkMock()
        _ = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 1 }, "initial subscription"))
        mock.subscriptions.last?.onOpen()

        let settled = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
        wait(for: [settled], timeout: 2)

        XCTAssertEqual(mock.loadMessagesRequests.count, 1, "первый open не должен дублировать загрузку истории")
    }

    private func makeMultiChatManager(channelA: NetworkMock, channelB: NetworkMock) -> IQChannelsManager {
        let config = IQChannelsConfig(address: "http://127.0.0.1:1", channels: ["a", "b"])
        let manager = IQChannelsManager(configuration: config)
        manager.networkManagers["a"] = channelA
        manager.networkManagers["b"] = channelB
        manager.authResults = [
            (channel: "a", auth: IQClientAuth(client: IQClient(), session: nil, analytics: nil)),
            (channel: "b", auth: IQClientAuth(client: IQClient(), session: nil, analytics: nil))
        ]
        return manager
    }

    private func select(_ manager: IQChannelsManager, channel: String) {
        let auth = manager.authResults.first { $0.channel == channel }!
        manager.selectedChat = (auth, .chat)
    }

    private func settle(_ seconds: TimeInterval = 0.5) {
        let settled = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { settled.fulfill() }
        wait(for: [settled], timeout: seconds + 2)
    }

    func testStaleChatResponseDoesNotOverwriteCurrentChat() {
        let mockA = NetworkMock()
        let mockB = NetworkMock()
        let manager = makeMultiChatManager(channelA: mockA, channelB: mockB)
        settle(0.5)

        mockA.holdNextLoadMessages()
        mockB.holdNextLoadMessages()

        select(manager, channel: "a")
        XCTAssertTrue(waitUntil({ mockA.loadMessagesRequests.count == 1 }, "A requested"))

        select(manager, channel: "b")
        XCTAssertTrue(waitUntil({ mockB.loadMessagesRequests.count == 1 }, "B requested"))

        mockB.resolveHeldLoadMessages(.init(result: ([historyMessage(id: 50)], false, nil, "", nil, nil)))
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 50 } }, "B history shown"))

        mockA.resolveHeldLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))
        settle()

        XCTAssertEqual(
            manager.messages.map(\.messageID),
            [50],
            "поздний ответ старого чата не должен перезаписывать текущий"
        )
    }

    func testOldChannelEventDoesNotLeakIntoNewChat() {
        let mockA = NetworkMock()
        let mockB = NetworkMock()
        let manager = makeMultiChatManager(channelA: mockA, channelB: mockB)
        settle(0.5)

        mockA.enqueueLoadMessages(.init(result: ([], false, nil, "", nil, nil)))
        mockB.enqueueLoadMessages(.init(result: ([historyMessage(id: 50)], false, nil, "", nil, nil)))

        select(manager, channel: "a")
        XCTAssertTrue(waitUntil({ mockA.listenRequests.count == 1 }, "A subscribed"))

        select(manager, channel: "b")
        XCTAssertTrue(waitUntil({
            mockB.listenRequests.count == 1 && manager.messages.contains { $0.messageID == 50 }
        }, "B shown and subscribed"))

        mockA.emit([IQChatEvent(id: 1, type: .messageCreated, message: operatorMessage(id: 41))])
        settle()

        XCTAssertFalse(
            manager.messages.contains { $0.messageID == 41 },
            "события SSE старого канала не должны попадать в новый чат"
        )
    }

    func testRefreshInFlightForOldChatDoesNotWriteAfterSwitch() {
        let mockA = NetworkMock()
        let mockB = NetworkMock()
        let manager = makeMultiChatManager(channelA: mockA, channelB: mockB)
        settle(0.5)

        mockA.enqueueLoadMessages(.init(result: ([], false, nil, "", nil, nil)))
        mockB.enqueueLoadMessages(.init(result: ([historyMessage(id: 60)], false, nil, "", nil, nil)))

        select(manager, channel: "a")
        XCTAssertTrue(waitUntil({ mockA.listenRequests.count == 1 }, "A subscribed"))

        dropConnection(mock: mockA)
        XCTAssertTrue(waitUntil({ mockA.listenRequests.count == 2 }, timeout: 8, "A reconnected"))

        mockA.holdNextLoadMessages()
        mockA.subscriptions.last?.onOpen()
        XCTAssertTrue(waitUntil({ mockA.loadMessagesRequests.count == 2 }, "A refresh in flight"))

        select(manager, channel: "b")
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 60 } }, "B shown"))

        mockA.resolveHeldLoadMessages(.init(result: ([operatorMessage(id: 41)], false, nil, "", nil, nil)))
        settle()

        XCTAssertFalse(manager.messages.contains { $0.messageID == 41 })
        XCTAssertTrue(manager.messages.contains { $0.messageID == 60 })
    }

    func testChatSwitchDuringHistoryPrefetchDoesNotOverwriteCurrentChat() {
        let mockA = NetworkMock()
        let mockB = NetworkMock()
        let manager = makeMultiChatManager(channelA: mockA, channelB: mockB)
        settle(0.5)

        var imageMessage = historyMessage(id: 41)
        var file = IQFile(dataFile: .init(data: Data([1]), filename: "photo.image.jpeg"))
        file.id = "file-41"
        file.url = URL(string: "http://10.255.255.1/f.png")
        file.imagePreviewUrl = URL(string: "http://10.255.255.1/preview.png")
        imageMessage.file = file

        mockA.enqueueLoadMessages(.init(result: ([imageMessage], false, nil, "", nil, nil)))
        mockB.enqueueLoadMessages(.init(result: ([historyMessage(id: 50)], false, nil, "", nil, nil)))

        mockA.holdNextLoadMessages()
        select(manager, channel: "a")
        XCTAssertTrue(waitUntil({ mockA.loadMessagesRequests.count == 1 }, "A requested"))
        mockA.resolveHeldLoadMessages(.init(result: ([imageMessage], false, nil, "", nil, nil)))
        settle(0.3)

        select(manager, channel: "b")
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 50 } }, "B shown"))

        settle(4.0)

        XCTAssertEqual(
            manager.messages.map(\.messageID),
            [50],
            "prefetch старого чата не должен перезаписывать текущий"
        )
    }

    func testChatSwitchDuringUnsentFlushDoesNotInsertOldChatMessages() {
        let mockA = NetworkMock()
        let mockB = NetworkMock()
        let manager = makeMultiChatManager(channelA: mockA, channelB: mockB)
        settle(0.5)

        IQDatabaseManager.shared.getAllMessages()
            .filter { $0.messageID == 0 && $0.author == "\"client\"" }
            .forEach { IQDatabaseManager.shared.deleteMessageByLocalId($0.localID ?? 0) }

        var pending = IQMessage(text: "pending", chatType: .chat, clientID: 0, localID: 910_001, replyMessageID: nil)
        pending.createdAt = 1
        IQDatabaseManager.shared.insertMessage(pending.toDatabaseMessage())
        defer { IQDatabaseManager.shared.deleteMessageByLocalId(910_001) }

        mockA.enqueueLoadMessages(.init(result: ([], false, nil, "", nil, nil)))
        mockA.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))
        mockB.enqueueLoadMessages(.init(result: ([historyMessage(id: 50)], false, nil, "", nil, nil)))

        select(manager, channel: "a")
        XCTAssertTrue(waitUntil({ mockA.listenRequests.count == 1 }, "A subscribed"))

        mockA.holdNextSendMessage()
        manager.loadOldMessages()
        XCTAssertTrue(waitUntil({ mockA.loadMessagesRequests.count == 2 }, "old page requested"))
        settle(0.3)

        select(manager, channel: "b")
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 50 } }, "B shown"))

        mockA.resolveHeldSends(nil)
        settle()

        XCTAssertEqual(manager.messages.first?.messageID, 50, "старые сообщения не должны вставляться в новый чат")
        XCTAssertFalse(manager.messages.contains { $0.messageID == 41 })
    }

    func testLiveSseMessageDuringMergeRequestSurvivesMerge() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 1 }, "initial subscription"))

        dropConnection(mock: mock)
        XCTAssertTrue(waitUntil({ mock.listenRequests.count == 2 }, timeout: 8, "reconnected"))

        mock.holdNextLoadMessages()
        mock.subscriptions.last?.onOpen()
        XCTAssertTrue(waitUntil({ mock.loadMessagesRequests.count == 2 }, "merge in flight"))

        mock.emit([IQChatEvent(id: 3, type: .messageCreated, message: operatorMessage(id: 77))])
        XCTAssertTrue(waitUntil({ manager.messages.contains { $0.messageID == 77 } }, "live message shown"))

        mock.resolveHeldLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        settle()
        XCTAssertTrue(
            manager.messages.contains { $0.messageID == 77 },
            "merge не должен затирать живые SSE-сообщения"
        )
    }
}

