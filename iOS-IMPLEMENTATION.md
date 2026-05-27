# iOS-IMPLEMENTATION.md — SAR Wallet iOS Foundation Layer

> Canonical path: `iOS-IMPLEMENTATION.md`. Non-UI build plan. Every phase has exit criteria.
> A phase is done when exit criteria pass — not when code is merged.
> UI screens are planned separately after design is finalised.

---

## Guiding Principles

1. **Foundation first, UI later.** All infrastructure compiles, is tested, and is wired
   together before a single production screen is built.
2. **No mocks for security-critical paths.** Auth, Keychain, and idempotency are tested
   against real system APIs on a physical device, not simulator substitutes.
3. **Strict concurrency from day one.** `SWIFT_STRICT_CONCURRENCY = complete` is set at
   project creation, not retrofitted. Zero data-race warnings on every build.
4. **Every SPM dependency is justified.** New package proposals require a written security
   review before merging into the auth or network layer.
5. **Build with the Instruments trace open.** Every feature that touches a list or scroll
   view ships with a 120Hz hitch trace attached to the PR.

---

## Phase 0 — Xcode Project Skeleton (Day 1–2)

### Goals
- Clean Xcode project configured for Swift 6 strict concurrency.
- CI pipeline running on every push.
- All SPM dependencies resolved and audited.
- `AppEnvironment` DI container scaffolded with fake implementations.

### Deliverables

#### Xcode Project Settings
```
SWIFT_VERSION = 6
SWIFT_STRICT_CONCURRENCY = complete
SWIFT_TREAT_WARNINGS_AS_ERRORS = YES
ENABLE_TESTABILITY = YES (debug only)
GCC_OPTIMIZATION_LEVEL = s (Release)
STRIP_SWIFT_SYMBOLS = YES (Release)
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

#### Info.plist Entries
```xml
<!-- TLS 1.3 floor for production domain -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key><false/>
  <key>NSExceptionDomains</key>
  <dict>
    <key>api.wallet.sa</key>
    <dict>
      <key>NSExceptionMinimumTLSVersion</key>
      <string>TLSv1.3</string>
    </dict>
  </dict>
</dict>

<!-- ProMotion opt-in for custom animations -->
<key>CADisableMinimumFrameDuration</key><true/>
```

#### SPM Dependencies to Add
```
TrustKit                 (datatheorem/TrustKit)             security — cert pinning
swift-uuidv7             (mhayes853/swift-uuidv7, from 0.6.0) idempotency keys
swift-eventsource        (launchdarkly/swift-eventsource)   SSE live balance
Nuke                     (kean/Nuke)                        image caching
IOSSecuritySuite         (securing/IOSSecuritySuite)        jailbreak detection
```

#### `AppEnvironment` scaffold (minimal Phase 0; full container in [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) §11)

| Property | Introduced |
|----------|------------|
| `apiClient` | Phase 1 |
| `authManager`, `keychainStore`, `sessionService` | Phase 2 |
| `idempotencyStore`, `paymentService` (idempotency wiring) | Phase 3 |
| `appAttestService` | Phase 4 |
| `sseClient`, `identityService` | Phase 5 |
| `walletService` | Phase 1 stub → Phase 5 logic |

`AppState`, `AppRouter`, and `AuthRouter` are **not** on `AppEnvironment` — root `@State` + `.environment()` per §8.1.

```swift
// Phase 0: placeholder fakes — properties added as phases land
struct AppEnvironment {
    let apiClient: APIClient
    let authManager: AuthManager
    let keychainStore: KeychainStore
    let walletService: WalletService
    let paymentService: PaymentService

