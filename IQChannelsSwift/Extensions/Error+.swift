//
//  Error+.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 11.05.2024.
//

import Foundation

extension Error {
    
    var iqIsAuthError: Bool {
        guard iqAppError != nil else {
            return false
        }

        if let error = iqAppError, error.code == .unauthorized {
            return true
        }

        return false
    }

    var iqAppError: IQError? {
        return (self as NSError).userInfo["ru.iqstore.error"] as? IQError
    }

    var iqHTTPStatusCode: Int? {
        return (self as NSError).userInfo[NSError.IQErrorHTTPStatusCodeKey] as? Int
    }

    var iqErrorCode: String? {
        return iqAppError?.code?.rawValue
    }
}
