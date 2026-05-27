import Foundation

/// Keychain wrapper — Phase 2 implements SecItem APIs.
struct KeychainStore: Sendable {
    func saveAccessToken(_ token: String) throws {}
    func loadAccessToken() throws -> String { throw KeychainError.itemNotFound }
    func deleteAccessToken() {}

    func saveRefreshToken(_ token: String) throws {}
    func loadRefreshToken() throws -> String { throw KeychainError.itemNotFound }
    func deleteRefreshToken() {}

    func clearAll() throws {
        deleteAccessToken()
        deleteRefreshToken()
    }
}

enum KeychainError: Error, Sendable {
    case itemNotFound
}
