import Foundation

/// Serialised token refresh — Phase 2.
actor AuthManager: Sendable {
    private let keychainStore: KeychainStore

    init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    func validToken() async throws -> String {
        throw AuthError.notImplemented
    }

    func clearSession() async {
        try? keychainStore.clearAll()
    }
}

enum AuthError: Error, Sendable {
    case notImplemented
}
