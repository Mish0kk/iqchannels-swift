//
//  IQGreetingSettings.swift
//  Pods
//
//  Created by Mikhail Zinkov on 06.06.2026.
//

struct IQGreetingSettings: Codable, Equatable {
    var greeting: String? = ""
    var greetingBold: String? = ""
//    var personalDataRequestType: DataRequestType = DataRequestType.default
    var channelType: String? = ""
}

public enum DataRequestType: String, Codable, Equatable {
    case `default`
    case fullForm = "full_form"
    case info
    case none
}
