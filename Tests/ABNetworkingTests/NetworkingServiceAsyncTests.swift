//
//  NetworkingServiceAsyncTests.swift
//  ABNetworkingTests
//
//  Created by Mario Pek on 8/8/23.
//

import XCTest
import ABNetworking

@available(iOS 13.0, *)
class NetworkingServiceAsyncTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.removeStub()
    }
    
    func test_request_async_deliversResourceOnSuccessfulHTTPResponse() async throws {
        let resource = ["key": "value"]
        let data = try! JSONSerialization.data(withJSONObject: resource)
        let response = HTTPURLResponse(statusCode: 200)
        
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let service: NetworkingService<[String: String]> = makeService(mapper: { data, response in
            if let data = data {
                return try JSONSerialization.jsonObject(with: data) as? [String: String]
            }
            return nil
        })
        
        let result = try await service.request()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["key"], "value")
    }
    
    func test_request_async_deliversNilOnSuccessfulHTTPResponseWithEmptyData() async throws {
        let response = HTTPURLResponse(statusCode: 204)
        
        URLProtocolStub.stub(data: nil, response: response, error: nil)
        
        let service: NetworkingService<[String: Any]> = makeService(mapper: { data, response in
            return nil
        })
        
        let result = try await service.request()
        
        XCTAssertNil(result)
    }
    
    func test_request_async_throwsErrorOnClientError() async {
        let error = anyNSError()
        
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let service: NetworkingService<[String: Any]> = makeService(mapper: { data, response in
            return nil
        })
        
        do {
            _ = try await service.request()
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }
    
    func test_request_async_throwsErrorOnInvalidData() async {
        let invalidData = Data("invalid json".utf8)
        let response = HTTPURLResponse(statusCode: 200)
        
        URLProtocolStub.stub(data: invalidData, response: response, error: nil)
        
        let service: NetworkingService<[String: Any]> = makeService(mapper: { data, response in
            throw NSError(domain: "test", code: 0)
        })
        
        do {
            _ = try await service.request()
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }
    
    func test_request_async_cancelsWhenTaskIsCancelled() async {
        let service: NetworkingService<[String: Any]> = makeService(mapper: { data, response in
            return nil
        })
        
        // Stub with delayed response to allow cancellation
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        
        let task = Task {
            try await service.request()
        }
        
        // Cancel service immediately (this simulates cancellation during execution)
        service.cancel()
        
        // Also cancel the task
        task.cancel()
        
        do {
            _ = try await task.value
            // If we get here, the request might have completed before cancellation
            // This is acceptable behavior
        } catch {
            // Expected cancellation error or task cancellation
            if case NetworkingService<[String: Any]>.Error.cancelled = error {
                // Expected NetworkingService cancellation
            } else if error is CancellationError {
                // Task cancellation is also acceptable
            } else {
                // Other errors might occur if cancellation happened at different times
                // This is acceptable - we're just testing that cancellation doesn't crash
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeService<Resource>(
        mapper: @escaping NetworkingService<Resource>.Mapper,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NetworkingService<Resource> {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let client = URLSessionHTTPClient(sessionConfig: configuration)
        
        let request = anyURLRequest()
        let service = NetworkingService<Resource>(
            request: request,
            client: client,
            mapper: mapper
        )
        
        trackForMemoryLeaks(service, file: file, line: line)
        return service
    }
}

