//
//  IQChatType.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 17.05.2024.
//

import Foundation

public enum IQChatType: String, Codable, Equatable {
    case manager = "personal_manager"
    case chat = "regular"
    case info
}
