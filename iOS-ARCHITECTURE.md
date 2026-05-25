# iOS-ARCHITECTURE.md — SAR Wallet iOS App (Foundation Layer)

> **Companion docs:** [iOS-APP.md](iOS-APP.md) (non-negotiable rules) · [iOS-IMPLEMENTATION.md](iOS-IMPLEMENTATION.md) (phased build plan)
>
> Non-UI foundation: networking, auth, idempotency, state, navigation, security.
> UI components and screen-level architecture are tracked separately once design is finalised.

---

## 1. High-Level Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SwiftUI Views (@MainActor)                     │
│              NavigationStack + Router (one per flow)                    │
└──────────────────────────┬──────────────────────────────────────────────┘
                           │ @Observable ViewModels (@MainActor)
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Application Layer                                │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │  WalletSvc  │  │  PaymentSvc  │  │  IdentitySvc │  │  SessionSvc │  │
│  │ (balance,   │  │ (transfer,   │  │ (KYC, OTP,   │  │ (login,     │  │
│  │  history)   │  │  withdrawal) │  │  Absher)     │  │  logout)    │  │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘  │
└─────────┼────────────────┼─────────────────┼─────────────────┼─────────┘
          │                │                 │                 │
          └────────────────┴─────────────────┴────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       Infrastructure Layer                              │
│  ┌──────────────┐  ┌────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  APIClient   │  │AuthManager │  │IdempotencyStr│  │  SSEClient   │  │
│  │  (actor)     │  │  (actor)   │  │  (Core Data) │  │ (LDEventSrc) │  │
│  └──────┬───────┘  └─────┬──────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ TrustKit     │  │KeychainStore│  │ AppAttest   │  │  PushHandler │  │
│  │ (SPKI pins)  │  │ (SE-backed) │  │(DCAppAttest)│  │  (APNs)      │  │
│  └──────────────┘  └─────────────┘  └─────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │ TLS 1.3 + certificate pinning
                                    ▼
                         ┌─────────────────────┐
                         │   Go Backend API    │
                         │  api.wallet.sa/v1   │
                         └─────────────────────┘
```

---

## 2. Layer Definitions

### 2.1 Infrastructure Layer
Owns all I/O: HTTP, Keychain, Core Data, push notifications, SSE.
Contains no business logic. All types in this layer are `actor` or `struct`.
View models and services never import `Security`, `CoreData`, or `Network` directly —
they call infrastructure interfaces.

### 2.2 Application (Service) Layer
Orchestrates infrastructure. Each service maps to a backend domain:
- `WalletService` — balance, transaction history, pagination cursor
- `PaymentService` — transfer, withdrawal, top-up; owns saga retry on app relaunch
- `IdentityService` — KYC flow, Absher OTP verification, device registration
- `SessionService` — login, logout, token lifecycle events

Services are `@MainActor`-free structs or classes injected into view models.
They call `APIClient` (actor) via `await`.

### 2.3 View Model Layer
`@Observable @MainActor final class`. One per screen (or per logical section of a screen).
Translates between domain types and display types.
Owns `isLoading`, `error`, and `isSubmitting` state.
All `Task` references for in-flight network calls are stored here and cancelled on logout.

### 2.4 View Layer (future, design-pending)
Pure SwiftUI views. Zero business logic. Zero direct API calls.
All data flows in through the view model.

---

## 3. Package Structure

```
WalletApp/
├── App/
│   ├── WalletApp.swift          ← @main, AppDelegate, TrustKit init, App Attest
│   ├── AppDelegate.swift        ← TrustKit config, APNs registration
│   └── AppEnvironment.swift     ← DI container (constructed once, injected via .environment)
│
├── Infrastructure/
│   ├── Network/
│   │   ├── APIClient.swift      ← actor APIClient, URLSession config
│   │   ├── Endpoint.swift       ← protocol Endpoint + HTTPMethod
│   │   ├── APIError.swift       ← typed error enum
│   │   └── TrustKitDelegate.swift  ← URLSessionDelegate for SPKI pinning
│   ├── Auth/
│   │   ├── AuthManager.swift    ← actor AuthManager, refresh serialisation
│   │   ├── KeychainStore.swift  ← ~60 lines, SecItemAdd/Copy/Delete
│   │   ├── TokenService.swift   ← refresh HTTP to Zitadel (no auth header)
│   │   └── Token.swift          ← Token struct, isExpired computed var
│   ├── Idempotency/
│   │   ├── IdempotencyStore.swift  ← Core Data CRUD for PendingRequest
│   │   └── PendingRequest+CoreData.swift
│   ├── Attestation/
│   │   └── AppAttestService.swift  ← DCAppAttestService wrapper
│   ├── RealTime/
│   │   ├── SSEClient.swift      ← LDSwiftEventSource wrapper, reconnect logic
│   │   └── PushNotificationHandler.swift
│   └── Security/
│       ├── JailbreakDetector.swift  ← IOSSecuritySuite wrapper, risk score
│       └── ScreenshotGuard.swift    ← scenePhase blur + secure field wrapper
│
├── Application/
│   ├── WalletService.swift
│   ├── PaymentService.swift
│   ├── IdentityService.swift
│   └── SessionService.swift
│
├── Domain/
│   ├── Models/
│   │   ├── Money.swift          ← Decimal wrapper, SAR formatting
│   │   ├── Transaction.swift
│   │   ├── Transfer.swift
│   │   └── Account.swift
│   └── Endpoints/
│       ├── WalletEndpoints.swift
│       ├── PaymentEndpoints.swift
│       └── IdentityEndpoints.swift
│
├── Navigation/
│   ├── AppRouter.swift          ← @Observable, [AppRoute] path
│   ├── AuthRouter.swift         ← @Observable, [AuthRoute] path
│   └── Routes.swift             ← AppRoute + AuthRoute enums
│
└── CoreData/
    └── WalletModel.xcdatamodeld ← PendingRequest entity only
