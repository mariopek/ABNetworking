# ABNetworking - Usage Examples

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Async/Await Examples](#asyncawait-examples)
3. [Error Handling](#error-handling)
4. [Retry Logic](#retry-logic)
5. [Request Cancellation](#request-cancellation)
6. [Nested API Calls](#nested-api-calls)
7. [Custom Logging](#custom-logging)
8. [Certificate Pinning](#certificate-pinning)
9. [Implementation Examples](#implementation-examples)

## Basic Usage

### Simple GET Request

```swift
import ABNetworking

// Create request
let request = ABURLRequestBuilder()
    .get(endpoint: "/api/users")
    .build()

// Create service
let service = NetworkingService<[String: Any]>(
    request: request,
    client: URLSessionHTTPClient(),
    mapper: GenericDataMapper.mapToDictionary
)

// Make request
service.request { result in
    switch result {
    case .success(let data):
        if let users = data {
            print("Users: \(users)")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### POST Request with Codable

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Create request body
let createRequest = CreateUserRequest(name: "John Doe", email: "john@example.com")

// Build request
let request = ABURLRequestBuilder()
    .post(endpoint: "/api/users", body: createRequest)
    .build()

// Create service
let service = NetworkingService<User>(
    request: request,
    client: URLSessionHTTPClient(),
    mapper: GenericDataMapper.map
)

// Make request
service.request { result in
    switch result {
    case .success(let user):
        if let user = user {
            print("Created user: \(user.name)")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Async/Await Examples

### Basic Async Request

```swift
import ABNetworking

@available(iOS 13.0, *)
func fetchUser(id: Int) async throws -> User? {
    let request = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(id)")
        .build()
    
    let service = NetworkingService<User>(
        request: request,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    return try await service.request()
}

// Usage in ViewController
class UserViewController: UIViewController {
    func loadUser() {
        Task {
            do {
                let user = try await fetchUser(id: 123)
                // Automatically on main thread
                self.nameLabel.text = user?.name
                self.emailLabel.text = user?.email
            } catch {
                self.showError(error)
            }
        }
    }
}
```

### Multiple Sequential Requests

```swift
@available(iOS 13.0, *)
func fetchUserProfile(userId: Int) async throws -> UserProfile {
    // Step 1: Get user basic info
    let userRequest = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(userId)")
        .build()
    
    let userService = NetworkingService<User>(
        request: userRequest,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    guard let user = try await userService.request() else {
        throw NetworkingService<User>.Error.invalidData
    }
    
    // Step 2: Get user settings
    let settingsRequest = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(userId)/settings")
        .build()
    
    let settingsService = NetworkingService<UserSettings>(
        request: settingsRequest,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    let settings = try await settingsService.request()
    
    // Step 3: Combine results
    return UserProfile(user: user, settings: settings)
}
```

### Parallel Requests

```swift
@available(iOS 13.0, *)
func fetchDashboardData() async throws -> DashboardData {
    async let users = fetchUsers()
    async let posts = fetchPosts()
    async let comments = fetchComments()
    
    // All requests execute in parallel
    return try await DashboardData(
        users: users,
        posts: posts,
        comments: comments
    )
}

func fetchUsers() async throws -> [User] {
    let request = ABURLRequestBuilder().get(endpoint: "/api/users").build()
    let service = NetworkingService<[User]>(
        request: request,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    return try await service.request() ?? []
}
```

## Error Handling

### Comprehensive Error Handling

```swift
func handleRequest() {
    let service = NetworkingService<[String: Any]>(
        request: request,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.mapToDictionary
    )
    
    service.request { result in
        switch result {
        case .success(let data):
            handleSuccess(data)
            
        case .failure(let error):
            handleError(error)
        }
    }
}

func handleError(_ error: Error) {
    if let networkingError = error as? NetworkingService<[String: Any]>.Error {
        switch networkingError {
        case .connectivity:
            showAlert(title: "No Internet", message: "Please check your internet connection")
            
        case .invalidData:
            showAlert(title: "Invalid Data", message: "The server returned invalid data")
            
        case .cancelled:
            // Request was cancelled - usually no action needed
            print("Request cancelled")
            
        case .httpError(let statusCode, let message):
            switch statusCode {
            case 401:
                showAlert(title: "Unauthorized", message: "Please login again")
                // Navigate to login
            case 403:
                showAlert(title: "Forbidden", message: "You don't have permission")
            case 404:
                showAlert(title: "Not Found", message: "Resource not found")
            case 500...599:
                showAlert(title: "Server Error", message: "Please try again later")
            default:
                showAlert(title: "Error", message: message ?? "Unknown error")
            }
            
        case .gwError(let message):
            showAlert(title: "Gateway Error", message: message)
        }
    } else {
        // Other errors
        showAlert(title: "Error", message: error.localizedDescription)
    }
}
```

### Async Error Handling

```swift
@available(iOS 13.0, *)
func fetchData() async {
    do {
        let data = try await service.request()
        handleSuccess(data)
    } catch NetworkingService<Resource>.Error.connectivity {
        showNetworkError()
    } catch NetworkingService<Resource>.Error.httpError(let statusCode, _) where statusCode == 401 {
        handleUnauthorized()
    } catch {
        showGenericError(error)
    }
}
```

## Retry Logic

### Configuring Retry

```swift
let service = NetworkingService<[String: Any]>(
    request: request,
    client: URLSessionHTTPClient(),
    mapper: GenericDataMapper.mapToDictionary
)

// Set maximum retry count
service.maxRetryCount = 3

// Retry delays will be: 2s, 4s, 8s (exponential backoff)
service.request { result in
    switch result {
    case .success(let data):
        print("Success after possible retries")
    case .failure(let error):
        print("Failed after all retries: \(error)")
    }
}
```

### Retry with Different Strategies

```swift
// For critical operations - more retries
func fetchCriticalData() {
    let service = NetworkingService<CriticalData>(
        request: request,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    service.maxRetryCount = 5  // Retry up to 5 times
    service.request { result in
        // Handle result
    }
}

// For user-initiated actions - fewer retries
func searchUsers(query: String) {
    let service = NetworkingService<[User]>(
        request: request,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    service.maxRetryCount = 1  // Only retry once
    service.request { result in
        // Handle result
    }
}
```

## Request Cancellation

### Cancelling on View Dismissal

```swift
class UserViewController: UIViewController {
    private var service: NetworkingService<User>?
    
    func loadUser() {
        let request = ABURLRequestBuilder()
            .get(endpoint: "/api/user")
            .build()
        
        service = NetworkingService<User>(
            request: request,
            client: URLSessionHTTPClient(),
            mapper: GenericDataMapper.map
        )
        
        service?.request { [weak self] result in
            guard let self = self else { return }
            // Handle result
        }
    }
    
    deinit {
        // Cancel request when view controller is deallocated
        service?.cancel()
    }
}
```

### Cancelling User-Initiated Actions

```swift
class SearchViewController: UIViewController {
    private var currentSearch: NetworkingService<[User]>?
    
    func searchUsers(query: String) {
        // Cancel previous search
        currentSearch?.cancel()
        
        let request = ABURLRequestBuilder()
            .get(endpoint: "/api/search?q=\(query)")
            .build()
        
        currentSearch = NetworkingService<[User]>(
            request: request,
            client: URLSessionHTTPClient(),
            mapper: GenericDataMapper.map
        )
        
        currentSearch?.request { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let users):
                self.displayResults(users ?? [])
            case .failure(let error):
                if case NetworkingService<[User]>.Error.cancelled = error {
                    // Search was cancelled - ignore
                    return
                }
                self.showError(error)
            }
        }
    }
}
```

## Nested API Calls

### Callback-Based (Legacy)

```swift
func fetchUserProfile(userId: Int, completion: @escaping (Result<UserProfile, Error>) -> Void) {
    // Step 1: Get user
    let userRequest = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(userId)")
        .build()
    
    let userService = NetworkingService<User>(
        request: userRequest,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    userService.request { result in
        switch result {
        case .success(let user):
            guard let user = user else {
                completion(.failure(NetworkingService<User>.Error.invalidData))
                return
            }
            
            // Step 2: Get user posts
            let postsRequest = ABURLRequestBuilder()
                .get(endpoint: "/api/users/\(userId)/posts")
                .build()
            
            let postsService = NetworkingService<[Post]>(
                request: postsRequest,
                client: URLSessionHTTPClient(),
                mapper: GenericDataMapper.map
            )
            
            postsService.request { result in
                switch result {
                case .success(let posts):
                    let profile = UserProfile(user: user, posts: posts ?? [])
                    completion(.success(profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

### Async/Await (Recommended)

```swift
@available(iOS 13.0, *)
func fetchUserProfile(userId: Int) async throws -> UserProfile {
    // Step 1: Get user
    let userRequest = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(userId)")
        .build()
    
    let userService = NetworkingService<User>(
        request: userRequest,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    guard let user = try await userService.request() else {
        throw NetworkingService<User>.Error.invalidData
    }
    
    // Step 2: Get user posts
    let postsRequest = ABURLRequestBuilder()
        .get(endpoint: "/api/users/\(userId)/posts")
        .build()
    
    let postsService = NetworkingService<[Post]>(
        request: postsRequest,
        client: URLSessionHTTPClient(),
        mapper: GenericDataMapper.map
    )
    
    let posts = try await postsService.request() ?? []
    
    return UserProfile(user: user, posts: posts)
}
```

## Custom Logging

### Using Custom Logger

```swift
class FileLogger: Logger {
    let minimumLogLevel: LogLevel = .debug
    private let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func log(_ message: String, level: LogLevel) {
        guard level >= minimumLogLevel else { return }
        
        let logEntry = "[\(level)] \(Date()): \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try? data.write(to: fileURL)
            }
        }
    }
}

// Use custom logger
let logger = FileLogger(fileURL: logFileURL)
let service = NetworkingService(
    request: request,
    client: URLSessionHTTPClient(logger: logger),
    mapper: mapper,
    logger: logger
)
```

### Conditional Logging

```swift
// Only log errors in production
let logger = ConsoleLogger(minimumLogLevel: .error)

// Log everything in debug builds
#if DEBUG
let logger = ConsoleLogger(minimumLogLevel: .debug)
#else
let logger = ConsoleLogger(minimumLogLevel: .error)
#endif

let service = NetworkingService(
    request: request,
    client: URLSessionHTTPClient(logger: logger),
    mapper: mapper,
    logger: logger
)
```

## Certificate Pinning

### Basic Certificate Pinning

```swift
import ABNetworking

// Load certificate from bundle
func loadCertificate(from filename: String) -> Data? {
    guard let path = Bundle.main.path(forResource: filename, ofType: "cer"),
          let data = NSData(contentsOfFile: path) as Data? else {
        return nil
    }
    return data
}

// Load certificate
guard let certificateData = loadCertificate(from: "api-certificate") else {
    fatalError("Failed to load certificate")
}

// Create PinningDelegate
let pinningDelegate = PinningDelegate(certificates: [certificateData])

// Create HTTP client with pinning
let client = URLSessionHTTPClient(delegate: pinningDelegate)

// Create request
let request = URLRequest(url: URL(string: "https://api.example.com/data")!)

// Create service
let service = NetworkingService<[String: Any]>(
    request: request,
    client: client,
    mapper: GenericDataMapper.mapToDictionary
)

// Make request - will only succeed if certificate matches
service.request { result in
    switch result {
    case .success(let data):
        print("Success: \(data ?? [:])")
    case .failure(let error):
        print("Certificate validation failed or other error: \(error)")
    }
}
```

### Multiple Certificates (Certificate Rotation)

```swift
// Load multiple certificates for rotation support
let certificate1 = loadCertificate(from: "api-certificate-v1")
let certificate2 = loadCertificate(from: "api-certificate-v2")

// Create delegate with multiple certificates
let pinningDelegate = PinningDelegate(
    certificates: [certificate1, certificate2].compactMap { $0 }
)

let client = URLSessionHTTPClient(delegate: pinningDelegate)

let service = NetworkingService<[String: Any]>(
    request: request,
    client: client,
    mapper: GenericDataMapper.mapToDictionary
)
```

### Certificate Pinning with Async/Await

```swift
@available(iOS 13.0, *)
func fetchSecureData() async throws -> [String: Any]? {
    // Load certificate
    guard let certPath = Bundle.main.path(forResource: "api-certificate", ofType: "cer"),
          let certData = NSData(contentsOfFile: certPath) as Data? else {
        throw NSError(domain: "CertificateError", code: -1, userInfo: nil)
    }
    
    // Create pinning delegate
    let pinningDelegate = PinningDelegate(certificates: [certData])
    
    // Create client with pinning
    let client = URLSessionHTTPClient(delegate: pinningDelegate)
    
    // Create request
    let request = URLRequest(url: URL(string: "https://api.example.com/secure")!)
    
    // Create service
    let service = NetworkingService<[String: Any]>(
        request: request,
        client: client,
        mapper: GenericDataMapper.mapToDictionary
    )
    
    return try await service.request()
}

// Usage
Task {
    do {
        let data = try await fetchSecureData()
        print("Secure data: \(data ?? [:])")
    } catch {
        print("Error: \(error)")
    }
}
```

### Complete Secure API Client Example

```swift
import ABNetworking

class SecureAPIClient {
    private let client: HTTPClient
    
    init(certificateFilename: String) {
        // Load certificate
        guard let certPath = Bundle.main.path(forResource: certificateFilename, ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath) as Data? else {
            fatalError("Certificate '\(certificateFilename)' not found in bundle")
        }
        
        // Create pinning delegate
        let pinningDelegate = PinningDelegate(certificates: [certData])
        
        // Create HTTP client with pinning
        self.client = URLSessionHTTPClient(delegate: pinningDelegate)
    }
    
    func fetchUserData(userId: Int, completion: @escaping (Result<User, Error>) -> Void) {
        let request = URLRequest(url: URL(string: "https://api.example.com/users/\(userId)")!)
        
        let service = NetworkingService<User>(
            request: request,
            client: client,
            mapper: GenericDataMapper.map
        )
        
        service.request { result in
            switch result {
            case .success(let user):
                if let user = user {
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "APIError", code: -1, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// Usage
let secureClient = SecureAPIClient(certificateFilename: "api-certificate")
secureClient.fetchUserData(userId: 123) { result in
    switch result {
    case .success(let user):
        print("User: \(user.name)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Conditional Certificate Pinning (Development vs Production)

```swift
class APIClient {
    private let client: HTTPClient
    
    init() {
        #if DEBUG
        // In development, don't use pinning for easier testing
        self.client = URLSessionHTTPClient()
        #else
        // In production, use certificate pinning
        guard let certData = loadCertificate(from: "api-certificate") else {
            fatalError("Certificate required in production")
        }
        let pinningDelegate = PinningDelegate(certificates: [certData])
        self.client = URLSessionHTTPClient(delegate: pinningDelegate)
        #endif
    }
}
```

### Loading Certificates from Different Sources

```swift
// From bundle
func loadCertificateFromBundle(filename: String) -> Data? {
    guard let path = Bundle.main.path(forResource: filename, ofType: "cer"),
          let data = NSData(contentsOfFile: path) as Data? else {
        return nil
    }
    return data
}

// From URL
func loadCertificateFromURL(_ url: URL) -> Data? {
    return try? Data(contentsOf: url)
}

// From base64 string
func loadCertificateFromBase64(_ base64String: String) -> Data? {
    return Data(base64Encoded: base64String)
}

// Usage
let cert1 = loadCertificateFromBundle(filename: "api-cert")
let cert2 = loadCertificateFromURL(URL(string: "https://example.com/cert.cer")!)
let cert3 = loadCertificateFromBase64("MIIF...") // Your base64 encoded certificate

let pinningDelegate = PinningDelegate(
    certificates: [cert1, cert2, cert3].compactMap { $0 }
)
```

## Implementation Examples

> **Note:** The following implementations (`ABURLRequestBuilder` and `GenericDataMapper`) are helper classes that are **not part of the ABNetworking SDK**. These are example implementations that you can use as a reference or implement your own. You can use any request builder (or create `URLRequest` directly) and any mapper function as long as they match the required interfaces.

### ABURLRequestBuilder Implementation

Here's an example implementation of `ABURLRequestBuilder` that you can use as a reference:

```swift
public class ABURLRequestBuilder {
    private var url: URL?
    private var method: String = "GET"
    private var headers: [String: String] = [:]
    private var body: Data?
    private var timeoutInterval: TimeInterval = 60.0
    private var multipartData: MultiPartData?
    private var baseURL: String = "https://api.example.com" // Configure your base URL
    
    public init() {}
    
    // Convenience methods for HTTP methods
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
    
    // Chainable configuration methods
    public func setURL(endpoint: String) -> ABURLRequestBuilder {
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

// Supporting structure for multipart data
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
        let boundaryPrefix = "--\(boundary)\r\n"
        
        // Add parameters
        for (key, value) in parameters {
            body.append(boundaryPrefix.data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file data
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}
```

### GenericDataMapper Implementation

> **Note:** `GenericDataMapper` is not part of the ABNetworking SDK. You can use any mapper function as long as it matches the `Mapper` type signature: `(Data?, HTTPURLResponse) throws -> Resource?`

Here's an example implementation of `GenericDataMapper` that you can use as a reference:

```swift
public struct GenericDataMapper {
    
    /// Maps response data to a Decodable model
    /// Usage: GenericDataMapper.map(data, from: response) as User?
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
            // Configure decoder if needed
            // decoder.dateDecodingStrategy = .iso8601
            // decoder.keyDecodingStrategy = .convertFromSnakeCase
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
    /// Usage: GenericDataMapper.mapToDictionary(data, from: response)
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
    /// Usage: GenericDataMapper.mapToArrayOfDictionaries(data, from: response)
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
    /// Usage: GenericDataMapper.plainData(data, from: response)
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

### Usage with NetworkingService

Here's how these implementations work together with `NetworkingService`:

```swift
// Example: Using ABURLRequestBuilder and GenericDataMapper together
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Build the request
let request = ABURLRequestBuilder()
    .get(endpoint: "/api/users/123")
    .setHeader("Authorization", forKey: "Bearer token123")
    .build()

// Create service with mapper
let service = NetworkingService<User>(
    request: request,
    client: URLSessionHTTPClient(),
    mapper: GenericDataMapper.map
)

// Make the request
service.request { result in
    switch result {
    case .success(let user):
        if let user = user {
            print("User: \(user.name)")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

