//
//  PinningDelegate.swift
//  ABNetworking
//
//  Created by Mario Pek on 8/8/23.
//

import Foundation

public protocol URLSessionDelegateHandler: URLSessionDelegate {
    init(certificates: [Data])
}

public final class PinningDelegate: NSObject, URLSessionDelegateHandler {
    
    private let certificates: [Data]
    
    required public init(certificates: [Data]) {
        self.certificates = certificates
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            var trustedRootCertificates = Array<SecCertificate>()
            
            certificates.forEach { certificateData in
                if let rootCertificateReference = SecCertificateCreateWithData(nil, certificateData as CFData) {
                    trustedRootCertificates.append(rootCertificateReference)
                }
            }
            
            let trust: SecTrust = challenge.protectionSpace.serverTrust!
            SecTrustSetAnchorCertificates(trust, trustedRootCertificates as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, true)
            
            var error: CFError?
            if SecTrustEvaluateWithError(trust, &error) {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}
