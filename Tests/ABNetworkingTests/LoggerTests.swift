//
//  LoggerTests.swift
//  ABNetworkingTests
//
//  Created by Mario Pek on 8/8/23.
//

import XCTest
import ABNetworking

class LoggerTests: XCTestCase {
    
    func test_consoleLogger_logsDebugMessage() {
        let logger = ConsoleLogger(minimumLogLevel: .debug)
        // This test verifies the logger doesn't crash
        logger.debug("Debug message")
        logger.log("Test message")
    }
    
    func test_consoleLogger_logsInfoMessage() {
        let logger = ConsoleLogger(minimumLogLevel: .info)
        logger.info("Info message")
    }
    
    func test_consoleLogger_logsWarningMessage() {
        let logger = ConsoleLogger(minimumLogLevel: .warning)
        logger.warning("Warning message")
    }
    
    func test_consoleLogger_logsErrorMessage() {
        let logger = ConsoleLogger(minimumLogLevel: .error)
        logger.error("Error message")
    }
    
    func test_consoleLogger_filtersMessagesBelowMinimumLevel() {
        let logger = ConsoleLogger(minimumLogLevel: .warning)
        
        // These should be filtered out in DEBUG builds
        logger.debug("This debug message should be filtered")
        logger.info("This info message should be filtered")
        
        // These should be logged
        logger.warning("This warning should be logged")
        logger.error("This error should be logged")
    }
    
    func test_consoleLogger_defaultMinimumLevelIsDebug() {
        let logger = ConsoleLogger()
        XCTAssertEqual(logger.minimumLogLevel, .debug)
    }
    
    func test_consoleLogger_customMinimumLevel() {
        let logger = ConsoleLogger(minimumLogLevel: .error)
        XCTAssertEqual(logger.minimumLogLevel, .error)
    }
    
    func test_logLevel_comparison() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertFalse(LogLevel.error < LogLevel.debug)
    }
    
    func test_logLevel_rawValues() {
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
    }
    
    func test_logger_protocolExtensionMethods() {
        let logger = MockLogger()
        
        logger.debug("debug")
        XCTAssertEqual(logger.lastMessage, "debug")
        XCTAssertEqual(logger.lastLevel, .debug)
        
        logger.info("info")
        XCTAssertEqual(logger.lastMessage, "info")
        XCTAssertEqual(logger.lastLevel, .info)
        
        logger.warning("warning")
        XCTAssertEqual(logger.lastMessage, "warning")
        XCTAssertEqual(logger.lastLevel, .warning)
        
        logger.error("error")
        XCTAssertEqual(logger.lastMessage, "error")
        XCTAssertEqual(logger.lastLevel, .error)
        
        logger.log("default")
        XCTAssertEqual(logger.lastMessage, "default")
        XCTAssertEqual(logger.lastLevel, .debug)
    }
}

// MARK: - Mock Logger

private class MockLogger: Logger {
    var minimumLogLevel: LogLevel = .debug
    var lastMessage: String?
    var lastLevel: LogLevel?
    
    func log(_ message: String, level: LogLevel) {
        lastMessage = message
        lastLevel = level
    }
}

