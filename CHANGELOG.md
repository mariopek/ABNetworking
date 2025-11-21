# ABNetworking - Changelog

## Improvements and Changes

### 🎯 Major Changes

#### 1. **Logger System - Log Levels**
- ✅ Added `LogLevel` enum with levels: `debug`, `info`, `warning`, `error`
- ✅ Extended `Logger` protocol with `minimumLogLevel` property
- ✅ Added extension methods: `debug()`, `info()`, `warning()`, `error()`
- ✅ `ConsoleLogger` now supports message filtering by level
- ✅ `ABLogger` updated to conform to new protocol
- ✅ DEBUG-only logging enabled

**Usage:**
```swift
let logger = ConsoleLogger(minimumLogLevel: .warning)
logger.debug("This won't be logged")  // Filtered out
logger.warning("This will be logged") // Displayed
```

#### 2. **NetworkingService - Thread Safety & Main Thread Guarantee**
- ✅ Thread-safe `ServiceManager` with `DispatchQueue`
- ✅ **Main Thread Guarantee** - all completion handlers are called on main thread
- ✅ Added `cancel()` method for cancelling requests
- ✅ `isCancelled` flag for cancellation check
- ✅ Retry logic checks cancellation before each retry

**Usage:**
```swift
let service = NetworkingService(request: request, client: client, mapper: mapper)
service.request { result in
    // This is GUARANTEED on main thread!
    // You can safely update UI
    switch result {
    case .success(let data):
        self.updateUI(with: data)
    case .failure(let error):
        self.showError(error)
    }
}

// You can cancel the request
service.cancel()
```

#### 3. **Error Handling - Improvements**
- ✅ Extended error types: `cancelled`, `httpError(statusCode:message:)`
- ✅ `Error` enum is `Equatable` for easier testing
- ✅ Better mapping of HTTP status codes to error types

**Usage:**
```swift
switch error {
case .connectivity:
    // Network problem
case .invalidData:
    // Invalid response data
case .cancelled:
    // Request was cancelled
case .httpError(let statusCode, let message):
    // HTTP error with status code
    print("Status: \(statusCode), Message: \(message)")
case .gwError(let message):
    // Gateway error
}
```

#### 4. **Async/Await Support**
- ✅ Added `request() async throws` method for modern Swift async/await
- ✅ Available from iOS 13.0+
- ✅ Automatically ensures main thread for UI updates

**Usage:**
```swift
// Modern async/await approach
do {
    let data = try await service.request()
    // Automatically on main thread
    self.updateUI(with: data)
} catch {
    self.showError(error)
}
```

#### 5. **Retry Logic - Improvements**
- ✅ Exponential backoff (2^n seconds)
- ✅ Thread-safe retry count management
- ✅ Retry logic respects cancellation
- ✅ Retry count reset after successful request

**Usage:**
```swift
let service = NetworkingService(request: request, client: client, mapper: mapper)
service.maxRetryCount = 3  // Maximum 3 retries

service.request { result in
    // Will automatically retry up to 3 times if it fails
}
```

#### 6. **URLSessionHTTPClient - Logging Improvements**
- ✅ Uses new log levels for request/response logging
- ✅ Error responses are logged at `error` level
- ✅ Successful responses are logged at `info` level
- ✅ Details are logged at `debug` level

### 📝 Detailed Changes by File

#### `Logger.swift`
- Added `LogLevel` enum
- Extended `Logger` protocol
- Updated `ConsoleLogger` with level filtering
- DEBUG-only logging

#### `NetworkingService.swift`
- Thread-safe `ServiceManager`
- `cancel()` method
- Main thread guarantee for completion handlers
- Improved error handling
- Retry logic with cancellation check

#### `NetworkingService+Async.swift` (NEW)
- Async/await wrapper for `request()` method

#### `URLSessionHTTPClient.swift`
- Updated to use new log levels
- Better error response logging

#### `ABLogger.swift` (outside Networking package)
- Updated to conform to new `Logger` protocol
- Supports log levels
- Preserved existing functionality (log history, timestamp)

#### `GenericDataMapper.swift` (outside Networking package)
- Updated to use `.error()` and `.warning()` methods instead of `.log()`

### 🧪 Tests

#### New Test Files:
1. **NetworkingServiceTests.swift**
   - Tests for successful requests
   - Tests for error handling
   - Tests for retry logic
   - Tests for cancellation
   - Tests for retry count reset

2. **PinningDelegateTests.swift**
   - Tests for initialization
   - Tests for certificate handling
   - Memory leak tests

3. **LoggerTests.swift**
   - Tests for all log levels
   - Tests for message filtering
   - Tests for log level comparison
   - Mock logger for testing

4. **NetworkingServiceAsyncTests.swift**
   - Async/await tests
   - Tests for cancellation in async context

### 🔧 Bug Fixes

1. **Main Thread Issue** - Fixed issue where UI API calls were on background thread
2. **Memory Leaks** - Thread-safe `ServiceManager` prevents memory leaks
3. **Logger Compatibility** - `ABLogger` now conforms to new protocol

### 📊 Results

- ✅ **Thread Safety** - All operations are thread-safe
- ✅ **Main Thread Guarantee** - UI updates are safe
- ✅ **Better Error Handling** - Specific error types
- ✅ **Modern Swift** - Async/await support
- ✅ **Better Logging** - Log levels for better debugging
- ✅ **Test Coverage** - Complete test suite
- ✅ **Cancellation Support** - You can cancel requests
- ✅ **Retry Logic** - Exponential backoff with cancellation check

