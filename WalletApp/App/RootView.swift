import SwiftUI

/// Foundation shell — production screens added after design.
struct RootView: View {
    /// Injected DI container — used by child views/view models in later phases.
    let environment: AppEnvironment

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var appRouter
    @Environment(AuthRouter.self) private var authRouter
    var body: some View {
        Group {
            switch appState.authStatus {
            case .authenticated:
                authenticatedRoot
            case .unauthenticated, .unknown:
                authRoot
            }
        }
    }

    private var authenticatedRoot: some View {
        NavigationStack(path: Bindable(appRouter).path) {
            FoundationPlaceholderView(title: "Wallet", subtitle: "Phase 0 — foundation skeleton")
                .navigationDestination(for: AppRoute.self) { route in
                    FoundationPlaceholderView(title: String(describing: route), subtitle: "Route placeholder")
                }
        }
    }

    private var authRoot: some View {
        NavigationStack(path: Bindable(authRouter).path) {
            FoundationPlaceholderView(title: "Sign in", subtitle: "Auth flow — Phase 2")
                .navigationDestination(for: AuthRoute.self) { route in
                    FoundationPlaceholderView(title: String(describing: route), subtitle: "Route placeholder")
                }
        }
    }
}

private struct FoundationPlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
