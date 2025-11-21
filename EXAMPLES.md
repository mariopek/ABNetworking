# ABNetworking - Usage Examples

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Async/Await Examples](#asyncawait-examples)
3. [Error Handling](#error-handling)
4. [Retry Logic](#retry-logic)
5. [Request Cancellation](#request-cancellation)
6. [Nested API Calls](#nested-api-calls)
7. [Custom Logging](#custom-logging)

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

