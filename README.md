
# ABNetworking

A modern, thread-safe networking layer for iOS with async/await support, automatic retry, comprehensive error handling, and certificate pinning.

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Installation

### Swift Package Manager

Add ABNetworking to your project using Swift Package Manager:

**In Xcode:**
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/mariopek/ABNetworking.git`
3. Select version: `1.0.0` or later
4. Click "Add Package"

**In Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/mariopek/ABNetworking.git", from: "1.0.0")
]
```

## Requirements

- iOS 12.0+
- Swift 5.7+
- Xcode 14.0+

## Overview

The ABNetworking layer has been built with modularity and ease of use in mind. It uses a set of classes and helpers to handle HTTP requests, response mapping, and other networking-related tasks. The main classes include:

**Core SDK Classes:**
- **NetworkingService**: Core networking service with retry logic, cancellation, and async/await support
- **HTTPClient**: Protocol-based HTTP client interface
- **URLSessionHTTPClient**: URLSession-based implementation of HTTPClient
- **Logger**: Logging system with configurable log levels
- **PinningDelegate**: Certificate pinning support

**Helper Classes (Example Implementations - Not Part of SDK):**
- **GenericDataMapper**: Example mapper for mapping and validating server responses (you can implement your own)
- **ABURLRequestBuilder**: Example builder for creating URLRequest objects (you can implement your own)
- **ABBaseNetworking**: Example wrapper that sets up the networking service using pinned certificates (you can implement your own)

> **Note:** The helper classes (`GenericDataMapper`, `ABURLRequestBuilder`, `ABBaseNetworking`) are example implementations shown in the documentation. They are not part of the ABNetworking SDK package. You can use your own implementations or create `URLRequest` objects directly and provide custom mapper functions that match the required signatures.

## Features

✨ **Modern Swift Support**
- Async/await support (iOS 13.0+)
- Protocol-oriented design
- Type-safe error handling

🔒 **Security**
- Certificate pinning support
- Thread-safe operations
- Main thread guarantee for UI updates

🔄 **Reliability**
- Automatic retry with exponential backoff
- Request cancellation support
- Comprehensive error handling

📊 **Logging**
- Log levels (debug, info, warning, error)
- Configurable minimum log level
- DEBUG-only logging option

🧪 **Testing**
- Comprehensive test coverage
- Memory leak detection
- Mock-friendly architecture

##Getting Started

#1. Building a URLRequest using ABURLRequestBuilder:

##ABURLRequestBuilder

ABURLRequestBuilder is a robust and versatile class designed to simplify the creation of URLRequest instances in your Swift project. It supports various HTTP methods, including GET, POST, PUT, and DELETE requests, and allows sending multipart data, JSON, and Codable objects as the body.

## Features
###Chainable Methods: Build your request with a fluent, readable syntax.
###Codable Support: Easily send Codable objects in the request body.
###Multipart Requests: Simplified multipart data sending.
###Custom Headers: Add custom headers to your requests.
###Timeout Configuration: Set custom timeout intervals for your requests.

## Usage

###GET Request

let builder = ABURLRequestBuilder()
let request = builder.get(endpoint: "path/to/resource").build()

###POST Request with Codable Object

struct UserModel: Codable {
    let username: String
    let email: String
}

let user = UserModel(username: "MarioPek", email: "test@example.com")
let builder = ABURLRequestBuilder()
let request = builder.post(endpoint: "path/to/resource", body: user).build()

### PUT Request with Codable Object

struct UpdateModel: Codable {
    let name: String
    let age: Int
}

let update = UpdateModel(name: "John Doe", age: 25)
let builder = ABURLRequestBuilder()
let request = builder.put(endpoint: "path/to/resource", body: update).build()

### Multipart Request

let parameters = ["username": "MarioPek"]
let data = Data() 
let multipartData = MultiPartData(parameters: parameters, data: data, mimeType: "image/jpeg", filename: "image.jpg")
let builder = ABURLRequestBuilder()
let request = builder.setURL(endpoint: "path/to/resource").setMethod(.POST).setMultipartData(multipartData).build()


