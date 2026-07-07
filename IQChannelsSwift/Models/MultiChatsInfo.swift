//
//  MultiChatsInfo.swift
//  Pods
//
//  Created by Muhammed Aralbek on 16.05.2024.
//  
//

import Foundation

struct IQMultiChatsInfo: Equatable, Codable {
    var personalManagerName: String?
    var channelName: String?
    var channelIconColor: String?
    var enableForPersonalManagers: Bool?
    var enableChat: Bool?
    var channelType: String?
}