```

---

## 4. Networking Architecture

### 4.1 `APIClient` Actor

```swift
actor APIClient {
    private let session: URLSession             // TrustKit-delegated
    private let auth: AuthManager
    private let appAttest: AppAttestService
    private let decoder: JSONDecoder
    private let baseURL: URL

    func send<E: Endpoint>(
        _ endpoint: E,
        allowRetry: Bool = true
    ) async throws -> E.Response {
        var request = try buildURLRequest(for: endpoint)

        // Auth header
        if endpoint.requiresAuth {
            let token = try await auth.validToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Idempotency header — mandatory for all mutating requests
        if let key = endpoint.idempotencyKey {
            request.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        }

        // App Attest signature (sensitive endpoints)
        if endpoint.requiresAttestation {
            let bodyData = try encodeBody(endpoint.body)
            let sig = try await appAttest.sign(bodyData)
            request.setValue(sig, forHTTPHeaderField: "X-Attest-Signature")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // One-shot refresh on 401
        if http.statusCode == 401, allowRetry {
            // Check for permanent refresh_token_revoked before retrying
            if let body = try? decoder.decode(APIErrorBody.self, from: data),
               body.error == "refresh_token_revoked" {
                await auth.clearSession()
                throw APIError.sessionRevoked
            }
            _ = try await auth.refreshSession()
            return try await send(endpoint, allowRetry: false)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode, data)
        }
        return try decoder.decode(E.Response.self, from: data)
    }
}
```

### 4.2 Endpoint Protocol

```swift
enum HTTPMethod: String {
    case GET, POST, PATCH, DELETE
}

protocol Endpoint {
    associatedtype Response: Decodable & Sendable
    var path: String { get }
    var method: HTTPMethod { get }
    var body: (any Encodable)? { get }
    var queryItems: [URLQueryItem]? { get }
    var requiresAuth: Bool { get }
    var requiresAttestation: Bool { get }
    /// UUIDv7 string. Non-nil for POST / PATCH / DELETE.
    var idempotencyKey: String? { get }
}

// Default implementations
extension Endpoint {
    var body: (any Encodable)? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var requiresAuth: Bool { true }
    var requiresAttestation: Bool { false }
    var idempotencyKey: String? { nil }
    // Mutating endpoints MUST set a persisted key (transfers) or an explicit key at call site.
    // Never use inline UUID7() for payment flows — see §6.
}
```

### 4.3 Error Hierarchy

```swift
enum APIError: Error, Sendable {
    case invalidResponse
    case sessionRevoked                         // refresh_token_revoked
    case http(Int, Data)                        // status code + raw body
    case decoding(DecodingError)
    case network(URLError)
    case pinningFailed                          // TrustKit rejected cert
    case cancelled                              // URLError.cancelled
}
```

---

## 5. Authentication Architecture

### 5.1 Token Lifecycle

```
App launch
    │
    ▼
KeychainStore.load(accessToken)
    │
    ├── found + not expired → inject into APIClient headers
    │
    └── found + expired (or missing)
              │
              ▼
        AuthManager.validToken() → performRefresh()
              │
              ├── refresh success → store new access + refresh token in Keychain
              │
              └── refresh failure (revoked / network) → clearSession() → show login
```

### 5.2 `AuthManager` public API

| Method | Caller | Behaviour |
|--------|--------|-----------|
| `validToken()` | `APIClient` (auth header) | Returns cached token if fresh; else `performRefresh()` |
| `refreshSession()` | `APIClient` (401 retry) | Clears in-memory access token; always `performRefresh()` once |
| `clearSession()` | Logout, `refresh_token_revoked` | Keychain purge, cancel in-flight refresh `Task` |

`performRefresh()` is **private**. Refresh HTTP lives in `TokenService` (injected).

### 5.3 Concurrent 401 Handling

Concurrent 401s call `refreshSession()`, which uses the same `performRefresh()` path as
`validToken()`. Because `AuthManager` is an `actor`, calls are serialised:
- First caller creates `refreshTask` and begins the network refresh.
- All subsequent callers await `refreshTask.value` — they do NOT start a second refresh.
- When the first caller finishes, all waiters receive the same new token.
- `refreshTask` is cleared in `defer` whether success or failure.

### 5.4 Keychain Layout

| Key | Protection | Control |
|-----|-----------|---------|
| `wallet.access_token` | `WhenUnlockedThisDeviceOnly` | none (expiry enforced in code) |
| `wallet.refresh_token` | `WhenUnlockedThisDeviceOnly` | `.biometryCurrentSet` (SE-gated) |
| `wallet.attest_key_id` | `WhenUnlockedThisDeviceOnly` | none |
| `wallet.device_public_key` | `WhenUnlockedThisDeviceOnly` | — (SE-stored private key) |

---

## 6. Idempotency Architecture

### 6.1 Flow

```
User taps "Send SAR 100"
    │
    ▼
PaymentService.initiateTransfer(cmd)
    │
    ├── IdempotencyStore.findOrCreate(intentID: cmd.intentID)
    │       │
    │       └── Core Data: find existing PendingRequest for this intentID
    │           or INSERT new row with UUID7().uuidString as idempotencyKey
    │
    ▼
APIClient.send(TransferEndpoint(idempotencyKey: pendingRequest.idempotencyKey))
    │
    ├── Network success (2xx)
    │       │
    │       └── IdempotencyStore.markTerminal(pendingRequest) → set terminalResponseAt
    │
    ├── Network error (retryable: 5xx, timeout)
    │       │
    │       └── PendingRequest.attempts += 1 — retry on next launch
    │
    └── Network error (non-retryable: 400, 409)
            │
            └── IdempotencyStore.markTerminal(pendingRequest) — do not retry
```

### 6.2 Core Data Entity — `PendingRequest`

```
PendingRequest
├── idempotencyKey:     String    (indexed, UUIDv7 string)
├── intentID:           String    (e.g., "transfer-\(draftID)" — client-side dedup key)
├── endpoint:           String    (route identifier)
├── payloadData:        Binary    (JSON-encoded request body)
├── createdAt:          Date
├── attempts:           Int16
├── lastError:          String?
└── terminalResponseAt: Date?     (nil = still retryable)
```

### 6.3 Launch-time Retry Scan

```swift
// AppEnvironment.swift — called once on launch, before any view appears
func retryPendingRequests() async {
    let pending = await idempotencyStore.fetchRetryable()
    // Requests older than 25h are beyond the server's 24h dedup window → purge
    let cutoff = Date().addingTimeInterval(-25 * 3600)
    let (stale, active) = pending.partition { $0.createdAt < cutoff }
    await idempotencyStore.purge(stale)
    for req in active {
        try? await paymentService.retry(req)
    }
}
```

---

## 7. State Management Architecture

### 7.1 `AppState` — Single Global Observable

```swift
@Observable
@MainActor
final class AppState {
    var authStatus: AuthStatus = .unknown   // .unknown → .authenticated | .unauthenticated
    var currentUserID: String?
    var currentTier: CustomerTier?

    // Shared session signals
    var sessionRevokedAlert = false
}

enum AuthStatus { case unknown, authenticated, unauthenticated }
```

`AppState` is injected at the root via `.environment(appState)`. Views observe only the
properties they read — `@Observable` ensures no unnecessary re-renders.

### 7.2 View Model Pattern

```swift
@Observable
@MainActor
final class TransactionHistoryViewModel {
    // Display state
    var transactions: [Transaction] = []
    var isLoading = false
    var error: APIError?
    var hasMore = true

    // Pagination cursor (UUIDv7 of last seen transaction)
    private var cursor: String?

    // Injected (not constructed in init)
    private let walletService: WalletService

    init(walletService: WalletService) {
        self.walletService = walletService
        // NO side effects here — init may be called multiple times by SwiftUI
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await walletService.fetchTransactions(cursor: nil, limit: 20)
            transactions = page.items
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            self.error = error as? APIError
        }
    }

    func loadNextPage() async {
        guard hasMore, !isLoading, let cursor else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await walletService.fetchTransactions(cursor: cursor, limit: 20)
            transactions.append(contentsOf: page.items)
            self.cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            self.error = error as? APIError
        }
    }
}
```

---

## 8. Navigation Architecture

### 8.1 Router Per Flow

```swift
// Two routers, injected as @State at the root scene level
@State private var appRouter = AppRouter()
@State private var authRouter = AuthRouter()

