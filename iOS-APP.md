# iOS-APP.md — SAR Wallet iOS App

> **Companion docs:** [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) (layers, APIs, ADRs) · [iOS-IMPLEMENTATION.md](iOS-IMPLEMENTATION.md) (phased build plan)
>
> Authoritative rules for AI-assisted development on the iOS client.
> Every suggestion, generated snippet, refactor, or review MUST comply with these rules.
> No exceptions without an explicit `# OVERRIDE:` comment and team sign-off.

---

## Project Context

We are building the native iOS (SwiftUI, Swift 6) client for a SAMA-regulated SAR fiat
e-wallet. The backend is Go + PostgreSQL 18 with Zitadel auth (short-lived JWTs 5–15 min +
rotating opaque refresh tokens), UUIDv7 idempotency keys, TLS 1.3, and mTLS for partner
integrations.

**This file covers the non-UI foundation layer only.**
UI components, design tokens, and screen layouts are tracked separately once design is finalised.

**Technology anchors:**
- Language: **Swift 6**, strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY = complete`)
- UI framework: **SwiftUI** (iOS 17+ minimum deployment target)
- Networking: **URLSession + async/await** (no Alamofire, no third-party HTTP library)
- State: **`@Observable` macro** (no TCA, no ObservableObject/Combine pipelines)
- Navigation: **`NavigationStack` + `Router`** (`@Observable` class, one per flow)
- Token storage: **Keychain** via hand-rolled `KeychainStore` (~60 lines, no wrapper library)
- Idempotency: **UUIDv7** via `mhayes853/swift-uuidv7` SPM package
- Certificate pinning: **TrustKit** (datatheorem/TrustKit, SPM)
- Real-time: **LDSwiftEventSource** (LaunchDarkly, SPM) for SSE balance stream
- Image caching: **Nuke** (kean/Nuke, SPM)
- Device attestation: **DCAppAttestService** (Apple native, iOS 14+)
- Persistence: **Core Data** for pending requests / idempotency store; **UserDefaults** never for sensitive data

---

## Non-Negotiable Rules

Violations of these rules cause the PR to be rejected automatically.

---

### 1. Strict Concurrency — Swift 6

```
RULE: The project compiles with zero warnings under SWIFT_STRICT_CONCURRENCY = complete.
      Every type that crosses an isolation boundary is explicitly annotated.
```

- View models are `@MainActor` — they are owned by the UI thread.
- Network and auth actors are **not** `@MainActor` — they run on the cooperative thread pool.
- Domain value types (`struct`, `enum`) must be `Sendable`.
- Passing a non-`Sendable` reference across isolation boundaries is a compile error, not a TODO.
- No `@unchecked Sendable` without a written comment explaining the invariant that makes it safe.

```swift
// CORRECT
@MainActor
final class WalletViewModel: ObservableObject { ... }   // wrong — see Rule 4
// use @Observable instead — see Rule 4

@Observable
@MainActor
final class WalletViewModel {
    var balance: Decimal = 0
}

// Network actor — NOT MainActor
actor APIClient {
    func send<E: Endpoint>(_ e: E) async throws -> E.Response { ... }
}
```

---

### 2. Networking — URLSession + async/await Only

```
RULE: All HTTP communication uses URLSession with async/await.
      No Alamofire. No Moya. No third-party HTTP library in the auth-critical path.
```

- The central type is `actor APIClient` — one instance per app lifetime, injected via DI.
- All endpoints are modelled as `struct` conformances to `protocol Endpoint`.
- Retry logic (401 → refresh → retry once) lives **inside** `APIClient.send()`, not in call sites.
- `allowRetry: Bool = true` prevents infinite refresh loops on persistent 401s.
- Decoding happens inside `APIClient` — call sites receive typed `Response` values, never `Data`.
- Every mutating request (`POST`, `PATCH`, `DELETE`) carries an `Idempotency-Key` header — see Rule 6.
- **No fire-and-forget network calls.** Every `Task { }` that makes a network call is either owned by a view model (cancelled on logout) or uses a `URLSessionConfiguration.background` session.

```swift
protocol Endpoint {
    associatedtype Response: Decodable & Sendable
    var path: String { get }
    var method: HTTPMethod { get }
    var body: (any Encodable)? { get }
    var queryItems: [URLQueryItem]? { get }
    var requiresAuth: Bool { get }
    var requiresAttestation: Bool { get }
    /// UUIDv7 string. Non-nil for mutating requests that carry Idempotency-Key.
    /// Payment/transfer endpoints MUST use a key persisted via IdempotencyStore (Rule 7).
    var idempotencyKey: String? { get }
}
```

Full default implementations: [iOS-ARCHITECTURE.md §4.2](iOS-ARCHITECTURE.md).

---

### 3. TLS 1.3 + Certificate Pinning

```
RULE: TLS 1.3 is the minimum. Certificate pinning via TrustKit is active on all
      production domains. Two SPKI hashes (primary + backup) are pinned per domain.