##Customization
You can further customize the request by setting additional headers, query parameters, timeout intervals, and other properties using the chainable method provided by ABURLRequestBuilder.

> **Note:** `ABURLRequestBuilder` is a helper class that is not part of the ABNetworking SDK. It's an example implementation that you can use as a reference or implement your own. You can use any request builder (or create `URLRequest` directly) as long as it produces a valid `URLRequest` object that can be passed to `NetworkingService`.

## Implementation Example

Here's an example of what `ABURLRequestBuilder` might look like:

```swift
public class ABURLRequestBuilder {
    private var url: URL?
    private var method: String = "GET"
    private var headers: [String: String] = [:]
    private var body: Data?
    private var timeoutInterval: TimeInterval = 60.0
    private var multipartData: MultiPartData?
    
    public init() {}
    
    public func get(endpoint: String) -> ABURLRequestBuilder {
        return setURL(endpoint: endpoint).setMethod("GET")
    }
    
    public func post<T: Codable>(endpoint: String, body: T) -> ABURLRequestBuilder {
        let builder = setURL(endpoint: endpoint).setMethod("POST")
        if let jsonData = try? JSONEncoder().encode(body) {
            builder.body = jsonData
            builder.headers["Content-Type"] = "application/json"
        }
        return builder
    }
    
    public func put<T: Codable>(endpoint: String, body: T) -> ABURLRequestBuilder {
        let builder = setURL(endpoint: endpoint).setMethod("PUT")
        if let jsonData = try? JSONEncoder().encode(body) {
            builder.body = jsonData
            builder.headers["Content-Type"] = "application/json"
        }
        return builder
    }
    
    public func delete(endpoint: String) -> ABURLRequestBuilder {
        return setURL(endpoint: endpoint).setMethod("DELETE")
    }
    
    public func setURL(endpoint: String) -> ABURLRequestBuilder {
        // Assuming baseURL is configured elsewhere
        self.url = URL(string: baseURL + endpoint)
        return self
    }
    
    public func setMethod(_ method: String) -> ABURLRequestBuilder {
        self.method = method
        return self
    }
    
    public func setMultipartData(_ data: MultiPartData) -> ABURLRequestBuilder {
        self.multipartData = data
        return self
    }
    
    public func setHeader(_ value: String, forKey key: String) -> ABURLRequestBuilder {
        self.headers[key] = value
        return self
    }
    
    public func setTimeout(_ interval: TimeInterval) -> ABURLRequestBuilder {
        self.timeoutInterval = interval
        return self
    }
    
    public func build() -> URLRequest {
        guard let url = self.url else {
            fatalError("URL must be set before building request")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval
        
        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        if let multipartData = multipartData {
            request.httpBody = multipartData.toData()
            request.setValue("multipart/form-data; boundary=\(multipartData.boundary)", forHTTPHeaderField: "Content-Type")
        } else if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

public struct MultiPartData {
    let parameters: [String: String]
    let data: Data
    let mimeType: String
    let filename: String
    let boundary: String
    
    public init(parameters: [String: String], data: Data, mimeType: String, filename: String) {
        self.parameters = parameters
        self.data = data
        self.mimeType = mimeType
        self.filename = filename
        self.boundary = UUID().uuidString
    }
    
    func toData() -> Data {
        var body = Data()
        // Implementation for multipart form data encoding
        return body
    }
}
```


#2. Setting up and Using ABBaseNetworking:
First, instantiate the ABBaseNetworking class:


let networking = ABBaseNetworking<Model>(
    request: yourURLRequest,
    mapper: yourMapperFunction
)
Then, you can start the request like so:

networking.startRequest { result in
    switch result {
    case .success(let data):
        // Handle success
    case .failure(let error):
        // Handle error
    }
}

#3. Using NetworkingService Directly:

You can use `NetworkingService` directly for more control:

