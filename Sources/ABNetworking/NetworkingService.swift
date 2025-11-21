//
//  NetworkingService.swift
//  ABNetworking
//
//  Created by Mario Pek on 8/7/23.
//

import Foundation

public class NetworkingService<Resource> {
    
    public var maxRetryCount: Int = 0
    private var currentRetryCount: Int = 0
    
    private let request: URLRequest
    private let client: HTTPClient
    private let mapper: Mapper
    private let logger: Logger?
    private var ongoingTask: HTTPClientTask?
    private var isCancelled = false
    private let queue = DispatchQueue(label: "com.abnetworking.service", attributes: .concurrent)

    public enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
        case gwError(String)
        case cancelled
        case httpError(statusCode: Int, message: String?)
        
        public static func == (lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.connectivity, .connectivity),
                 (.invalidData, .invalidData),
                 (.cancelled, .cancelled):
                return true
            case (.gwError(let lhsMsg), .gwError(let rhsMsg)):
                return lhsMsg == rhsMsg
            case (.httpError(let lhsCode, let lhsMsg), .httpError(let rhsCode, let rhsMsg)):
                return lhsCode == rhsCode && lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    

    public typealias Result = Swift.Result<Resource?, Swift.Error>
    public typealias Mapper = (Data?, HTTPURLResponse) throws -> Resource?
    
    public init(request: URLRequest, client: HTTPClient, mapper: @escaping Mapper, logger: Logger = ConsoleLogger()) {
        self.request = request
        self.client = client
        self.mapper = mapper
        self.logger = logger
    }
    
    public func cancel() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.isCancelled = true
            self.ongoingTask?.cancel()
            self.ongoingTask = nil
            ServiceManager.shared.remove(service: self)
        }
    }

    public func request(completion: @escaping (Result) -> Void) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            ServiceManager.shared.add(service: self)
        }

        ongoingTask = client.request(from: request) { [weak self, logger] result in
            guard let self = self else {
                logger?.warning("Service was deallocated prematurely.")
                return
            }
            
            self.queue.async(flags: .barrier) {
                guard !self.isCancelled else {
                    self.dispatchCompletion(.failure(Error.cancelled), completion: completion)
                    return
                }
                
                ServiceManager.shared.remove(service: self)

                switch result {
                case let .success((data, response)):
                    self.currentRetryCount = 0
                    let mappedResult = self.map(data, from: response)
                    self.dispatchCompletion(mappedResult, completion: completion)
                    self.ongoingTask = nil

                case .failure(let error):
                    self.logger?.error("Error received: \(error.localizedDescription)")
                    
                    // Don't retry if cancelled
                    guard !self.isCancelled else {
                        self.dispatchCompletion(.failure(Error.cancelled), completion: completion)
                        self.ongoingTask = nil
                        return
                    }
                    
                    if self.currentRetryCount < self.maxRetryCount {
                        self.currentRetryCount += 1
                        
                        let delay = pow(2.0, Double(self.currentRetryCount))
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            self.queue.async(flags: .barrier) {
                                guard !self.isCancelled else {
                                    self.dispatchCompletion(.failure(Error.cancelled), completion: completion)
                                    return
                                }
                                self.logger?.info("Retrying request: \(self.request.url?.absoluteString ?? "") - Attempt: \(self.currentRetryCount)")
                                self.request(completion: completion)
                            }
                        }
                    } else {
                        self.logger?.warning("Max retry attempts reached for: \(self.request.url?.absoluteString ?? "")")
                        self.currentRetryCount = 0
                        self.dispatchCompletion(.failure(Error.connectivity), completion: completion)
                        self.ongoingTask = nil
                    }
                }
            }
        }
    }

    private func map(_ data: Data?, from response: HTTPURLResponse) -> Result {
        do {
            if let resource = try mapper(data, response) {
                return .success(resource)
            } else {
                return .success(nil)
            }
        } catch let error as NSError {
            // Check if it's an HTTP error with status code
            if response.statusCode >= 400 {
                return .failure(Error.httpError(statusCode: response.statusCode, message: error.localizedDescription))
            }
            return .failure(error)
        } catch {
            return .failure(Error.invalidData)
        }
    }
    
    /// Ensures completion handler is called on main thread
    private func dispatchCompletion(_ result: Result, completion: @escaping (Result) -> Void) {
        if Thread.isMainThread {
            completion(result)
        } else {
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}


fileprivate class ServiceManager {
    static let shared = ServiceManager()
    private var activeServices: [AnyObject] = []
    private let queue = DispatchQueue(label: "com.abnetworking.servicemanager", attributes: .concurrent)

    private init() {}

    func add(service: AnyObject) {
        queue.async(flags: .barrier) {
            self.activeServices.append(service)
        }
    }

    func remove(service: AnyObject) {
        queue.async(flags: .barrier) {
            if let index = self.activeServices.firstIndex(where: { $0 === service }) {
                self.activeServices.remove(at: index)
            }
        }
    }
}

