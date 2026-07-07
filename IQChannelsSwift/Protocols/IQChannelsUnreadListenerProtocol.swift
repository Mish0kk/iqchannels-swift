//
//  IQChannelsUnreadListenerProtocol.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 24.05.2024.
//

import Foundation

@MainActor
public protocol IQChannelsUnreadListenerProtocol: AnyObject {
    var id: String { get }
    func iqChannelsUnreadDidChange(_ unread: Int)
}

@MainActor
public protocol IQChannelsAdvancedUnreadListenerProtocol: AnyObject {
    var id: String { get }
    func iqChannelsAdvancedUnreadDidChange(_ unread: IQAdvancedUnread)
    func iqChannelsAdvancedUnreadException(_ e: Error)
}


public struct IQAdvancedUnread: Decodable, Equatable {
    var channels: [Channel]? = nil
}

public struct Channel: Decodable, Equatable {
    var name: String? = nil
    var chatType: String? = nil
    var lastMessage: LastMessage? = nil
    var unreadCount: Int? = nil
}

public struct LastMessage: Decodable, Equatable {
    var text: String? = nil
    var fileID: String? = nil
    var isSurvey: Bool? = nil
    var date: String? = nil
}

public struct IQAdvancedUnreadResult: Decodable, Equatable {
    var id: Int? = nil
    var type: String? = nil
    var name: String? = nil
    var lastMessage: LastMessage? = nil
    var unreadCount: Int? = nil
}
