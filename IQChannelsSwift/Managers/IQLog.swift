//
//  IQLog.swift
//  IQChannelsSwift
//
//  Created by Mikhail Zinkov on 02.11.2024.
//

import SwiftUI
import OSLog

class IQLog {
    private static var isLoggingEnabled = true

    static func configure(state: Bool) {
        isLoggingEnabled = state
    }
    
    // Method for logging debug messages
    static func debug(message: String) {
        if isLoggingEnabled {
            os_log("%{public}s", type: .debug, "[DEBUG]: \(message)")
        }
    }
    
    // Method for logging error messages
    static func error(message: String) {
        if isLoggingEnabled {
            os_log("%{public}s", type: .error, "[ERROR]: \(message)")
        }
    }

    // Method for logging warnings
    static func warn(message: String) {
        if isLoggingEnabled {
            os_log("%{public}s", type: .default, "[WARN]: \(message)")
        }
    }
}
