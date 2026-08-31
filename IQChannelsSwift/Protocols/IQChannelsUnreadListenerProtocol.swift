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
    public var channels: [Channel]? = nil
}

public struct Channel: Decodable, Equatable {
    public var name: String? = nil
    public var chatType: String? = nil
    public var lastMessage: LastMessage? = nil
    public var unreadCount: Int? = nil
}

public struct LastMessage: Decodable, Equatable {
    public var text: String? = nil
    public var fileID: String? = nil
    public var isSurvey: Bool? = nil
    public var date: String? = nil
}

public struct IQAdvancedUnreadResult: Decodable, Equatable {
    public var id: Int? = nil
    public var type: String? = nil
    public var name: String? = nil
    public var lastMessage: LastMessage? = nil
    public var unreadCount: Int? = nil
}