```

- `Info.plist`: `NSExceptionMinimumTLSVersion = TLSv1.3` for every production domain.
- TrustKit is configured in `AppDelegate` before any network request fires.
- Pin SPKI hashes (not the full leaf cert) so rotation does not require an app update.
- **Always pin two keys** — TrustKit refuses to start with one as a correctness guard; the backup is your rotation escape hatch.
- Certificate rotation runbook must be updated every time a TrustKit config changes.
- Cipher suites are **not** explicitly configured — iOS enforces ATS-appropriate ciphers; TLS 1.3 mandates only strong ciphers by spec.
- Pinning protects honest users from MITM on hostile Wi-Fi. It does **not** protect against Frida on jailbroken devices — combine with App Attest for that threat model.

```swift
// AppDelegate.swift — configure before any URLSession
TrustKit.initSharedInstance(withConfiguration: [
    kTSKSwizzleNetworkDelegates: false,          // explicit delegation, no swizzle
    kTSKPinnedDomains: [
        "api.wallet.sa": [
            kTSKEnforcePinning: true,
            kTSKIncludeSubdomains: false,
            kTSKPublicKeyHashes: [
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",   // primary SPKI SHA-256 base64
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="    // backup SPKI SHA-256 base64
            ]
        ]
    ]
])
```

---

### 4. State Management — `@Observable` Only

```
RULE: Use the @Observable macro (iOS 17+) for all view models and shared state.
      Never use ObservableObject, @Published, or @StateObject for new code.
      Never adopt TCA.
```

- View models are `@Observable @MainActor final class`.
- Views inject view models via `@State var vm = ViewModel()` or environment.
- Do **not** put side effects (NotificationCenter, UserDefaults reads, network calls) inside `init` — `@Observable` instances may be constructed multiple times during SwiftUI view-rebuild cycles (confirmed Jesse Squires, 2024). Use `.task` on the view or a lazy initialisation pattern.
- A single `@Observable` `AppState` holds cross-cutting session state (auth status, current user). Everything else is local to the screen that owns it.

```swift
// WRONG
class WalletVM: ObservableObject {
    @Published var balance: Decimal = 0
}

// CORRECT
@Observable
@MainActor
final class WalletViewModel {
    var balance: Decimal = 0          // view re-renders only when this changes
    var transactions: [Transaction] = []
    private(set) var isLoading = false

    private let api: APIClient        // injected, not constructed here

    func load() async {
        isLoading = true
        defer { isLoading = false }
        balance = try await api.send(GetBalanceEndpoint())
    }
}
```

---

### 5. Authentication — `AuthManager` Actor

```
RULE: Token refresh is serialised inside an actor. Concurrent 401s MUST NOT trigger
      multiple parallel refresh requests. The actor is the single source of truth
      for the current access token.
