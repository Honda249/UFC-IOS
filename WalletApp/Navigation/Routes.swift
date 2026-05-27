import Foundation

enum AppRoute: Hashable, Sendable {
    case home
    case transactionDetail(id: String)
    case settings
}

enum AuthRoute: Hashable, Sendable {
    case login
    case onboarding
}

enum AuthStatus: Sendable {
    case unknown
    case authenticated
    case unauthenticated
}

enum CustomerTier: Sendable {
    case basic
    case verified
}
