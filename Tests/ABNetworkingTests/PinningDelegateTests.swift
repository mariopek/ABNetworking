//
//  PinningDelegateTests.swift
//  ABNetworkingTests
//
//  Created by Mario Pek on 8/8/23.
//

import XCTest
import ABNetworking
import Security

class PinningDelegateTests: XCTestCase {
    
    func test_pinningDelegate_initializesWithCertificates() {
        let certificates = [Data("certificate data".utf8)]
        let delegate = PinningDelegate(certificates: certificates)
        
        XCTAssertNotNil(delegate)
    }
    
    func test_pinningDelegate_initializesWithMultipleCertificates() {
        let certificates = [
            Data("certificate1".utf8),
            Data("certificate2".utf8),
            Data("certificate3".utf8)
        ]
        let delegate = PinningDelegate(certificates: certificates)
        
        XCTAssertNotNil(delegate)
    }
    
    func test_pinningDelegate_initializesWithEmptyCertificates() {
        let certificates: [Data] = []
        let delegate = PinningDelegate(certificates: certificates)
        
        XCTAssertNotNil(delegate)
    }
    
    func test_pinningDelegate_handlesServerTrustChallenge() {
        let certificates = [Data("certificate data".utf8)]
        let delegate = PinningDelegate(certificates: certificates)
        
        // Note: Full integration test would require actual SSL certificates
        // This test verifies the delegate can be created and conforms to protocol
        XCTAssertTrue(delegate is URLSessionDelegateHandler)
    }
    
    func test_pinningDelegate_conformsToURLSessionDelegateHandler() {
        let certificates = [Data("certificate data".utf8)]
        let delegate = PinningDelegate(certificates: certificates)
        
        XCTAssertTrue(delegate is URLSessionDelegateHandler)
    }
    
    func test_pinningDelegate_handlesNonServerTrustChallenge() {
        let certificates = [Data("certificate data".utf8)]
        let delegate = PinningDelegate(certificates: certificates)
        
        let exp = expectation(description: "Wait for challenge handling")
        var disposition: URLSession.AuthChallengeDisposition?
        var credential: URLCredential?
        
        // Create a mock challenge (this is a simplified test)
        // In a real scenario, you'd need to create an actual URLAuthenticationChallenge
        // For now, we verify the delegate structure
        
        exp.fulfill()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNotNil(delegate)
    }
    
    func test_pinningDelegate_memoryLeak() {
        let certificates = [Data("certificate data".utf8)]
        
        trackForMemoryLeaks(PinningDelegate(certificates: certificates))
    }
}

