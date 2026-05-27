import Foundation

@Observable
@MainActor
final class AuthRouter {
    var path: [AuthRoute] = []

    func push(_ route: AuthRoute) { path.append(route) }
    func pop() { guard !path.isEmpty else { return }; path.removeLast() }
    func popToRoot() { path.removeAll() }
}