// Root scene switch
var body: some View {
    Group {
        switch appState.authStatus {
        case .authenticated:
            AppNavigationRoot(router: appRouter)
        case .unauthenticated, .unknown:
            AuthNavigationRoot(router: authRouter)
        }
    }
    .environment(appState)
    .environment(appRouter)
    .environment(authRouter)
}
```

### 8.2 Route Enums

```swift
enum AppRoute: Hashable {
    case home
    case transactionDetail(id: String)
    case transferConfirmation(draft: TransferDraft)
    case withdrawalConfirmation(draft: WithdrawalDraft)
    case settings
    case kycUpgrade
}

enum AuthRoute: Hashable {
    case login
    case otpVerification(phoneHint: String)
    case onboarding
    case kycStart
}
```

### 8.3 NavigationStack Binding

```swift
NavigationStack(path: $router.path) {
    HomeView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .transactionDetail(let id):
                TransactionDetailView(id: id)
            case .transferConfirmation(let draft):
                TransferConfirmationView(draft: draft)
            // ...
            }
        }
}
```

---

## 9. Real-Time Architecture

### 9.1 SSE Balance Stream

```
Foreground (scenePhase == .active)
    │
    ▼
SSEClient.connect(url: GET /v1/wallet/stream, lastEventID: stored)
    │
    ├── event "balance.updated" → WalletService.refreshBalance()
    ├── event "transaction.posted" → WalletService.appendTransaction()
    └── error → exponential backoff (1s → 2s → 4s … 30s cap) + reconnect

