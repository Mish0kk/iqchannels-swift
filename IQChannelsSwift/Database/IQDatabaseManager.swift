//
//  IQDatabaseManager.swift
//  Pods
//
//  Created by Mikhail Zinkov on 27.12.2024.
//

import SQLite
import Foundation

class IQDatabaseManager {
    static let shared = IQDatabaseManager()
    private var db: Connection!
    
    typealias Expression = SQLite.Expression

    private let messages = Table("messages")
    private let uid = Expression<Int>("uid")
    private let messageID = Expression<Int>("messageId")
    private let localID = Expression<Int?>("localId")
    private let fileID = Expression<String?>("fileId")
    private let chatID = Expression<Int?>("chatId")
    private let createdAt = Expression<Int?>("createdAt")
    private let userID = Expression<Int?>("userId")
    private let clientID = Expression<Int?>("clientId")
    private let ratingID = Expression<Int?>("ratingId")
    private let payload = Expression<String?>("payload")
    private let text = Expression<String?>("text")
    private let author = Expression<String?>("author")
    private let isRead = Expression<Bool?>("isRead")
    private let replyToMessageID = Expression<Int?>("replyToMessageId")
    private let botpressPayload = Expression<String?>("botpressPayload")
    private let isDropDown = Expression<Bool?>("isDropDown")
    private let disableFreeText = Expression<Bool?>("disableFreeText")
    private let isSystem = Expression<Bool?>("isSystem")
    private let actions = Expression<String?>("actions")
    private let singleChoices = Expression<String?>("singleChoices")
    private let chatType = Expression<String?>("chatType")
    private let eventID = Expression<Int?>("eventId")
    private let client = Expression<String?>("client")
    private let user = Expression<String?>("user")
    private let file = Expression<String?>("file")
    private let rating = Expression<String?>("rating")
    private let upload = Expression<String?>("upload")
    private let error = Expression<Bool>("error")
    private let transferToChannel = Expression<String?>("transferToChannel")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/iq_database.sqlite3")

            try db.run(messages.create(ifNotExists: true) { t in
                t.column(uid, primaryKey: .autoincrement)
                t.column(messageID)
                t.column(localID, unique: true)
                t.column(fileID)
                t.column(chatID)
                t.column(createdAt)
                t.column(userID)
                t.column(clientID)
                t.column(ratingID)
                t.column(payload)
                t.column(text)
                t.column(author)
                t.column(isRead)
                t.column(replyToMessageID)
                t.column(botpressPayload)
                t.column(isDropDown)
                t.column(disableFreeText)
                t.column(isSystem)
                t.column(actions)
                t.column(singleChoices)
                t.column(chatType)
                t.column(eventID)
                t.column(client)
                t.column(user)
                t.column(file)
                t.column(rating)
                t.column(upload)
                t.column(error)
                t.column(transferToChannel)
            })
            IQLog.debug(message: "Initializing database")
            