```swift
import ABNetworking

// Create request
let request = URLRequest(url: URL(string: "https://api.example.com/data")!)

// Create HTTP client
let client = URLSessionHTTPClient()

// Create service with mapper
let service = NetworkingService<[String: Any]>(
    request: request,
    client: client,
    mapper: GenericDataMapper.mapToDictionary
)

// Configure retry
service.maxRetryCount = 3

// Make request
service.request { result in
    switch result {
    case .success(let data):
        print("Success: \(data ?? [:])")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Cancel if needed
service.cancel()
```

### Async/Await Usage (iOS 13.0+)

```swift
import ABNetworking

// Create service
let service = NetworkingService<User>(
    request: request,
    client: client,
    mapper: GenericDataMapper.map
)

// Use async/await
Task {
    do {
        let user = try await service.request()
        // Automatically on main thread - safe for UI updates
        self.updateUI(with: user)
    } catch NetworkingService<User>.Error.cancelled {
        print("Request was cancelled")
    } catch NetworkingService<User>.Error.connectivity {
        print("Network connectivity issue")
    } catch NetworkingService<User>.Error.httpError(let statusCode, let message) {
        print("HTTP Error \(statusCode): \(message ?? "Unknown")")
    } catch {
        print("Other error: \(error)")
    }
}
```

### Advanced: Nested API Calls with Async/Await

```swift
func fetchUserProfile() async throws -> UserProfile {
    // First request - get user ID
    let userIdRequest = ABURLRequestBuilder().get(endpoint: "/user/id").build()
    let userIdService = NetworkingService<String>(
        request: userIdRequest,
        client: client,
        mapper: GenericDataMapper.map
    )
    
    let userId = try await userIdService.request() ?? ""
    
    // Second request - get user profile using ID
    let profileRequest = ABURLRequestBuilder().get(endpoint: "/user/\(userId)/profile").build()
    let profileService = NetworkingService<UserProfile>(
        request: profileRequest,
        client: client,
        mapper: GenericDataMapper.map
    )
    
    return try await profileService.request()!
}

// Usage
Task {
    do {
        let profile = try await fetchUserProfile()
        self.displayProfile(profile)
    } catch {
        self.showError(error)
    }
}
```

### Error Handling

```swift
service.request { result in
    switch result {
    case .success(let data):
        // Handle success
        break
        
    case .failure(let error):
        switch error {
        case NetworkingService<Resource>.Error.connectivity:
            // Network connectivity issue
            showNetworkError()
            
        case NetworkingService<Resource>.Error.invalidData:
            // Invalid response data
            showDataError()
            
        case NetworkingService<Resource>.Error.cancelled:
            // Request was cancelled
            // Usually no action needed
            
        case NetworkingService<Resource>.Error.httpError(let statusCode, let message):
            // HTTP error with status code
            if statusCode == 401 {
                handleUnauthorized()
            } else {
                showHTTPError(statusCode: statusCode, message: message)
            }
            
        case NetworkingService<Resource>.Error.gwError(let message):
            // Gateway error
            showGatewayError(message)
            
        default:
            // Other errors
            showGenericError(error)
        }
    }
}
```

#4. Using the GenericDataMapper:

To map the data from a response to a Decodable model:

```swift
try GenericDataMapper.map(yourData, from: yourHTTPURLResponse)
```

To map the data to a dictionary:

```swift
try GenericDataMapper.mapToDictionary(yourData, from: yourHTTPURLResponse)
```

To map the data to an array of dictionaries:

```swift
try GenericDataMapper.mapToArrayOfDictionaries(yourData, from: yourHTTPURLResponse)
```

To get plain data:

```swift
try GenericDataMapper.plainData(yourData, from: yourHTTPURLResponse)
```

> **Note:** `GenericDataMapper` is a helper struct that is not part of the ABNetworking SDK. It's an example implementation that you can use as a reference or implement your own. You can use any mapper function as long as it matches the `Mapper` type signature: `(Data?, HTTPURLResponse) throws -> Resource?`

## Implementation Example

Here's an example of what `GenericDataMapper` might look like:

