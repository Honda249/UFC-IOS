import Foundation

enum HTTPMethod: String, Sendable {
    case GET, POST, PATCH, DELETE
}

/// Typed endpoint — request building and `send` in Phase 1.
protocol Endpoint {
    associatedtype Response: Decodable & Sendable
    var path: String { get }
    var method: HTTPMethod { get }
    var requiresAuth: Bool { get }
    var idempotencyKey: String? { get }
}

extension Endpoint {
    var requiresAuth: Bool { true }
    var idempotencyKey: String? { nil }
}
