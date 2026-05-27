import Foundation

@Observable
@MainActor
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) { path.append(route) }
    func pop() { guard !path.isEmpty else { return }; path.removeLast() }
    func popToRoot() { path.removeAll() }
    func replace(with route: AppRoute) { path = [route] }
}