Background (scenePhase != .active)
    │
    └── SSEClient.disconnect()

APNs silent push ("balance-changed")
    │
    └── PushNotificationHandler → background URLSession fetch → Core Data update
         → post Notification → WalletViewModel receives on next foreground activation
```

### 9.2 SSE Client Wrapper

```swift
final class SSEClient: @unchecked Sendable {
    // @unchecked Sendable: EventSource is mutated only on its internal serial queue
    // and our public methods are called from a single actor context
    private var eventSource: LDSwiftEventSource.EventSource?
    private var lastEventID: String?

    func connect(
        url: URL,
        authToken: String,
        onBalance: @escaping (Decimal) -> Void,
        onTransaction: @escaping (Transaction) -> Void
    ) {
        var config = EventSource.Config(handler: self, url: url)
        config.headers = ["Authorization": "Bearer \(authToken)"]
        if let id = lastEventID {
            config.headers["Last-Event-ID"] = id
        }
        eventSource = EventSource(config: config)
        eventSource?.start()
    }

    func disconnect() {
        eventSource?.stop()
        eventSource = nil
    }
}
```

---

## 10. Security Architecture

### 10.1 Defence-in-Depth Layers

| Layer | Mechanism | Bypassable on jailbreak? | Notes |
|-------|-----------|--------------------------|-------|
| TLS 1.3 | ATS + TrustKit SPKI pins | With Frida (Objection) | Protects honest users on hostile Wi-Fi |
| App Attest | DCAppAttestService (SE) | No — SE key cannot be extracted | Hardware-rooted; unavailable on jailbroken devices (graceful degrade) |
| Biometric-gated Keychain | SecAccessControl(.biometryCurrentSet) | Hard — SE releases the key | `.biometryCurrentSet` invalidates on new biometric enrollment |
| Jailbreak detection | IOSSecuritySuite + dyld check | Yes — Frida bypasses documented | Risk signal to backend, not a hard gate |
| Screenshot prevention | Secure UITextField wrap + scenePhase blur | Partial — app-switcher covered | DRM-style lock is not possible on iOS |
| No reverse-engineering | Strip debug symbols, Release optimisations | — | Raises attacker cost |

### 10.2 App Attest Flow

```
First launch
    │
    ▼
