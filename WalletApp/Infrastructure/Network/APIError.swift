import Foundation

enum APIError: Error, Sendable {
    case invalidResponse
    case sessionRevoked
    case http(Int, Data)
    case decoding(DecodingError)
    case network(URLError)
    case pinningFailed
    case cancelled
}
