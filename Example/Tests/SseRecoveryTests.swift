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

        func enqueueLoadMessages(_ result: ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)>) {
            loadMessagesResults.append(result)
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
    ) {
        let exp = expectation(description: message)
        func tick() {
            if condition() { exp.fulfill(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: tick)
        }
        tick()
        wait(for: [exp], timeout: timeout)
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
        mock.subscriptions[0].callback(nil, NSError(domain: "test.sse", code: 1))
    }

    func testReconnectOpenMergesMissedOperatorMessage() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41), operatorMessage(id: 50)], false, nil, "", nil, nil)))

        waitUntil({ mock.listenRequests.count == 1 }, "initial subscription")

        dropConnection(mock: mock)
        waitUntil({ mock.listenRequests.count == 2 }, timeout: 8, "reconnect subscription")
        mock.subscriptions.last?.onOpen()

        waitUntil({ manager.messages.contains { $0.messageID == 50 } }, timeout: 5, "missed message merged")
        XCTAssertEqual(mock.listenRequests.count, 2, "merge не должен рестартить SSE-подписку")
        XCTAssertEqual(mock.loadMessagesRequests.count, 2)
    }

    func testReconnectOpenConfirmsPendingByLocalId() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([], false, nil, "", nil, nil)))

        waitUntil({ mock.listenRequests.count == 1 }, "initial subscription")

        manager.sendMessage("привет", files: nil, replyToMessage: nil)
        waitUntil({ manager.messages.contains { $0.messageID == 0 && $0.localID != nil } }, "pending row appended")
        let localID = manager.messages.first { $0.messageID == 0 }?.localID

        var echo = IQMessage(text: "привет", chatType: .chat, clientID: 11, localID: localID!, replyMessageID: nil)
        echo.messageID = 42
        mock.enqueueLoadMessages(.init(result: ([echo], false, nil, "", nil, nil)))

        dropConnection(mock: mock)
        waitUntil({ mock.listenRequests.count == 2 }, timeout: 8, "reconnect subscription")
        mock.subscriptions.last?.onOpen()

        waitUntil(
            { manager.messages.first { $0.localID == localID }?.messageID == 42 },
            timeout: 5,
            "pending confirmed by merge"
        )
        XCTAssertFalse(manager.messages.first { $0.localID == localID }?.error ?? true)
    }

    func testReplayedKnownMessageNotDuplicated() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        waitUntil({ mock.listenRequests.count == 1 }, "initial subscription")

        mock.subscriptions[0].callback(
            [IQChatEvent(id: 1, type: .messageCreated, message: operatorMessage(id: 41))],
            nil
        )
        mock.subscriptions[0].callback(
            [IQChatEvent(id: 2, type: .messageCreated, message: operatorMessage(id: 41))],
            nil
        )

        XCTAssertEqual(manager.messages.filter { $0.messageID == 41 }.count, 1)
    }

    func testFirstOpenDoesNotRefetchHistory() {
        let mock = NetworkMock()
        _ = makeManager(mock: mock)
        mock.enqueueLoadMessages(.init(result: ([historyMessage(id: 41)], false, nil, "", nil, nil)))

        waitUntil({ mock.listenRequests.count == 1 }, "initial subscription")
        mock.subscriptions[0].onOpen()

        let settled = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
        wait(for: [settled], timeout: 2)

        XCTAssertEqual(mock.loadMessagesRequests.count, 1, "первый open не должен дублировать загрузку истории")
    }
}

