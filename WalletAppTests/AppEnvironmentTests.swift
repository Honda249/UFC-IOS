import XCTest
@testable import WalletApp

final class AppEnvironmentTests: XCTestCase {
    func test_preview_returns_environment() {
        let env = AppEnvironment.preview()
        XCTAssertNotNil(env.apiClient)
        XCTAssertNotNil(env.authManager)
        XCTAssertNotNil(env.keychainStore)
        XCTAssertNotNil(env.walletService)
        XCTAssertNotNil(env.paymentService)
    }

    func test_package_linkage_does_not_trap() {
        PackageLinkage.verifyPackagesLinked()
    }
}