```

The "thundering herd" problem: N views fire parallel requests; all N get 401 simultaneously;
naive code launches N refresh calls that race and invalidate each other's rotating refresh
tokens — causing permanent logout. The actor with a cached `Task` prevents this.

```swift
actor AuthManager {
    private let keychainStore: KeychainStore
    private let tokenService: TokenService
    private var accessToken: Token?
    private var refreshTask: Task<Token, Error>?

    /// Returns a valid (non-expired) access token, refreshing exactly once if needed.
    func validToken() async throws -> String {
        if let t = accessToken, !t.isExpired { return t.value }
        return try await performRefresh().value
    }

    /// Called by APIClient on 401 (after checking refresh_token_revoked). Forces one refresh.
    func refreshSession() async throws -> String {
        accessToken = nil
        return try await performRefresh().value
    }

    private func performRefresh() async throws -> Token {
        // Re-use in-flight refresh task — all concurrent callers await the same Task.
        if let existing = refreshTask { return try await existing.value }
        let task = Task<Token, Error> {
            let newToken = try await tokenService.refresh(using: keychainStore.refreshToken())
            self.accessToken = newToken
            try keychainStore.save(accessToken: newToken)
            return newToken
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    func clearSession() {
        accessToken = nil
        refreshTask?.cancel()
        refreshTask = nil
        keychainStore.clearAll()
    }
}
```

`TokenService` performs the refresh HTTP call to Zitadel (`POST /oauth/v2/token`). See
[iOS-ARCHITECTURE.md §5](iOS-ARCHITECTURE.md) and Phase 2 in [iOS-IMPLEMENTATION.md](iOS-IMPLEMENTATION.md).

**Additional auth rules:**
- On `clearSession()` (logout or refresh failure): purge Keychain, in-memory cache, pending
  `PendingRequest` Core Data rows (non-terminal), and all in-flight `Task` references.
- Background re-entry (`scenePhase → .active` after > 15 min): access token has expired;
  the next call into `validToken()` triggers refresh automatically. No special foreground
  handling needed if the actor is correct.
- Re-use of a revoked refresh token must result in immediate forced logout, not a retry.
  The backend returns `401` with `{"error": "refresh_token_revoked"}` — check for this
  specifically before the one-retry loop.

---

### 6. Keychain — Token Storage

```
RULE: Access tokens and refresh tokens are stored ONLY in Keychain.
      Never in UserDefaults, NSCache, static variables, or UserActivity.
```

- **Access token**: `kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Refresh token**: `kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  PLUS `SecAccessControlCreateWithFlags(.biometryCurrentSet)`.
  - `.biometryCurrentSet` (not `.biometryAny`) invalidates the item if new biometrics are
    enrolled — prevents an attacker who adds their own fingerprint from gaining access.
  - The Secure Enclave releases the key; it is never passed to `LAContext.evaluatePolicy`
    and trusting that boolean is not the security boundary.
- `ThisDeviceOnly` prevents iCloud Keychain sync and encrypted iTunes backup leakage.
- **Keychain items survive app deletion by default.** Clear them in a first-launch check.
- On jailbroken devices, Keychain can be read by any app — combine with App Attest and
  jailbreak detection to raise risk score (not block outright).

```swift
// Minimal KeychainStore — hand-rolled, no third-party wrapper in this path
struct KeychainStore {
    static func save(_ data: Data, forKey key: String, access: SecAccessControl? = nil) throws
    static func load(forKey key: String) throws -> Data
    static func delete(forKey key: String)
}
// Access control for refresh token:
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    .biometryCurrentSet,
    nil
)!
```

---

### 7. Idempotency Keys — UUIDv7, Persisted Before Send

```
RULE: Every mutating network request carries a UUIDv7 Idempotency-Key header.
      The key is generated and persisted to Core Data BEFORE the request fires.
      The same key is reused on every retry, including across app kills.
```

- Use `mhayes853/swift-uuidv7` — RFC 9562-compliant, monotonic even on clock skew, not
  Foundation's `UUID()` (which generates v4, unordered).
- The key is **bound to the user intent** (e.g., the draft transfer record), not the
  network call. One transfer attempt = one key, forever.
- Storage schema (Core Data entity `PendingRequest`):
  ```
  idempotencyKey: String       // UUIDv7 string
  intentID: String             // client-side dedup key (e.g. transfer draft ID)
  endpoint: String             // route identifier
  payloadData: Data            // JSON-encoded request body
  createdAt: Date
  attempts: Int16
  lastError: String?
  terminalResponseAt: Date?    // set when server returns 2xx or non-retryable 4xx
  ```
- On app launch, scan for pending requests with `terminalResponseAt == nil` and retry them.
- Purge rows with `terminalResponseAt` older than 25 hours (backend deduplication window is 24h).
- **Do NOT use Stripe's iOS SDK as a reference for idempotency** — `stripe-ios` does not
  auto-inject `Idempotency-Key` headers (confirmed in `StripeCore/STPAPIClient.swift`). You
  must build this yourself.

---

### 8. Device Attestation — App Attest

```
RULE: DCAppAttestService is initialised at first launch. Every sensitive request payload
      is signed with the attested key. The Go backend verifies attestations.
```

- App Attest attestation is hardware-rooted in Secure Enclave — it cannot be forged by Frida
  or method swizzling from inside the app.
- Graceful degradation: `DCAppAttestService.isSupported` is `false` on jailbroken devices,
  simulators, and some Mac Catalyst targets. Log the failure and flag the session with reduced
  trust on the backend — do not block login.
- Store the attested key ID in Keychain (not UserDefaults). Regenerate if attestation fails
  with `DCError.invalidKey`.

---

### 9. Performance — Main Thread Budget

```
RULE: The main thread has a hard budget of 8.3 ms per frame (120 Hz).
      Realistic budget after system overhead is ~5 ms.
      Any work that cannot complete in 5 ms MUST run off the main thread.
```

- `@MainActor` is used **only** on: view models, types that touch UIKit/SwiftUI, `Router`.
- Network actors, auth actors, crypto operations, JSON decoding, Core Data writes: **not**
  `@MainActor`.
- Use `List` (UICollectionView-backed) for transaction history — **never** `LazyVStack` in a
  `ScrollView` for lists > ~50 items. `List` gives buttery 120 fps; `LazyVStack` hitches.
- No string interpolation with `NumberFormatter` / `DateFormatter` inside `body` — create
  formatters once as static or lazy properties, never on every render.
- No `.filter`, `.sorted`, `.map` on large arrays inside `body` — derive in the view model,
  cache the result.
- `AsyncImage` does **not** cache — use `Nuke`'s `LazyImage` for all remote images.
- ProMotion (120 Hz) requires `CADisableMinimumFrameDuration = YES` in Info.plist. For
  scrolling it is automatic on Pro hardware; explicit opt-in is for custom animations.

---

### 10. Navigation — `NavigationStack` + Router

```
RULE: Navigation state is owned by an @Observable Router per flow.
      Never manipulate NavigationPath by index — use [Route] array directly.
```

- Auth flow router: `AuthRouter`. Main app flow router: `AppRouter`.
- `NavigationPath` can only `removeLast(k)` — cannot remove from the middle. Use
  `[Route]` (typed array) as the path binding to allow surgical stack manipulation
  (e.g., popping to the home screen from deep inside a payment confirmation).
- Deep link handling resolves to a `Route` enum case and appends to the active router.
- No UIKit `UINavigationController` wrapping unless a specific screen requires it.

```swift
@Observable
@MainActor
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute)  { path.append(route) }
    func pop()                    { path.removeLast() }
    func popToRoot()              { path.removeAll() }
    func replace(with route: AppRoute) { path = [route] }
}
```

---

### 11. Real-Time Balance — SSE + APNs

```
RULE: Foreground balance updates use SSE (LDSwiftEventSource).
      Background balance updates use APNs silent pushes → refetch.
      Neither WebSocket nor SSE survive iOS app suspension — APNs is the only
      correct channel for background updates.
