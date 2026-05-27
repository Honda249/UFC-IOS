import Foundation

@Observable
@MainActor
final class AppState {
    var authStatus: AuthStatus = .unknown
    var currentUserID: String?
    var currentTier: CustomerTier?
    var sessionRevokedAlert = false
}
