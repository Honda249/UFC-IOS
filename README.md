# UFC-IOS

Native iOS (Swift 6 / SwiftUI) client for the SAR fiat e-wallet. **Foundation layer** — UI screens follow design.

## Specification

| Document | Purpose |
|----------|---------|
| [iOS-APP.md](iOS-APP.md) | Non-negotiable rules for AI-assisted development |
| [iOS-ARCHITECTURE.md](iOS-ARCHITECTURE.md) | Layering, types, flows, ADRs |
| [iOS-IMPLEMENTATION.md](iOS-IMPLEMENTATION.md) | Phased build plan (Phase 0–6) with exit criteria |

Read **APP → ARCHITECTURE → IMPLEMENTATION** before generating or reviewing code.

## Build (Phase 0)

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen   # once
xcodegen generate
xcodebuild -scheme WalletApp -destination 'generic/platform=iOS' build
xcodebuild -scheme WalletApp -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Open `WalletApp.xcodeproj` in Xcode after running `xcodegen generate`. The `.xcodeproj` is generated locally (not committed); CI runs `xcodegen` on each push.

## Project layout

```
WalletApp/          # Application target sources
WalletAppTests/     # Unit tests
project.yml         # XcodeGen spec (SPM deps, Swift 6 strict concurrency)
```

## Status

| Phase | Status |
|-------|--------|
| 0 — Xcode skeleton, SPM, `AppEnvironment.preview()` | Done |
| 1 — Networking + TrustKit | Next |
