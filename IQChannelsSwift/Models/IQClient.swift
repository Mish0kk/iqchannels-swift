//
//  IQClient.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 10.05.2024.
//

import Foundation

struct IQClient: Equatable, Codable {
    var id: Int = 0
    var name: String?
    var integrationID: String?
    var personalManagerID: Int?
    var personalManagerGroupID: Int?
    var multiChatsInfo: IQMultiChatsInfo?
    var projectID: Int?
    var crmClientID: String?
    var channelID: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case integrationID
        case personalManagerID
        case personalManagerGroupID
        case multiChatsInfo
        case projectID
        case crmClientID = "cRMClientID"
        case channelID
    }
    
    var canAccessPersonalManager: Bool {
//        (personalManagerID != nil || personalManagerGroupID != nil) && (multiChatsInfo?.enableForPersonalManagers ?? false)
        
        personalManagerID != nil || personalManagerGroupID != nil
    }
    
    var chatTypes: [IQChatType] {
        guard let multiChatsInfo else { return [.chat] }
        
        if(multiChatsInfo.channelType == "info"){
            return [.info]
        } else {
            return (canAccessPersonalManager) ? [.manager] : [.chat]
        }
    }
}
