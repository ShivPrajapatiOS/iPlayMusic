// APIEndpoint.swift
// Define every API endpoint in a type-safe, structured way

import Foundation

// MARK: - APIEndpoint Protocol

protocol APIEndpointProtocol {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get set }
    var queryParameters: [String: String]? { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
}

extension APIEndpointProtocol {
    func buildURLRequest(decoder: JSONDecoder? = nil) throws -> URLRequest {
        // Build full URL
        var urlString = baseURL + path
        
        // Append query parameters
        if let params = queryParameters, !params.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components?.url?.absoluteString ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Encode body for POST/PUT
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingFailed
            }
        }
        
        return request
    }
}

// MARK: - Concrete APIEndpoint

struct APIEndpoint: APIEndpointProtocol {
    var baseURL: String
    var path: String
    var method: HTTPMethod
    var queryParameters: [String: String]?
    var headers: [String: String]?
    var body: Encodable?
    
    init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .GET,
        queryParameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Encodable? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.headers = headers
        self.body = body
    }
}

// MARK: - AnyEncodable (Encode any Encodable type)

struct AnyEncodable: Encodable {
    private let encodingClosure: (Encoder) throws -> Void
    
    init(_ encodable: Encodable) {
        self.encodingClosure = encodable.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encodingClosure(encoder)
    }
}
