//
//  NSError+.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 10.05.2024.
//

import Foundation

extension NSError {
    
    static let IQErrorDomain = "ru.iqstore.iqchannels"
    static let IQErrorUserInfoKey = "ru.iqstore.error"
    static let IQErrorHTTPStatusCodeKey = "ru.iqstore.http_status_code"

    static let IQErrorAppError = 2
    static let IQErrorClientError = 3
    
    convenience init(_ error: IQError?) {
        let text = error?.text ?? NSLocalizedString("Unknown error", comment: "")
        let userInfo = [
            NSLocalizedDescriptionKey: text,
            NSError.IQErrorUserInfoKey: error as Any
        ] as [String : Any]
        self.init(domain: NSError.IQErrorDomain, code: NSError.IQErrorAppError, userInfo: userInfo)
    }

    class func clientError(_ text: String? = nil) -> NSError {
        let descriptionText = text ?? NSLocalizedString("Client error", comment: "")
        return NSError(domain: IQErrorDomain, code: IQErrorClientError, userInfo: [NSLocalizedDescriptionKey: descriptionText])
    }

    class func httpError(statusCode: Int, iqError: IQError?) -> NSError {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode),
            NSError.IQErrorHTTPStatusCodeKey: statusCode
        ]
        if let iqError {
            userInfo[NSError.IQErrorUserInfoKey] = iqError
        }
        return NSError(domain: IQErrorDomain, code: IQErrorClientError, userInfo: userInfo)
    }
    
    class func failedToParseModel(_ model: Any.Type) -> NSError {
        return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse model: \(String(describing: model))"])
    }
    
    static var internetError: NSError {
        return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Отсутствует соединение с сетью. Пожалуйста, проверьте ваше интернет-соединение и попробуйте снова."])
    }
    
}