    static func production() -> AppEnvironment { fatalError("wired incrementally Phase 1–5") }
    static func preview() -> AppEnvironment {
        // Returns fake implementations for SwiftUI previews and unit tests
    }
}
```

**UI deferred:** [Nuke](https://github.com/kean/Nuke) (`LazyImage`) ships with the first screen that loads remote images — not in foundation phases.

#### Exit Criteria — Phase 0
- [ ] `xcodebuild -scheme WalletApp -destination 'generic/platform=iOS'` succeeds with 0 warnings
- [ ] `SWIFT_STRICT_CONCURRENCY = complete` produces 0 errors on clean build
- [ ] All 5 SPM packages resolve and build
- [ ] `AppEnvironment.preview()` compiles and returns a non-crashing environment
- [ ] CI runs `xcodebuild test` on every push to `main` and `feature/*`

---

## Phase 1 — Networking + TLS + Pinning (Days 3–5)

### Goals
- `APIClient` actor fully operational.
- TrustKit SPKI pinning active; dev build fails against Charles/Burp.
- `Endpoint` protocol with typed request/response.
- Baseline API error handling.

### Deliverables

#### `Infrastructure/Network/APIClient.swift`
- `actor APIClient` with `URLSession` configured via `URLSessionConfiguration.ephemeral`
  (no disk cache for auth responses) for auth paths; `.default` for paginated history.
- `TrustKitDelegate` as `URLSessionDelegate` forwarding to TrustKit's public key validator.
- `send<E: Endpoint>(_ endpoint: E)` — builds request, injects headers, decodes response.
- `APIError` enum covering `.http`, `.decoding`, `.network`, `.pinningFailed`, `.cancelled`.

#### `Infrastructure/Network/Endpoint.swift`
- `protocol Endpoint` with default implementations for `body`, `queryItems`,
  `requiresAuth`, `requiresAttestation`.
- `idempotencyKey` default: `nil` — mutating endpoints MUST override with a persisted UUIDv7
  key (PaymentEndpoints in Phase 3; never rely on the protocol default for payments).

#### `App/AppDelegate.swift`
```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions ...) -> Bool {
    TrustKit.initSharedInstance(withConfiguration: [
        kTSKSwizzleNetworkDelegates: false,
        kTSKPinnedDomains: [
            "api.wallet.sa": [
                kTSKEnforcePinning: true,
                kTSKIncludeSubdomains: false,
                kTSKPublicKeyHashes: [primarySPKI, backupSPKI]
            ]
        ]
    ])
    return true
}
```

#### Unit Tests — Phase 1
```
NetworkTests/
  APIClientTests.swift
    test_send_GET_decodes_response()
    test_send_401_without_retry_throws_http()
    test_send_pinning_failure_throws_pinningFailed()
    test_endpoint_default_idempotencyKey_is_nil()
    test_transfer_endpoint_requires_explicit_persisted_idempotencyKey()
    test_api_error_http_preserves_status_code()
    test_concurrent_send_operations_do_not_deadlock()
```
Use `URLProtocol` subclass as the fake transport — no real network in unit tests.

#### Exit Criteria — Phase 1
- [ ] `nscurl --ats-diagnostics https://api.wallet.sa` confirms TLS 1.3 minimum
- [ ] Routing dev build through Charles Proxy → TrustKit throws `TSKPinningValidatorError`
  (connection refused) — verified in device log
- [ ] All unit tests pass on device and simulator
- [ ] Zero Swift concurrency warnings

---

## Phase 2 — Authentication (Days 6–9)

### Goals
- `KeychainStore` operational with Secure Enclave-backed refresh token.
- `AuthManager` actor with concurrent-401-safe refresh serialisation.
- Biometric-gated session start.
- Login and logout flows wired end-to-end against the Zitadel backend (OIDC/device flow
  details live in backend auth docs — implemented in `SessionService` / `IdentityService`).

### Deliverables

#### `Infrastructure/Auth/KeychainStore.swift`
```swift
struct KeychainStore {
    // Access token — no extra access control
    func saveAccessToken(_ token: String) throws
    func loadAccessToken() throws -> String
    func deleteAccessToken()

    // Refresh token — Secure Enclave biometry gate
    func saveRefreshToken(_ token: String) throws  // uses SecAccessControl(.biometryCurrentSet)
    func loadRefreshToken() throws -> String       // triggers Face ID / Touch ID
    func deleteRefreshToken()

    // Device key ID (App Attest)
    func saveAttestKeyID(_ id: String) throws
    func loadAttestKeyID() throws -> String

    func clearAll()   // called on logout — clears all wallet.* items
}
```

#### `Infrastructure/Auth/Token.swift`
```swift
struct Token: Sendable, Codable {
    let value: String
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt.addingTimeInterval(-30) }
    // 30-second buffer prevents race between expiry check and request send
}
```

#### `Infrastructure/Auth/AuthManager.swift`
Full actor implementation per [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) §5. Key behaviours:
- `validToken()` — returns cached token if fresh; calls `performRefresh()` otherwise.
- `performRefresh()` — single in-flight `Task`, all concurrent callers await same task.
- On `refresh_token_revoked` body → `clearSession()` + publish `.sessionRevoked` signal.
- `clearSession()` — clears Keychain, in-memory token, cancels `refreshTask`.

#### `Application/SessionService.swift`
```swift
final class SessionService: Sendable {
    func login(otp: String, phone: String) async throws -> Void
    func logout() async
    func startBiometricSession() async throws // unlocks refresh token via Face ID
}
```

#### Unit Tests — Phase 2
```
AuthTests/
  AuthManagerTests.swift
    test_validToken_returns_cached_when_fresh()
    test_validToken_refreshes_when_expired()
    test_concurrent_401_triggers_single_refresh()     // launch 10 Tasks simultaneously
    test_refresh_token_revoked_clears_session()
    test_logout_clears_all_keychain_items()
    test_refresh_failure_propagates_to_all_waiters()

  KeychainStoreTests.swift  // MUST run on physical device
    test_save_and_load_access_token()
    test_refresh_token_protected_by_biometry()
    test_clear_all_removes_all_items()
    test_load_missing_key_throws()
    test_items_not_present_after_reinstall_first_launch()
```

**Keychain tests MUST run on a physical device.** Simulator Keychain behaviour diverges from
device on `SecAccessControl` operations.

#### Exit Criteria — Phase 2
- [ ] `test_concurrent_401_triggers_single_refresh` passes 100 iterations without flakiness
- [ ] `KeychainStore` tests pass on physical device (not simulator)
- [ ] Refresh token requires Face ID/Touch ID to load (verified manually on device)
- [ ] Force-quitting app and relaunching within 5 min → session resumes without login prompt
- [ ] Force-quitting app and relaunching after 20 min → refresh fires exactly once
- [ ] Deleting and reinstalling app → `clearAll()` on first launch, new login required

---

## Phase 3 — Idempotency Store + Payment Endpoints (Days 10–12)

### Goals
- `IdempotencyStore` with Core Data persistence.
- `PendingRequest` scan-and-retry on launch.
- `PaymentEndpoints` with persisted UUIDv7 keys.
- Double-tap guard in view model pattern.

### Deliverables

#### `CoreData/WalletModel.xcdatamodeld`
Single entity `PendingRequest` with attributes listed in [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) §6.2.
Index on `idempotencyKey` (unique) and `terminalResponseAt` (for scan query).

#### `Infrastructure/Idempotency/IdempotencyStore.swift`
```swift
actor IdempotencyStore {
    func findOrCreate(intentID: String, endpoint: String, payloadData: Data) async -> PendingRequestDTO
    func markTerminal(_ id: NSManagedObjectID) async
    func incrementAttempt(_ id: NSManagedObjectID, error: String) async
    func fetchRetryable() async -> [PendingRequestDTO]
    func purgeExpired() async    // items with terminalResponseAt > 25h ago
}
```

#### `Domain/Endpoints/PaymentEndpoints.swift`
```swift
struct TransferEndpoint: Endpoint {
    typealias Response = TransferResponse
    let draft: TransferDraft
    let persistedIdempotencyKey: String  // loaded from IdempotencyStore, not generated inline

    var path: String { "/v1/transfers" }
    var method: HTTPMethod { .POST }
    var body: (any Encodable)? { draft }
    var requiresAttestation: Bool { true }
    var idempotencyKey: String? { persistedIdempotencyKey }
}
```

#### `App/AppEnvironment+LaunchRetry.swift`
Launch-time retry scan — called in `@main` `init` before first scene activation.

#### Unit Tests — Phase 3
```
IdempotencyTests/
  IdempotencyStoreTests.swift
    test_findOrCreate_returns_same_key_for_same_intent()
    test_findOrCreate_creates_new_key_for_new_intent()
    test_markTerminal_prevents_retry()
    test_fetchRetryable_excludes_terminal_requests()
    test_fetchRetryable_excludes_requests_older_than_25h()
    test_purgeExpired_removes_old_terminal_rows()
    test_launch_retry_uses_same_idempotency_key()

PaymentEndpointTests.swift
    test_transfer_endpoint_carries_persisted_idempotency_key()
    test_idempotency_key_is_uuidv7()
    test_double_tap_guard_prevents_second_submission()  // view model test
    test_isSubmitting_reset_on_error()
    test_isSubmitting_reset_on_success()
```

#### Exit Criteria — Phase 3
- [ ] Submitting a transfer, killing the app before server responds, relaunching → same
  `Idempotency-Key` is retried (verify in backend logs)
- [ ] Rapid double-tap on "Send" button → backend receives exactly one request
  (verify via API log with unique idempotency key)
- [ ] `test_idempotency_key_is_uuidv7` — `UUID(uuidString: key)!.version == 7`
- [ ] Core Data store survives app kill and relaunch with pending rows intact

---

## Phase 4 — App Attest + Security Hardening (Days 13–15)

### Goals
- `AppAttestService` registration and per-request assertion signing.
- `JailbreakDetector` with risk-score backend reporting.
- Screenshot guard active on balance and card screens.
- `ScreenRecordingNotifier` publishing screenshot events.

### Deliverables

#### `Infrastructure/Attestation/AppAttestService.swift`
```swift
final class AppAttestService: @unchecked Sendable {
    // @unchecked Sendable: DCAppAttestService is thread-safe; wrapper methods are
    // invoked from APIClient actor context only — document invariant if extended.

    func registerIfNeeded() async throws
    // → generateKey() if no keyID in Keychain
    // → GET /v1/device/challenge
    // → attestKey(keyID, clientDataHash: SHA256(nonce))
    // → POST /v1/device/register

    func sign(_ body: Data) async throws -> String
    // → generateAssertion(keyID, clientDataHash: SHA256(body))
    // → base64url-encode for X-Attest-Signature header
}
```

#### `Infrastructure/Security/JailbreakDetector.swift`
```swift
struct JailbreakDetector {
    static func riskScore() -> Int {
        // IOSSecuritySuite checks: jailbreak, hook detection, debugger, dylib injection
        // Returns 0 (clean) to 100 (highly suspicious)
        // Result is sent to backend as X-Device-Risk-Score header on every request
    }
}
```

Integrate `riskScore()` result as a header in `APIClient.send()` for all authenticated
requests. Never use it to block the user locally.

#### `Infrastructure/Security/ScreenshotGuard.swift`
```swift
// View modifier — apply to all screens showing balance or card details
struct PrivacyShield: ViewModifier { ... }   // blur on scenePhase != .active

// UIViewRepresentable — wrap balance text in secure drawing path
struct SecureBalanceDisplay: UIViewRepresentable { ... }
```

#### Unit Tests — Phase 4
```
SecurityTests/
  AppAttestServiceTests.swift
    test_register_stores_key_id_in_keychain()
    test_register_handles_unsupported_device_gracefully()  // DCError.featureUnsupported
    test_sign_produces_non_empty_assertion()
    test_sign_uses_same_key_id_across_calls()

  JailbreakDetectorTests.swift
    test_risk_score_on_simulator_is_nonzero()    // simulator triggers some checks
    test_risk_score_returns_value_in_0_to_100()

  ScreenshotGuardTests.swift
    test_privacy_shield_blurs_when_scene_inactive()
    test_screenshot_notification_is_received()
```

#### Exit Criteria — Phase 4
- [ ] On a physical device: App Attest registration succeeds and `keyID` is in Keychain
- [ ] Backend receives `X-Attest-Signature` header on transfer endpoint calls
- [ ] App Attest gracefully degrades on simulator (no crash, `isSupported = false` logged)
- [ ] `X-Device-Risk-Score` header present on every authenticated request
- [ ] App Switcher screenshot shows blurred content when app is backgrounded (manual test)
- [ ] Balance display is absent from iOS screenshot (manual test via `UITextField` secure path)

---

## Phase 5 — State, Navigation, Real-Time (Days 16–18)

### Goals
- `AppState`, `AppRouter`, `AuthRouter` fully operational.
- SSE client live, reconnects on foreground.
- APNs integration for background balance refresh.
- All view models for wallet and payment flows scaffolded (no UI yet — just logic).

### Deliverables

#### `Navigation/AppRouter.swift` + `AuthRouter.swift`
Per [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) §8 — `@Observable @MainActor final class`, typed `[Route]` path.

#### `Infrastructure/RealTime/SSEClient.swift`
LDSwiftEventSource wrapper per [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) §9.2.
- Start/stop driven by `scenePhase` via `.onChange(of: scenePhase)` in root scene.
- Persists `lastEventID` in UserDefaults (non-sensitive — it is just a string cursor).
- Reconnection backoff: 1 s → 2 s → 4 s … 30 s cap, ± 15% jitter.

#### `Infrastructure/RealTime/PushNotificationHandler.swift`
- Register for APNs in `AppDelegate.applicationDidFinishLaunching`.
- On silent push `{"type": "balance-changed"}`: fire background
  `URLSessionConfiguration.background` fetch of `/v1/wallet/balance`.
- Notify `WalletViewModel` via `NotificationCenter` on completion.

#### View Model Scaffolds (logic only, no View)
```
WalletViewModel.swift         — balance, transaction history, cursor pagination
TransferViewModel.swift       — draft state, OTP flow, submission, isSubmitting guard
WithdrawalViewModel.swift     — draft state, bank selection, confirmation
OnboardingViewModel.swift     — KYC tier, Absher OTP, phone verification
LoginViewModel.swift          — phone input, OTP request, OTP verify
```

All view models are `@Observable @MainActor final class` with no side effects in `init`.

#### Unit Tests — Phase 5
```
StateTests/
  AppStateTests.swift
    test_auth_status_transitions_unknown_to_authenticated()
    test_session_revoked_sets_unauthenticated()

  AppRouterTests.swift
    test_push_appends_route()
    test_pop_removes_last()
    test_pop_to_root_clears_all()
    test_replace_sets_single_route()

  WalletViewModelTests.swift
    test_load_initial_populates_transactions()
    test_load_next_page_appends_transactions()
    test_load_next_page_no_op_when_loading()
    test_load_initial_sets_error_on_failure()
    test_has_more_false_when_next_cursor_nil()

  TransferViewModelTests.swift
    test_submit_sets_is_submitting_true()
    test_submit_resets_is_submitting_on_success()
    test_submit_resets_is_submitting_on_error()
    test_double_submit_guard_prevents_second_call()

SSETests/
  SSEClientTests.swift
    test_connect_starts_event_source()
    test_disconnect_stops_event_source()
    test_balance_event_invokes_callback()
    test_reconnect_passes_last_event_id()
    test_backoff_does_not_exceed_30s()
```

#### Exit Criteria — Phase 5
- [ ] App routes to correct root (auth vs main) based on `appState.authStatus`
- [ ] Killing the app during a transfer and relaunching → router navigates to correct screen,
  pending request retried with same idempotency key
- [ ] SSE connects on foreground, disconnects on background (verified in proxy log)
- [ ] APNs silent push triggers a balance refresh (verified with `xcrun simctl push`)
- [ ] All view model unit tests pass; `SWIFT_STRICT_CONCURRENCY = complete` on every build
  (compile-time data-race checks; add XCTest concurrency stress tests where flakiness is a risk)

---

## Phase 6 — Integration + Hardening (Days 19–21)

### Goals
- Full end-to-end integration test against staging backend.
- Instruments trace on all list scrolls — zero hitches at 120 Hz.
- Security review checklist complete.
- TestFlight internal build.

### Deliverables

#### Integration Test Suite (XCTest, physical device)
```
IntegrationTests/
  AuthFlowIntegrationTests.swift
    test_login_stores_tokens_in_keychain()
    test_refresh_on_expired_access_token()
    test_concurrent_requests_single_refresh()

  PaymentFlowIntegrationTests.swift
    test_transfer_end_to_end_with_idempotency()
    test_transfer_retry_same_key_no_duplicate()

  SSEIntegrationTests.swift
    test_balance_update_received_within_5s_of_backend_event()
```

Integration tests target a staging backend with test accounts.
They run in CI on a physical device connected via `devicefarm` or local Xcode Cloud.

#### Performance Benchmarks
```
PerformanceTests/
  TransactionListPerformanceTests.swift
    test_scroll_1000_transactions_zero_hitches()   // measure in Instruments, assert < 0.1% hitch
    test_cold_launch_to_interactive_under_2s()
    test_token_refresh_under_500ms_p99()
```

#### Security Checklist
- [ ] No `print()` or `NSLog()` of tokens, amounts, or PII in Release build
  (grep: `print.*token\|print.*SAR\|print.*national`)
- [ ] No secrets, API keys, or URLs hardcoded in source — all in Vault-backed config service
- [ ] TrustKit config has two SPKI hashes per domain (rotation runbook exists)
- [ ] App Attest enabled and verified on physical device
- [ ] `xcrun codesign -dv --verbose=4 WalletApp.app` shows hardened runtime entitlements
- [ ] Screenshot test: balance screen absent from iOS Photos after screenshot
- [ ] App Switcher: blurred content when app backgrounds
- [ ] Jailbreak risk score sent to backend on every request (verify in proxy log)
- [ ] All Keychain items use `WhenUnlockedThisDeviceOnly` (verify with `security` CLI dump)

#### Exit Criteria — Phase 6
- [ ] End-to-end login → transfer → verify balance flow passes on physical device
  against staging backend
- [ ] Instruments Animation Hitches: 0% hitch time on 1,000-item transaction list scroll
- [ ] Instruments Hangs: 0 hangs (> 250 ms main thread block) during 5-min smoke test
- [ ] Security checklist fully signed off
- [ ] Internal TestFlight build submitted and approved

---

## Testing Summary

| Phase | Unit Tests | Integration | Device Required | Coverage Gate |
|-------|-----------|-------------|----------------|---------------|
| 0 | DI scaffolding | — | No | compiles |
| 1 | Network, TrustKit | — | No (URLProtocol) | 80% |
| 2 | Auth, Keychain | — | **Yes (Keychain biometry)** | 80% |
| 3 | Idempotency, Core Data | — | No | 80% |
| 4 | App Attest, Security | — | **Yes (SE)** | 80% |
| 5 | State, ViewModels, SSE | — | No | 80% |
| 6 | — | Full E2E | **Yes** | — |

---

## Definition of Done (every PR)

- [ ] `xcodebuild build-for-testing` succeeds with 0 warnings
- [ ] `SWIFT_STRICT_CONCURRENCY = complete` produces 0 errors
- [ ] All unit tests pass on both simulator and physical device
- [ ] No `UUID()` used for idempotency keys (grep: `UUID()` in `Endpoints/` → 0 results)
- [ ] Payment/transfer endpoints override `idempotencyKey` with persisted keys (grep: no payment `Endpoint` relying on default `nil`)
- [ ] No `UserDefaults` for tokens or sensitive data (grep: `UserDefaults.*token` → 0 results)
- [ ] No `ObservableObject` or `@Published` in new files (grep → 0 results)
- [ ] No `LazyVStack` in list contexts > 50 items (code review)
- [ ] No `Double` or `Float` for monetary values (grep: `Double.*amount\|Float.*amount` → 0)
- [ ] No `NumberFormatter()` or `DateFormatter()` constructed inside `body` (code review)
- [ ] No `.task { }` wrapping payment submission calls (code review)
- [ ] Instruments trace attached for any PR touching a scrollable list
- [ ] [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) ADR updated if a design decision was made

---

## SPM Version Lock

```swift
// Package.resolved — pin exact versions, review before any update
TrustKit              3.0.0
swift-uuidv7          0.6.1    // check for RFC 9562 conformance note on each update
swift-eventsource     3.0.0
Nuke                  12.0.0
IOSSecuritySuite      1.9.0
```

Security-related packages (`TrustKit`, `IOSSecuritySuite`) require a dedicated security
review in the PR description before any version bump.