            checkColumns()
        } catch {
            IQLog.error(message: "Error initializing database: \(error)")
        }
    }
    
    func checkColumns() {
        do {
            let checkColumnExists = try db.scalar("""
               SELECT COUNT(*)
               FROM pragma_table_info('messages')
               WHERE name = 'error'
            """) as! Int64

            if checkColumnExists == 0 {
                do {
                    try db.run(messages.addColumn(error, defaultValue: false))
                } catch {
                    IQLog.error(message: "Error add columns: \(error)")
                }
            }
        } catch {
            IQLog.error(message: "Error check columns: \(error)")
        }
        
        do {
            let checkColumnExists = try db.scalar("""
               SELECT COUNT(*)
               FROM pragma_table_info('messages')
               WHERE name = 'transferToChannel'
            """) as! Int64

            if checkColumnExists == 0 {
                do {
                    try db.run(messages.addColumn(transferToChannel, defaultValue: nil))
                } catch {
                    IQLog.error(message: "Error add columns: \(error)")
                }
            }
        } catch {
            IQLog.error(message: "Error check columns: \(error)")
        }
    }
    
    private func parseMessage(_ message: Row) -> IQDatabaseMessage {
        return IQDatabaseMessage(
            uid: message[uid],
            messageID: message[messageID],
            localID: message[localID],
            fileID: message[fileID],
            chatID: message[chatID],
            createdAt: message[createdAt],
            userID: message[userID],
            clientID: message[clientID],
            ratingID: message[ratingID],
            payload: message[payload],
            text: message[text],
            author: message[author],
            isRead: message[isRead],
            replyToMessageID: message[replyToMessageID],
            botpressPayload: message[botpressPayload],
            isDropDown: message[isDropDown],
            disableFreeText: message[disableFreeText],
            isSystem: message[isSystem],
            actions: message[actions],
            singleChoices: message[singleChoices],
            chatType: message[chatType],
            eventID: message[eventID],
            client: message[client],
            user: message[user],
            file: message[file],
            rating: message[rating],
            upload: message[upload],
            error: message[error],
            transferToChannel: message[transferToChannel]
        )
    }
    
    
    func insertMessage(_ message: IQDatabaseMessage) {
        if(message.localID != 0){
            do {
                try db.run(messages.insert(or: .replace,
                   messageID <- message.messageID,
                   localID <- message.localID,
                   fileID <- message.fileID,
                   chatID <- message.chatID,
                   createdAt <- message.createdAt,
                   userID <- message.userID,
                   clientID <- message.clientID,
                   ratingID <- message.ratingID,
                   payload <- message.payload,
                   text <- message.text,
                   author <- message.author,
                   isRead <- message.isRead,
                   replyToMessageID <- message.replyToMessageID,
                   botpressPayload <- message.botpressPayload,
                   isDropDown <- message.isDropDown,
                   disableFreeText <- message.disableFreeText,
                   isSystem <- message.isSystem,
                   actions <- message.actions,
                   singleChoices <- message.singleChoices,
                   chatType <- message.chatType,
                   eventID <- message.eventID,
                   client <- message.client,
                   user <- message.user,
                   file <- message.file,
                   rating <- message.rating,
                   upload <- message.upload,
                   error <- message.error,
                   transferToChannel <- message.transferToChannel
                  ))
                IQLog.debug(message: "Inserted message to database  \(message)")
            } catch {
                IQLog.error(message: "Error inserting message: \(error)")
            }
        }
    }

    func getAllMessages() -> [IQDatabaseMessage] {
        var messagesArray: [IQDatabaseMessage] = []
        do {
            for message in try db.prepare(messages) {
                messagesArray.append(parseMessage(message))
            }
        } catch {
            IQLog.error(message: "Error retrieving all messages: \(error)")
        }
        return messagesArray
    }
    
    func getMessageById(_ messageIdValue: Int) -> IQDatabaseMessage? {
        do {
           let query = messages.filter(messageID == messageIdValue)

           if let row = try db.pluck(query) {
               let message = parseMessage(row)
               IQLog.debug(message: "getMessageById \(messageIdValue)")
               return message
           }
       } catch {
           IQLog.error(message: "Error getting message by id: \(error)")
       }

       return nil
    }

    func deleteMessageByLocalId(_ localIdValue: Int) -> Bool {
        do {
            let query = messages.filter(localID == localIdValue)
            if try db.run(query.delete()) > 0 {
                IQLog.debug(message: "DeleteMessageByLocalId \(localIdValue)")
                return true
            }
        } catch {
            IQLog.error(message: "Error deleting message by localId: \(error)")
        }
        return false
    }

    func deleteMessageByChatId(_ chatIdValue: Int?) -> Bool {
        do {
            let query = messages.filter(chatID == chatIdValue)
            if try db.run(query.delete()) > 0 {
                IQLog.debug(message: "DeleteMessageByChatId \(chatIdValue)")
                return true
            }
        } catch {
            IQLog.error(message: "Error deleting messages by chatId: \(error)")
        }
        return false
    }
    
    func readMessageByChatId(_ chatIdValue: Int?) {
        do {
           try db.run(messages.filter(chatID == chatIdValue).update(isRead <- true))
            IQLog.debug(message: "ReadMessageByChatId \(chatIdValue)")
        } catch {
            IQLog.error(message: "Error reading messages by chatId: \(error)")
        }
    }
}