DCAppAttestService.generateKey() → store keyID in Keychain
    │
    ▼
Fetch challenge nonce from backend (GET /v1/device/challenge)
    │
    ▼
DCAppAttestService.attestKey(keyID, clientDataHash: SHA256(nonce))
    │
    ▼
POST /v1/device/register { attestation, keyID, nonce }
    │
    ▼ Backend verifies with Apple + stores device record
    │
Per-request (sensitive endpoints)
    │
    ▼
DCAppAttestService.generateAssertion(keyID, clientDataHash: SHA256(requestBody))
    │
    ▼
Add X-Attest-Signature header → backend verifies
```

### 10.3 Screenshot Guard (SwiftUI)

```swift
struct PrivacyShield: ViewModifier {
    @Environment(\.scenePhase) private var phase

    func body(content: Content) -> some View {
        content
            .blur(radius: phase == .active ? 0 : 20)
            .animation(.easeInOut(duration: 0.15), value: phase)
    }
}

// Secure field wrapper — excluded from iOS screenshot and screen-recording pipeline
struct SecureDisplayView<Content: View>: UIViewRepresentable {
    // Embeds content inside UITextField(isSecureTextEntry: true)
    // which routes through iOS secure drawing path
    let content: Content
    // ...implementation...
}
```

---

## 11. Dependency Injection

Single `AppEnvironment` struct constructed at app launch and injected via SwiftUI `.environment`.
No service locator, no singletons (except `URLSession.shared` for non-pinned dev tooling).
`AppAttestService`, `APIClient`, and `AuthManager` are created once in `AppEnvironment.production()`
and passed by value/reference into consumers.

```swift
struct AppEnvironment {
    // Infrastructure
    let apiClient: APIClient
    let authManager: AuthManager
    let keychainStore: KeychainStore
    let idempotencyStore: IdempotencyStore
    let sseClient: SSEClient
    let appAttestService: AppAttestService

    // Application services
    let walletService: WalletService
    let paymentService: PaymentService
    let identityService: IdentityService
    let sessionService: SessionService

    // Navigation
    let appRouter: AppRouter
    let authRouter: AuthRouter

    // Shared state
    let appState: AppState

    static func production() -> AppEnvironment { ... }
    static func preview() -> AppEnvironment { ... }     // fake implementations
}
```

---

## 12. Performance Architecture

### 12.1 Threading Model

```
Main thread (@MainActor)
  ├── All SwiftUI body evaluations
  ├── View model property reads/writes
  └── Router state changes

