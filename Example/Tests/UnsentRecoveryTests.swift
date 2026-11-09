import XCTest
@testable import IQChannelsSwift

final class UnsentRecoveryTests: XCTestCase {

    private final class NetworkMock: IQNetworkManagerProtocol {
        var token: String?

        var sendMessageResult: ((IQMessageForm) -> Error?)?
        private(set) var sentForms: [IQMessageForm] = []
        private(set) var listenRequests: [IQListenEventsRequest] = []
        var onOpenHandler: (() -> Void)?
        private(set) var resetSessionCalls = 0

        func isConnectedToEvents() -> Bool { true }
        func setCustomHeaders(_ headers: [String: String]) {}
        func resetSessionIfNeeded() { resetSessionCalls += 1 }
        func cancelTask(with taskIdentifier: Int) {}

        func listenToEvents(
            request: IQListenEventsRequest,
            onOpen: @escaping (() -> Void),
            callback: @escaping ResponseCallbackClosure<[IQChatEvent]>
        ) {
            listenRequests.append(request)
            onOpenHandler = onOpen
        }

        func listenToAdvancedUnread(callback: @escaping ResponseCallbackClosure<IQAdvancedUnreadResult>) {}
        func stopListenToEvents() {}
        func stopListenToAdvancedUnread() {}
        func pushToken(token: String) async -> Error? { nil }
        func sendReceivedEvent(_ messageIDs: [Int]) async -> Error? { nil }
        func sendReadEvent(_ messageIDs: [Int]) async -> Error? { nil }
        func sendTypingEvent() async -> Error? { nil }
        func sendAnalyticsEvent(_ event: IQAnalyticsEvent) async -> ResponseCallback<IQResult<IQEmptyResponse>> { .init() }
        func getFile(id: String) async throws -> IQFile? { nil }
        func loadMessages(request: IQLoadMessageRequest, getSettings: Bool, isInfoChat: Bool, language: String?) async -> ResponseCallback<([IQMessage], Bool, Int?, String, [IQLanguage]?, String?)> {
            .init(result: ([], false, nil, "", nil, nil))
        }
        func getBlocker() async -> ResponseCallback<IQInfoChatSettings> { .init() }
        func rate(value: Int, ratingID: Int) async -> Error? { nil }
        func sendPoll(request: IQSendPollRequest) async -> Error? { nil }
        func finishPoll(ratingId: Int, pollId: Int, rated: Bool) async -> Error? { nil }
        func uploadFile(file: DataFile, taskIdentifierCallback: TaskIdentifierCallback?) async -> ResponseCallback<IQFile> { .init() }
        func sendMessage(form: IQMessageForm) async -> Error? {
            sentForms.append(form)
            return sendMessageResult?(form) ?? nil
        }
        func acceptProduct(form: IQProductForm) async -> Error? { nil }
        func declineProduct(form: IQProductForm) async -> Error? { nil }
        func clientsAuth(token: String) async -> ResponseCallback<IQClientAuth> { .init() }
        func clientsSignup() async -> ResponseCallback<IQClientAuth> { .init() }
        func clientsIntegrationAuth(credentials: String) async -> ResponseCallback<IQClientAuth> { .init() }
        func getSignupGreetingSettings() async -> ResponseCallback<IQGreetingSettings> { .init() }
        func setLanguage(languageCode: String) async -> Error? { nil }
        func getAvailableLanguages() async -> ResponseCallback<[IQLanguage]> { .init() }
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

