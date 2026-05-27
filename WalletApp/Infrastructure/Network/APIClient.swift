import Foundation

/// HTTP client actor — full implementation in Phase 1.
actor APIClient: Sendable {
    init(baseURL: URL = URL(string: "https://api.wallet.sa/v1")!) {}
}