```swift
public struct GenericDataMapper {
    
    /// Maps response data to a Decodable model
    public static func map<T: Decodable>(_ data: Data?, from response: HTTPURLResponse) throws -> T? {
        guard let data = data, !data.isEmpty else {
            return nil
        }
        
        // Validate HTTP status code
        guard (200...299).contains(response.statusCode) else {
            throw NSError(
                domain: "GenericDataMapper",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(response.statusCode)"]
            )
        }
        
        do {
            let decoder = JSONDecoder()
            // Configure decoder if needed (date decoding strategy, etc.)
            // decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NSError(
                domain: "GenericDataMapper",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode: \(error.localizedDescription)"]
            )
        }
    }
    
    /// Maps response data to a dictionary
    public static func mapToDictionary(_ data: Data?, from response: HTTPURLResponse) throws -> [String: Any]? {
        guard let data = data, !data.isEmpty else {
            return nil
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw NSError(
                domain: "GenericDataMapper",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(response.statusCode)"]
            )
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }
            return json
        } catch {
            throw NSError(
                domain: "GenericDataMapper",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON: \(error.localizedDescription)"]
            )
        }
    }
    
    /// Maps response data to an array of dictionaries
    public static func mapToArrayOfDictionaries(_ data: Data?, from response: HTTPURLResponse) throws -> [[String: Any]]? {
        guard let data = data, !data.isEmpty else {
            return nil
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw NSError(
                domain: "GenericDataMapper",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(response.statusCode)"]
            )
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                return nil
            }
            return json
        } catch {
            throw NSError(
                domain: "GenericDataMapper",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON array: \(error.localizedDescription)"]
            )
        }
    }
    
    /// Returns plain data without parsing
    public static func plainData(_ data: Data?, from response: HTTPURLResponse) throws -> Data? {
        guard (200...299).contains(response.statusCode) else {
            throw NSError(
                domain: "GenericDataMapper",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(response.statusCode)"]
            )
        }
        
        return data
    }
}
```



## Certificate Pinning

The ABNetworking layer provides an integrated certificate pinning mechanism through the `PinningDelegate` class. It ensures that the server the app communicates with presents a certificate that matches the pinned certificate in the app, enhancing security.

### Basic Usage

To use certificate pinning:

1. Load your certificate(s) as `Data`
2. Create a `PinningDelegate` with the certificates
3. Pass the delegate to `URLSessionHTTPClient` when initializing it

```swift
import ABNetworking

// Load certificate from bundle
guard let certPath = Bundle.main.path(forResource: "api-certificate", ofType: "cer"),
      let certData = NSData(contentsOfFile: certPath) as Data? else {
    fatalError("Certificate not found")
}

// Create PinningDelegate
let pinningDelegate = PinningDelegate(certificates: [certData])

// Create HTTP client with pinning
let client = URLSessionHTTPClient(delegate: pinningDelegate)

// Use with NetworkingService
let service = NetworkingService<[String: Any]>(
    request: request,
    client: client,
    mapper: GenericDataMapper.mapToDictionary
)
```

**Important Notes:**
- Certificates should be in DER format (`.cer` files)
- Certificate pinning will reject connections if the server's certificate doesn't match the pinned certificate(s)
- You can pin multiple certificates to support certificate rotation