    private func waitForChatSelection() {
        let selected = expectation(description: "selectedChat settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { selected.fulfill() }
        wait(for: [selected], timeout: 2)
    }

    private func makeStuckMessage(localID: Int, text: String) -> IQMessage {
        var message = IQMessage(text: text, chatType: .chat, channel: nil, clientID: 11, localID: localID, replyMessageID: nil)
        message.messageID = 0
        message.error = true
        return message
    }

    private func makeStuckMessage(localID: Int, text: String, chatType: IQChatType, channel: String) -> IQMessage {
        var message = IQMessage(text: text, chatType: chatType, channel: channel, clientID: 11, localID: localID, replyMessageID: nil)
        message.messageID = 0
        message.error = true
        return message
    }

    func testUnsentMessageFromOtherChatIsNotSentThroughCurrentChat() {
        let regularMock = NetworkMock()
        let pmMock = NetworkMock()
        let config = IQChannelsConfig(address: "http://127.0.0.1:1", channels: ["regular", "pm"])
        let manager = IQChannelsManager(configuration: config)
        manager.networkManagers["regular"] = regularMock
        manager.networkManagers["pm"] = pmMock
        let auth = IQClientAuth(client: IQClient(), session: nil, analytics: nil)
        manager.authResults = [
            (channel: "regular", auth: auth),
            (channel: "pm", auth: auth),
        ]

        waitForChatSelection()
        manager.selectedChat = ((channel: "regular", auth: auth), .chat)

        manager.unsentMessages = [
            makeStuckMessage(localID: 301, text: "pm-failed", chatType: .manager, channel: "pm"),
        ]

        manager.networkStatusChanged(.reachable)

        let flushed = expectation(description: "pm message flushed via own channel")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { flushed.fulfill() }
        wait(for: [flushed], timeout: 5)

        XCTAssertEqual(
            pmMock.sentForms.map(\.localId),
            [301],
            "Упавшее pm-сообщение должно уйти через менеджер своего канала"
        )
        XCTAssertEqual(
            regularMock.sentForms.count,
            0,
            "Неотправленное сообщение pm-чата не должно переотправляться через текущий обычный чат"
        )
        XCTAssertTrue(manager.unsentMessages.isEmpty)
    }

    func testNetworkRecoveryFlushesUnsentQueueInOrder() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        waitForChatSelection()
        manager.unsentMessages = [
            makeStuckMessage(localID: 101, text: "offline-1"),
            makeStuckMessage(localID: 102, text: "offline-2"),
        ]

        manager.networkStatusChanged(.reachable)

        let flushed = expectation(description: "unsent queue flushed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { flushed.fulfill() }
        wait(for: [flushed], timeout: 5)

        XCTAssertEqual(
            mock.sentForms.map(\.localId),
            [101, 102],
            "После возврата сети unsent-очередь должна уйти целиком в порядке createdDate (SDK-703)"
        )
        XCTAssertEqual(
            mock.sentForms.map { $0.text ?? "" },
            ["offline-1", "offline-2"]
        )
        XCTAssertTrue(
            manager.unsentMessages.isEmpty,
            "После успешной доставки очередь unsent должна опустеть"
        )
    }

    func testSseOpenDuringFlushDoesNotDuplicateSends() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        waitForChatSelection()
        manager.unsentMessages = [makeStuckMessage(localID: 201, text: "stuck")]

        manager.networkStatusChanged(.reachable)

        let sseOpened = expectation(description: "sse listener started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mock.onOpenHandler?()
            sseOpened.fulfill()
        }
        wait(for: [sseOpened], timeout: 3)

        let settled = expectation(description: "flush settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { settled.fulfill() }
        wait(for: [settled], timeout: 4)

        XCTAssertEqual(
            mock.sentForms.filter { $0.localId == 201 }.count,
            1,
            "SSE onOpen и networkStatusChanged не должны дублировать отправку одного unsent-сообщения"
        )
    }

    func testReachableResetsOwnedSessions() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        waitForChatSelection()

        manager.networkStatusChanged(.notReachable)
        manager.networkStatusChanged(.reachable)

        let reset = expectation(description: "session reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { reset.fulfill() }
        wait(for: [reset], timeout: 2)

        XCTAssertGreaterThanOrEqual(
            mock.resetSessionCalls, 1,
            "При возврате сети собственная URLSession должна пересоздаваться (сброс протухшего DNS/path-кэша)"
        )
    }

    func testNewMessagesSendAfterRecovery() {
        let mock = NetworkMock()
        let manager = makeManager(mock: mock)
        waitForChatSelection()

        manager.networkStatusChanged(.reachable)

        let recovered = expectation(description: "recovery cycle finished")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { recovered.fulfill() }
        wait(for: [recovered], timeout: 3)

        manager.sendMessage("после-восстановления", files: nil, replyToMessage: nil)

        let sent = expectation(description: "new message sent")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { sent.fulfill() }
        wait(for: [sent], timeout: 3)

        XCTAssertEqual(
            mock.sentForms.map { $0.text ?? "" },
            ["после-восстановления"],
            "Новые сообщения после возврата сети должны отправляться штатно (SDK-703)"
        )
        XCTAssertTrue(manager.unsentMessages.isEmpty)
    }
}
