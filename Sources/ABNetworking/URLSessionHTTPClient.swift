//
//  URLSessionHTTPClient.swift
//  ABNetworking
//
//  Created by Mario Pek on 8/7/23.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let logger: Logger
    
    
    public init(delegate: URLSessionDelegateHandler? = nil, sessionConfig: URLSessionConfiguration = .default, logger: Logger = ConsoleLogger()) {
        self.session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
        self.logger = logger
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    public func request(from request: URLRequest, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let requestId = UUID().uuidString
        logRequestDetails(request, requestId: requestId)
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                self?.logResponseDetails(data, response: httpResponse, requestId: requestId)
            }
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}

//Logger
extension URLSessionHTTPClient {
    
    private func logRequestDetails(_ request: URLRequest, requestId: String) {
        logger.info("--------------- ABNetworking Request ---------------")
        logger.debug("Request ID: \(requestId)")
        
        if let url = request.url?.absoluteURL.absoluteString {
            logger.debug("URL: \(url)")
        }
        
        if let method = request.httpMethod {
            logger.debug("METHOD: \(method)")
        }
        
        if let headers = request.allHTTPHeaderFields {
            logger.debug("HEADERS:")
            for (key, value) in headers {
                logger.debug("\(key): \(value)")
            }
        }
        
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("BODY: \(bodyString)")
        }
        
        logger.info("-------------------------------------------")
    }
    
    private func logResponseDetails(_ data: Data?, response: HTTPURLResponse?, requestId: String) {
        let statusCode = response?.statusCode ?? 0
        let logLevel: LogLevel = (200...299).contains(statusCode) ? .info : .error
        
        logger.log("--------------- ABNetworking Response ---------------", level: logLevel)
        logger.debug("Request ID: \(requestId)")
        
        if let url = response?.url?.absoluteString {
            logger.debug("URL: \(url)")
        }
        
        if let statusCode = response?.statusCode {
            logger.log("STATUS CODE: \(statusCode)", level: logLevel)
        }
        
        if let headers = response?.allHeaderFields {
            logger.debug("HEADER:")
            for (key, value) in headers {
                logger.debug("\(key): \(value)")
            }
        }
        
        if let bodyData = data {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: bodyData, options: [])
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    logger.debug("DATA: \(jsonString)")
                } else {
                    logger.debug("DATA: <Unable to convert JSON to string>")
                }
            } catch {
                logger.debug("DATA: <Unable to decode JSON>")
            }
        } else {
            logger.debug("DATA: <No body data>")
        }
        
        logger.log("-------------------------------------------", level: logLevel)
    }
}
