//
//  IQNetworkManager+Extensions.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 27.05.2024.
//

import Foundation

extension IQNetworkManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping
    (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(
            .useCredential,
            URLCredential(trust: serverTrust)
        )
    }
    
    func sse<T: Decodable>(path: String, responseType: T.Type, onOpen: @escaping (() -> Void), callback: @escaping ResponseCallbackClosure<IQResult<T>>) -> IQEventSourceManager {
        let url = requestUrl(path)
        
        return IQEventSourceManager(url: url, authToken: token, customHeaders: customHeaders, onOpen: onOpen) { data, error in
            guard error == nil else {
                callback(nil, error)
                return
            }
            
            guard let data else {
                callback(nil, nil)
                return
            }
            
            do {
                let response = try IQJSONDecoder().decode(IQResponse<T>.self, from: data)
                if !response.ok {
                    callback(nil, NSError(response.error))
                    return
                }
                let result = IQResult(value: response.result, relations: self.relationManager.mapFromRelations(response.rels))
                callback(result, nil)
            } catch {
                callback(nil, error)
            }
        }
    }
    
    func post<T: Decodable>(_ path: String,
                            headers: [String: String] = [:],
                            body: Encodable?,
                            responseType: T.Type) async -> ResponseCallback<IQResult<T>> {
        var parameter: Any?
        if let body,
           let encoded = try? JSONEncoder().encode(body),
           let json = try? JSONSerialization.jsonObject(with: encoded) {
            parameter = json
        }
        
        return await post(path, headers: headers, body: parameter, responseType: responseType)
    }
    
    func post<T: Decodable>(_ path: String,
                            headers: [String: String] = [:],
                            body: Any?,
                            responseType: T.Type) async -> ResponseCallback<IQResult<T>> {
        var error: NSError?
        guard let request = self.request(path, method: "POST", headers: headers, json: body, error: &error),
              error == nil else { return .init(error: error) }
        
        return await post(request: request, responseType: responseType)
    }
    
    func get<T: Decodable>(_ path: String,
                           headers: [String: String] = [:],
                           responseType: T.Type) async -> ResponseCallback<IQResult<T>> {
       var error: NSError?
       guard let request = self.request(path, method: "GET", headers: headers, json: nil, error: &error),
             error == nil else { return .init(error: error) }
       
       return await post(request: request, responseType: responseType)
   }
    
    func post<T: Decodable>(request: URLRequest, taskIdentifierCallback: TaskIdentifierCallback? = nil, responseType: T.Type) async -> ResponseCallback<IQResult<T>> {
        await withCheckedContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, taskError in
                let turtle = self.handleResponse(url: request.url, data: data, response: response, error: taskError, responseType: responseType)
                if let taskError {
                    print(taskError)
                }
                continuation.resume(returning: turtle)
            }
            task.resume()
            taskIdentifierCallback?(task.taskIdentifier)
        }
    }
    
    func request(_ path: String, method: String, headers: [String: String], json: Any?, error: inout NSError?) -> URLRequest? {
        let url = requestUrl(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token {
            request.addValue("Client \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let customHeaders {
            for (key, value) in customHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        guard let json = json else { return request }
        
        do {
            let body = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            request.httpBody = body
            request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        } catch let serializationError as NSError {
            error = serializationError
            return nil
        }
        
        return request
    }
    
    func request(_ path: String, multipart params: [String: Any], files: [String: IQFileUploadRequest], error: inout NSError?) -> URLRequest? {
        let url = requestUrl(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "-----------iqchannels-boundary-\(UUID().uuidString)"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        
        if let customHeaders {
            for (key, value) in customHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        let body = requestMultipartBody(params: params, files: files, boundary: boundary)
        request.httpBody = body
        request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        
        return request
    }
    
    func requestMultipartBody(params: [String: Any], files: [String: IQFileUploadRequest], boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in params {
            guard let valueString = value as? String else { continue }
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(valueString)\r\n".data(using: .utf8)!)
        }
        
        for (key, file) in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.name ?? "")\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType ?? "")\r\n\r\n".data(using: .utf8)!)
            if let data = file.data {
                body.append(data)
            }
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    func requestUrl(_ path: String) -> URL {
        var formattedAddress = address.hasSuffix("/") ? String(address.dropLast()) : address
        formattedAddress += "/public/api/v1\(path)"
        return URL(string: formattedAddress)!
    }
    
    func post<T: Decodable>(_ path: String,
                                    multipart params: [String: String],
                                    files: [String: IQFileUploadRequest],
                                    taskIdentifierCallback: TaskIdentifierCallback? = nil,
                                    responseType: T.Type) async -> ResponseCallback<IQResult<T>> {
        var error: NSError?
        guard let request = self.request(path, multipart: params, files: files, error: &error),
              error == nil else { return .init(error: error) }
        
        return await post(request: request, taskIdentifierCallback: taskIdentifierCallback, responseType: responseType)
    }
    
    func handleResponse<T: Decodable>(url: URL?, data: Data?, response: URLResponse?, error: Error?, responseType: T.Type) -> ResponseCallback<IQResult<T>> {
        if let error {
            return .init(error: error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let text = HTTPURLResponse.localizedString(forStatusCode: 500)
            let error = NSError.clientError(text)
            return .init(error: error)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let text = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            let error = NSError.clientError(text)
            return .init(error: error)
        }
        
        guard let data, !data.isEmpty else { return .init(result: IQResult<T>()) }
        
        do {
//            let response = try IQJSONDecoder().decode(IQResponse<T>.self, from: data)
            
//            // !!!!!!!!!!! вывод сырого ответа
//            if let rawString = String(data: data, encoding: .utf8) {
//                print("Raw response: \(rawString)")
//            }
//            else {
//                print("Raw response (non-UTF8): \(data)")
//            }
            
            var responseData = data

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["OK"] == nil {

                let wrapped: [String: Any] = [
                    "OK": true,
                    "Result": json,
                    "Error": NSNull(),
                    "Rels": [:]
                ]

                responseData = try JSONSerialization.data(withJSONObject: wrapped)
            }

            let response = try IQJSONDecoder().decode(IQResponse<T>.self, from: responseData)
            
            if !response.ok {
                return .init(error: NSError(response.error))
            }
            let result = IQResult(value: response.result ?? response.data, relations: relationManager.mapFromRelations(response.rels))
            return .init(result: result)
        } catch {
            return .init(error: error)
        }
    }
    
}
