import XCTest
@testable import IQChannelsSwift

final class MessageRecoveryTests: XCTestCase {

    func testEventsQueryDoesNotResumeFromLocalEventIds() {
        let query = IQChannelsManager.eventsQuery(chatType: .chat)

        XCTAssertNil(
            query.lastEventID,
            "LastEventId из локальных eventID глушит события после рестарта сервера (SDK-703)"
        )
        XCTAssertEqual(query.chatType, IQChatType.chat)
    }

    func testMergedClearsErrorAndSetsServerIdentity() {
        var local = IQMessage(text: "привет", chatType: .chat, clientID: 11, localID: 42, replyMessageID: nil)
        local.error = true
        var server = local
        server.messageID = 1785

        let merged = local.merged(with: server)

        XCTAssertEqual(merged.messageID, 1785)
        XCTAssertFalse(merged.error, "серверное эхо подтверждает отправку — ошибка должна сбрасываться")
        XCTAssertEqual(merged.id, local.id, "UI-идентичность сообщения должна сохраниться")
        XCTAssertEqual(merged.localID, 42)
    }

    func testWithErrorPreservesMessageIdForUnsentBookkeeping() {
        var message = IQMessage(text: "x", chatType: .chat, clientID: 11, localID: 7, replyMessageID: nil)
        message.error = true

        let cleared = message.withError(false)

        XCTAssertEqual(cleared.id, message.id, "очистка ошибки не должна менять id — по нему unsentMessages.removeAll")
        XCTAssertFalse(cleared.error)
    }

    func testMergeReplacesUnsentLocalMessageWithServerCopy() {
        var local = IQMessage(text: "off1", chatType: .chat, clientID: 11, localID: 100, replyMessageID: nil)
        local.error = true
        var server = local
        server.messageID = 1785

        let merged = IQChannelsManager.mergeMessages([local], with: [server])

        XCTAssertEqual(merged.count, 1, "серверная копия замещает локальную, а не дублируется")
        XCTAssertEqual(merged[0].messageID, 1785)
        XCTAssertFalse(merged[0].error)
        XCTAssertEqual(merged[0].id, local.id)
    }

    func testMergeAppendsServerMessageWithoutLocalPair() {
        let local = IQMessage(text: "hi", chatType: .chat, clientID: 11, localID: 100, replyMessageID: nil)
        var server = IQMessage(
            text: "ответ оператора", chatType: .chat, clientID: 11, localID: 101, replyMessageID: nil
        )
        server.messageID = 1786
        server.author = .user

        let merged = IQChannelsManager.mergeMessages([local], with: [server])

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged.last?.messageID, 1786)
    }

    func testMergeIgnoresServerMessageWithoutLocalID() {
        let local = IQMessage(text: "hi", chatType: .chat, clientID: 11, localID: 100, replyMessageID: nil)
        var server = IQMessage(text: "без localID", chatType: .chat, clientID: 11, localID: 101, replyMessageID: nil)
        server.localID = nil
        server.messageID = 1787
        server.author = .user

        let merged = IQChannelsManager.mergeMessages([local], with: [server])

        XCTAssertEqual(merged.count, 2, "серверное сообщение без localID не должно подменять локальные")
        XCTAssertEqual(merged.last?.messageID, 1787)
    }

    func testMergeKeepsMessagesSortedByCreatedDate() {
        var old = IQMessage(text: "старое", chatType: .chat, clientID: 11, localID: 100, replyMessageID: nil)
        old.createdAt = 1000
        old.messageID = 1700
        var local = IQMessage(
            text: "новое неотправленное", chatType: .chat, clientID: 11, localID: 200, replyMessageID: nil
        )
        local.createdAt = 3000
        local.error = true
        var serverEcho = local
        serverEcho.messageID = 1785

        let merged = IQChannelsManager.mergeMessages([local, old], with: [serverEcho])

        XCTAssertEqual(merged.map { $0.messageID }, [1700, 1785])
        XCTAssertEqual(merged.map { $0.localID }, [100, 200])
    }
}
