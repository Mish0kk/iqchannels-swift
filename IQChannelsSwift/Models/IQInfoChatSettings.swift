//
//  IQInfoChatSettings.swift
//  IQChannelsSwift
//
//  Created by Mikhail Zinkov on 25.05.2026.
//

import Foundation
import SwiftUI

struct IQInfoChatSettings: Decodable {
    let blockerText: String?
    let blockerIcon: URL?
}

struct IQInfoChatSettingsResponse: Decodable {
    let text: String?
    let blockerFileID: String?
}