Cooperative thread pool (default actor)
  ├── APIClient.send() — URLSession async
  ├── AuthManager.validToken() / refreshSession()
  ├── JSON decoding (inside APIClient)
  ├── Core Data reads/writes (IdempotencyStore)
  └── SSEClient event parsing

Secure Enclave (hardware)
  └── DCAppAttestService.generateAssertion()
```

### 12.2 Transaction List — List over LazyVStack

```swift
// CORRECT — UICollectionView-backed, cell reuse, 120fps tested
List(transactions) { tx in
    TransactionRowView(tx: tx)
        .id(tx.id)          // stable identity = no unnecessary diffs
}
.listStyle(.plain)

// WRONG for large sets — eager VStack, no reuse, hitches on scroll
ScrollView {
    LazyVStack {
        ForEach(transactions) { tx in
            TransactionRowView(tx: tx)
        }
    }
}
```

### 12.3 Formatters as Static Properties

```swift
extension NumberFormatter {
    static let sar: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "SAR"
        f.locale = Locale(identifier: "ar_SA")
        return f
    }()
}

extension DateFormatter {
    static let transactionDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale.current
        return f
    }()
}
// Used in TransactionRowView body — never constructed inline
```

---

## 13. SPM Dependencies

```swift
// Package.swift dependencies
.package(url: "https://github.com/datatheorem/TrustKit", from: "3.0.0"),
.package(url: "https://github.com/mhayes853/swift-uuidv7", from: "1.0.0"),
.package(url: "https://github.com/launchdarkly/swift-eventsource", from: "3.0.0"),
.package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
.package(url: "https://github.com/securing/IOSSecuritySuite", from: "1.9.0"),
```

**No Alamofire. No TCA. No Combine pipelines. No RxSwift.**
The fewer third-party dependencies in the auth-critical path, the smaller the supply-chain
attack surface.

---

## 14. Architecture Decision Records

### ADR-001: URLSession + async/await over Alamofire
**Status:** Accepted
Alamofire adds ~200 KB binary size and a third-party dependency in the most security-sensitive
code path. Swift Concurrency natively solves the refresh serialisation problem via `actor`.
Monzo's production iOS codebase uses URLSession directly. Risk: team must implement retry and
error handling manually — this is acceptable given the security requirements.

### ADR-002: `@Observable` over TCA
**Status:** Accepted
TCA documented production issues: stack overflow on large state trees, multi-second CPU spikes
on text input (Zabłocki, 2023), slow incremental build times from reducer-tree recompilation
(Schmidt, 2024). `@Observable` + NavigationStack + per-screen ViewModels is the pattern
Revolut and Nubank converge on. TCA is reconsidered if the team exceeds 8 iOS engineers and
experiences demonstrated state-management pain.

### ADR-003: Hand-Rolled `KeychainStore` (~60 lines)
**Status:** Accepted
`KeychainAccess` and `keychain-swift` both had CVE or access-group issues in recent major
versions. The Keychain API surface used by a wallet is narrow: `SecItemAdd`, `SecItemCopyMatching`,
`SecItemDelete`. Hand-rolling this reduces supply-chain risk in the credential storage path.

### ADR-004: UUIDv7 via `swift-uuidv7`, Not Foundation `UUID()`
**Status:** Accepted
Foundation `UUID()` generates v4 (random). The backend expects UUIDv7 idempotency keys for
time-ordered deduplication. `swift-uuidv7` guarantees monotonic generation even on clock skew
(uses rand_a 12 bits as in-process counter per RFC 9562 §6.2 appendix).

### ADR-005: No `LazyVStack` for Transaction Lists
**Status:** Accepted
Jacob Bartlett's 120fps benchmark (May 2025) confirmed `List` is buttery at 120fps on Low
Power Mode with 1,000 items; `LazyVStack` hitches. `List` is UICollectionView-backed with
cell reuse. `LazyVStack` loads the entire hierarchy for visible cells without reuse.

### ADR-006: SSE for Foreground, APNs for Background
**Status:** Accepted
WebSocket and SSE connections are killed when iOS suspends an app. APNs silent pushes are the
only reliable background notification channel. This matches the Monzo pattern (WebSocket/SSE
for foreground activity + push for background badge/refresh).