```

- Start the SSE stream in `scenePhase == .active`, stop in `scenePhase != .active`.
- Handle `Last-Event-ID` resume: persist the last received event ID; pass it on reconnect.
- Reconnection backoff: start at 1 s, cap at 30 s, jitter ± 15%.
- On APNs push receipt (background): fetch balance diff via a lightweight
  `URLSessionConfiguration.background` request; update Core Data; badge if needed.

---

### 12. Security Hardening

```
RULE: The following security measures are non-optional before TestFlight.
```

**Screenshot / screen recording prevention:**
- Overlay a blur in `scenePhase != .active` to protect the App Switcher snapshot.
- Wrap balance and card number fields in a `UITextField(isSecureTextEntry: true)` view
  (renders through iOS secure drawing path, excluded from screenshots and screen recordings).
- Subscribe to `UIApplication.userDidTakeScreenshotNotification` to log the event.

**Jailbreak / integrity detection:**
- Integrate `IOSSecuritySuite` for jailbreak, hook, debugger, and dylib-injection checks.
- Treat results as **risk signals sent to the backend** — not as yes/no gates. IOSSecuritySuite
  is publicly bypassable via Frida; it raises attacker cost, it does not block a determined
  adversary.
- Also check `_dyld_image_count` for unexpected injected dylibs.
- Combine with App Attest for a hardware-rooted signal that Frida cannot forge.

**Runtime protections:**
- Enable full compiler optimizations in Release builds — removes debug metadata.
- No logging of tokens, OTPs, amounts, or national IDs to `OSLog` in Release. Use
  `#if DEBUG` guards around all sensitive log calls.
