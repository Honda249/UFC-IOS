import SwiftUI

@main
struct WalletApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var appState = AppState()
    @State private var appRouter = AppRouter()
    @State private var authRouter = AuthRouter()
    @State private var environment = AppEnvironment.preview()

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
                .environment(appState)
                .environment(appRouter)
                .environment(authRouter)
                .onAppear {
                    PackageLinkage.verifyPackagesLinked()
                }
        }
    }
}
