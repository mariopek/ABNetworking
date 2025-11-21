//
//  Logger.swift
//  ABNetworking
//
//  Created by Mario Pek on 8/8/23.
//

import Foundation

public enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public protocol Logger {
    var minimumLogLevel: LogLevel { get }
    func log(_ message: String, level: LogLevel)
}

public extension Logger {
    func log(_ message: String) {
        log(message, level: .debug)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
}

public struct ConsoleLogger: Logger {
    public let minimumLogLevel: LogLevel
    
    public init(minimumLogLevel: LogLevel = .debug) {
        self.minimumLogLevel = minimumLogLevel
    }
    
    public func log(_ message: String, level: LogLevel) {
        #if DEBUG
        guard level >= minimumLogLevel else { return }
        let prefix = levelPrefix(for: level)
        print("\(prefix) \(message)")
        #endif
    }
    
    private func levelPrefix(for level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍 [DEBUG]"
        case .info: return "ℹ️ [INFO]"
        case .warning: return "⚠️ [WARNING]"
        case .error: return "❌ [ERROR]"
        }
    }
}