- Disable `OS_ACTIVITY_MODE` in Release scheme.

---

### 13. Task Lifecycle — No Orphan Tasks

```
RULE: Every Task that makes a network call is either:
  (a) owned by a view model and cancelled on logout, OR
  (b) a URLSessionConfiguration.background task for payment-critical requests.
Never use .task { } modifier for mutating API calls (payment submission, transfer, withdrawal).
```

- SwiftUI's `.task { }` modifier cancels when the view disappears — including during
  re-layout passes where the view briefly leaves the hierarchy.
- For payment submission: create `Task { await vm.submitTransfer() }` inside a `Button`
  action, owned by the view model. The view model is `@MainActor` and holds a reference
  to the task, cancelled only on explicit logout.
- For background payment-confirmation: use `URLSessionConfiguration.background(withIdentifier:)`
  so iOS continues the transfer even if the app is suspended. Combine with idempotency keys.
- Catch `URLError.cancelled` everywhere — it fires on `.task` cancellation, `refreshable`
  gesture completion, and background session teardown.

---

### 14. Double-Submission Prevention

```
RULE: Every payment action must be protected against double-tap and navigation-race
      double-submission at the UI layer AND at the idempotency layer.
```

The belt (idempotency key — Rule 7) handles network-level duplicates.
The suspenders (UI guard) prevent the second request from being sent at all:

```swift
// In Button action — synchronous guard before the async work
Button("Send") {
    guard !vm.isSubmitting else { return }
    vm.isSubmitting = true          // synchronous — blocks second tap immediately
    Task { await vm.submitTransfer() }
}
.disabled(vm.isSubmitting)
```

- `isSubmitting` is set to `true` synchronously inside the button action, before `await`.
- It is reset to `false` in a `defer` block at the end of the view model method, whether
  the request succeeds or fails.

---

### 15. Money Display

```
RULE: Amounts are always displayed as formatted SAR strings.
      Never display raw halala integers to users.
      Never compute display amounts with floating-point arithmetic.
```

- Backend sends amounts as `String` (e.g., `"150.50"`). Decode as `Decimal`.
- Format using `NumberFormatter` with `numberStyle = .currency`, `currencyCode = "SAR"`.
- Create formatters as `static let` properties — never inside `body` or `init`.
- `Decimal` is the only numeric type allowed for monetary values in the iOS codebase.
  `Double`, `Float`, `CGFloat` for money is a compile-error-worthy violation.

---

## What Claude Must Never Do

- **Never suggest `UUID()` for idempotency keys.** Use `UUID7()` from `swift-uuidv7`.
- **Never suggest `UserDefaults` for tokens, keys, or sensitive data.** Keychain only.
- **Never suggest `ObservableObject` / `@Published` / `@StateObject` for new code.** `@Observable`.
- **Never suggest TCA.** `@Observable` + `NavigationStack` is the architecture for this app.
- **Never suggest Alamofire or Moya** in the auth/network path.
- **Never suggest `LAContext.evaluatePolicy` boolean as a security boundary.** The security is
  releasing a Keychain item gated by `SecAccessControl(.biometryCurrentSet)` — not trusting
  a boolean from user space.
- **Never suggest placing a payment submission inside `.task { }`.** Own the `Task` in the VM.
- **Never suggest `LazyVStack` for transaction lists > 50 items.** Use `List`.
- **Never suggest `AsyncImage` for remote images in lists.** Use `Nuke`'s `LazyImage`.
- **Never suggest `Double` or `Float` for monetary values.** Use `Decimal`.
- **Never suggest inline `NumberFormatter()` or `DateFormatter()` inside `body`.** Static/lazy only.
- **Never suggest skipping idempotency keys** because a request "seems safe" to retry without one.
- **Never suggest `kSecAttrAccessibleAlways`** — it is deprecated and insecure.
- **Never suggest `@unchecked Sendable`** without a written safety invariant comment.
