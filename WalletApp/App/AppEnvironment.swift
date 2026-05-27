import Foundation

/// DI container for infrastructure and application services (see iOS-ARCHITECTURE.md §11).
struct AppEnvironment: Sendable {
    let apiClient: APIClient
    let authManager: AuthManager
    let keychainStore: KeychainStore
    let walletService: WalletService
    let paymentService: PaymentService
    let sessionService: SessionService
    let identityService: IdentityService

    static func production() -> AppEnvironment {
        fatalError("AppEnvironment.production() — wired incrementally Phase 1–5")
    }

    static func preview() -> AppEnvironment {
        let keychain = KeychainStore()
        let api = APIClient()
        let auth = AuthManager(keychainStore: keychain)
        return AppEnvironment(
            apiClient: api,
            authManager: auth,
            keychainStore: keychain,
            walletService: WalletService(apiClient: api),
            paymentService: PaymentService(apiClient: api),
            sessionService: SessionService(authManager: auth, keychainStore: keychain),
            identityService: IdentityService(apiClient: api)
        )
    }
}
