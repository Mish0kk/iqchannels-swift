//
//  IQClientAuth.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 10.05.2024.
//

import Foundation

struct IQClientAuth: Decodable {
    var client: IQClient?
    var session: IQClientSession?
    var analytics: IQAnalyticsConfig?
}