For more detailed examples including async/await usage, multiple certificates, conditional pinning, and different certificate loading methods, see the [Certificate Pinning section in EXAMPLES.md](EXAMPLES.md#certificate-pinning).

## Logging

### Using Logger

```swift
import ABNetworking

// Create logger with minimum log level
let logger = ConsoleLogger(minimumLogLevel: .info)

// Log messages
logger.debug("Debug message")    // Won't be logged if level is .info or higher
logger.info("Info message")      // Will be logged
logger.warning("Warning message") // Will be logged
logger.error("Error message")    // Will be logged

// Or use the generic log method (defaults to .debug)
logger.log("Debug message")
```

### Custom Logger

```swift
class CustomLogger: Logger {
    let minimumLogLevel: LogLevel = .debug
    
    func log(_ message: String, level: LogLevel) {
        // Your custom logging implementation
        if level >= minimumLogLevel {
            // Send to your logging service
            sendToLoggingService(message, level: level)
        }
    }
}

// Use custom logger
let service = NetworkingService(
    request: request,
    client: client,
    mapper: mapper,
    logger: CustomLogger()
)
```

## Retry Logic

The `NetworkingService` supports automatic retry with exponential backoff:

```swift
let service = NetworkingService(request: request, client: client, mapper: mapper)

// Set maximum retry count
service.maxRetryCount = 3

// Retry delays: 2s, 4s, 8s (exponential backoff)
service.request { result in
    // Will automatically retry up to 3 times on failure
}
```

## Request Cancellation

You can cancel ongoing requests:

```swift
let service = NetworkingService(request: request, client: client, mapper: mapper)

// Start request
service.request { result in
    switch result {
    case .failure(let error):
        if case NetworkingService<Resource>.Error.cancelled = error {
            print("Request was cancelled")
        }
    default:
        break
    }
}

// Cancel the request
service.cancel()
```

## Main Thread Guarantee

**Important**: All completion handlers are guaranteed to be called on the main thread. This means you can safely update UI directly from the completion handler:

```swift
service.request { result in
    // ✅ This is on main thread - safe for UI updates
    switch result {
    case .success(let data):
        self.label.text = "Success"
        self.tableView.reloadData()
    case .failure(let error):
        self.showErrorAlert(error)
    }
}
```

## Best Practices

1. **Use Async/Await when possible** - Cleaner code, better error handling
2. **Set appropriate retry counts** - Don't retry too many times for user-initiated actions
3. **Handle cancellation** - Check for cancellation errors and handle appropriately
4. **Use appropriate log levels** - Use `.error` for errors, `.debug` for detailed info
5. **Cancel requests when needed** - Cancel requests when view controller is deallocated

## Conclusion

With the ABNetworking layer, you get a structured and secure way of handling network operations in your app. The layer provides:

- ✅ Thread-safe operations
- ✅ Main thread guarantee for UI updates
- ✅ Modern async/await support
- ✅ Automatic retry with exponential backoff
- ✅ Request cancellation
- ✅ Comprehensive error handling
- ✅ Flexible logging system
- ✅ Certificate pinning support

Always ensure that the configuration, especially related to certificate pinning, is accurate and up-to-date to ensure the app's functionality and security.

For further queries or troubleshooting, please refer to the inline documentation within the code or contact the developer.


## Usage in situation that need to execute nested API calls


import ABNetworking

@objcMembers class TestService: NSObject {
    
    func getFirstData(success: @escaping ([String: Any]) -> Void, failure: @escaping (Error) -> Void) {
        let request = ABURLRequestBuilder().get(endpoint: "/firstEndpoint").build()
        let service = NetworkingService<[String: Any]>(request: request, mapper: GenericDataMapper.mapToDictionary)
        service.request { result in
            switch result {
            case .success(let data):
                success(data)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func getSecondData(success: @escaping ([[String: Any]]) -> Void, failure: @escaping (Error) -> Void) {
        let request = ABURLRequestBuilder().get(endpoint: "/secondEndpoint").build()
        let service = NetworkingService<[[String: Any]]>(request: request, mapper: GenericDataMapper.mapToArrayOfDictionaries)
        service.request { result in
            switch result {
            case .success(let data):
                success(data)
            case .failure(let error):
                failure(error)
            }
        }
    }
}

  And now we can use it like this:
 
 func fetchFirstThenSecondData() {
    let testService = TestService()
    
    testService.getFirstData(success: { firstData in
        print("Received first data: \(firstData)")

        // Now, call the second API using the result from the first
        testService.getSecondData(success: { secondData in
            print("Received second data: \(secondData)")
        }, failure: { error in
            print("Failed to get second data: \(error)")
        })

    }, failure: { error in
        print("Failed to get first data: \(error)")
    })
}

