//
//  NetworkingService+Async.swift
//  ABNetworking
//
//  Created by Mario Pek on 8/8/23.
//

import Foundation

@available(iOS 13.0, macOS 10.15, *)
extension NetworkingService {
    /// Performs the network request using async/await
    /// - Returns: The mapped resource or nil if the response is empty
    /// - Throws: NetworkingService.Error or any error from the mapper
    public func request() async throws -> Resource? {
        return try await withCheckedThrowingContinuation { continuation in
            request { result in
                switch result {
                case .success(let resource):
                    continuation.resume(returning: resource)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

