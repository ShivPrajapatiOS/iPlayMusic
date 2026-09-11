// HTTPClient.swift
// Core reusable HTTP client — use in ANY iOS project
// Supports GET, POST, PUT, DELETE with full error handling

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case noInternetConnection
    case networkTimeout
    case serverError(statusCode: Int, message: String?)
    case decodingFailed(Error)
    case encodingFailed
    case unauthorized
    case notFound
    case rateLimited
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided."
        case .noInternetConnection:
            return "No internet connection. Please check your network."
        case .networkTimeout:
            return "Request timed out. Please try again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed:
            return "Failed to encode request body."
        case .unauthorized:
            return "Unauthorized access. Please login again."
        case .notFound:
            return "Requested resource not found."
        case .rateLimited:
            return "Too many requests. Please slow down."
        case .unknown(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Response Wrapper

struct APIResponse<T: Decodable>: Decodable {
    let status: String?
    let message: String?
    let data: T?
    
    // Flexible key mapping — adjust if API response structure changes
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case data
    }
}

// MARK: - Request Configuration

struct RequestConfig {
    var timeoutInterval: TimeInterval = 30.0      // Request timeout in seconds
    var resourceTimeout: TimeInterval = 60.0      // Total resource timeout
    var retryCount: Int = 2                        // Number of retries on failure
    var retryDelay: TimeInterval = 1.0             // Delay between retries (seconds)
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    static let `default` = RequestConfig()
    
    static let fast = RequestConfig(
        timeoutInterval: 10.0,
        resourceTimeout: 20.0,
        retryCount: 1,
        retryDelay: 0.5
    )
    
    static let slow = RequestConfig(
        timeoutInterval: 60.0,
        resourceTimeout: 120.0,
        retryCount: 3,
        retryDelay: 2.0
    )
}

// MARK: - HTTP Client

final class HTTPClient {
    
    // Singleton — use HTTPClient.shared or create own instance
    static let shared = HTTPClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(config: RequestConfig = .default) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeoutInterval
        sessionConfig.timeoutIntervalForResource = config.resourceTimeout
        sessionConfig.waitsForConnectivity = false
        
        self.session = URLSession(configuration: sessionConfig)
        
        self.decoder = JSONDecoder()
//        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Core Request Method
    
    /// Generic request — handles GET, POST, PUT, DELETE
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        config: RequestConfig = .default
    ) async throws -> T {
        return try await withRetry(count: config.retryCount, delay: config.retryDelay) {
            try await self.performRequest(endpoint, responseType: responseType)
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        config: RequestConfig = .default
    ) async throws -> T {
        var ep = endpoint
        ep.method = .GET
        return try await request(ep, responseType: responseType, config: config)
    }
    
    func post<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        config: RequestConfig = .default
    ) async throws -> T {
        var ep = endpoint
        ep.method = .POST
        return try await request(ep, responseType: responseType, config: config)
    }
    
    func put<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        config: RequestConfig = .default
    ) async throws -> T {
        var ep = endpoint
        ep.method = .PUT
        return try await request(ep, responseType: responseType, config: config)
    }
    
    func delete<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        config: RequestConfig = .default
    ) async throws -> T {
        var ep = endpoint
        ep.method = .DELETE
        return try await request(ep, responseType: responseType, config: config)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        
        // 1. Build URL Request
        let urlRequest = try endpoint.buildURLRequest(decoder: decoder)
        
        // 2. Log request (debug only)
        #if DEBUG
        debugLog(request: urlRequest)
        #endif
        
        // 3. Execute request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw APIError.unknown(error)
        }
        
        // 4. Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(NSError(domain: "Invalid response", code: 0))
        }
        
        // 5. Log response (debug only)
        #if DEBUG
        debugLog(response: httpResponse, data: data)
        #endif
        
        // 6. Handle HTTP status codes
        try validateStatusCode(httpResponse.statusCode, data: data)
        
        // 7. Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    private func validateStatusCode(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 400...499:
            let message = extractErrorMessage(from: data)
            throw APIError.serverError(statusCode: statusCode, message: message)
        case 500...599:
            let message = extractErrorMessage(from: data)
            throw APIError.serverError(statusCode: statusCode, message: message)
        default:
            throw APIError.serverError(statusCode: statusCode, message: nil)
        }
    }
    
    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noInternetConnection
        case .timedOut:
            return .networkTimeout
        case .badURL, .unsupportedURL:
            return .invalidURL
        default:
            return .unknown(error)
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["message"] as? String ?? json?["error"] as? String
    }
    
    // MARK: - Retry Logic
    
    private func withRetry<T>(
        count: Int,
        delay: TimeInterval,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...count {
            do {
                return try await operation()
            } catch let error as APIError {
                // Don't retry client errors or auth errors
                switch error {
                case .unauthorized, .notFound, .invalidURL, .encodingFailed:
                    throw error
                default:
                    lastError = error
                    if attempt < count {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
            }
        }
        
        throw lastError ?? APIError.unknown(NSError(domain: "Retry failed", code: 0))
    }
    
    // MARK: - Debug Logging
    
    private func debugLog(request: URLRequest) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 REQUEST: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func debugLog(response: HTTPURLResponse, data: Data) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📥 RESPONSE: \(response.statusCode) \(response.url?.absoluteString ?? "")")
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let string = String(data: pretty, encoding: .utf8) {
            print("   Body: \(string.prefix(500))...")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
