# Kalirova

Kalirova is a native SwiftUI iPhone app for private, on-device health tracking. It keeps health data local by default, imports Apple Health data through HealthKit, estimates exercise calories independently from device-reported values, and offers optional per-interaction ChatGPT assistance only after showing the exact data that will be sent.

> Wellness disclaimer: this app is for wellness tracking only and is not medical advice.

## Current Sprint

Sprint 1 improves onboarding/profile input, editable profile username, unit preferences, BMI guidance, meal grouping, optional restaurant meal estimation with ChatGPT, Apple-standard UI patterns, a five-tab card-based navigation experience, 90-day HealthKit workout import, the Kalirova brand rename, the supplied Kalirova design system, and app-wide accessible semantic colors.

## Repository Rules

- Primary branch: `main`.
- Use conventional commits.
- Keep commits small and traceable to `PRODUCT_BACKLOG.md` and `SPRINT_BACKLOG.md`.
- Never commit API keys, tokens, HealthKit data, personal health data, generated user data, exports, local databases, or local config.
- Update backlog, changelog, and affected docs with each meaningful change.
- Run relevant checks before committing whenever possible.

## Local Setup

Requirements:

- macOS with full Xcode installed.
- Xcode 26.6 or newer stable Xcode when available.
- Swift 6 toolchain. The current local validation toolchain is Swift 6.3.3.
- iOS 17 SDK or newer. The app deployment target remains iOS 17 to avoid dropping supported devices unnecessarily.
- A physical iPhone for HealthKit functionality.
- Apple Developer signing team for physical-device builds. A Personal Development Team can build local development versions when iCloud capability is disabled.

Install and run:

1. Clone the repository.
2. Open `Kalirova.xcodeproj` in Xcode. The app product and display name build as Kalirova.
3. Select a development team for signing.
4. Keep HealthKit enabled for physical-device HealthKit functionality. Simulator previews use mock data.
5. Optional OpenAI features require an API key stored in Keychain from Settings. Do not place API keys in source files, plist files, or commits.
6. iCloud Backup is disabled for local development builds so Personal Development Teams can sign `com.kalirova.app`. Re-enabling CloudKit sync later requires a paid Apple Developer account, adding the iCloud capability/container back to the target entitlements, and defining the `ENABLE_ICLOUD_BACKUP` Swift compilation condition.

## Build And Test

The app target requires full Xcode with iOS SDK support. Core deterministic logic is also exposed as a Swift package so it can be tested from the command line:

```sh
swift test
```

If `xcodebuild` reports that Command Line Tools are selected, switch to full Xcode:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Build the iOS app from the command line:

```sh
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Run Xcode tests on an available simulator:

```sh
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test
```

## CI Efficiency

GitHub Actions are path-aware to avoid burning macOS runner minutes on docs-only work.

- CI runs Ubuntu metadata checks for documentation-only changes and runs macOS Swift/iOS jobs only for Swift, package, Xcode project, workflow, or manual runs.
- Security automation runs on pull requests, weekly schedule, and manual dispatch instead of every push.
- Wiki sync runs only when `docs/wiki/**` or the wiki workflow changes.
- Swift Package Manager cache is enabled; Xcode DerivedData is intentionally not cached.
- GitHub Actions dependencies are kept on current stable major versions, including checkout v7, cache v6, dependency-review v5, CodeQL v4, and paths-filter v4.

See `docs/ci-efficiency.md` for the full trigger and caching policy.

## Architecture

- UI: SwiftUI with native tab navigation, grouped forms/lists, card-based summaries, SF Symbols, materials, Apple Charts, reusable Kalirova design-system components, and centralized semantic color tokens for Light/Dark Mode readability.
- Local persistence: SwiftData models, local-only by default.
- Optional iCloud Backup: CloudKit-backed SwiftData code is preserved but disabled in local development builds behind the `ENABLE_ICLOUD_BACKUP` compilation condition.
- Apple Health integration: HealthKit service isolated behind async APIs.
- Exercise calories: app-estimated calories are stored separately from device-reported calories.
- Meals: foods are logged into local meal containers grouped by date and meal type.
- AI: OpenAI integration is optional, isolated, and opt-in per request, including restaurant meal estimates that show the exact outbound meal fields before sending. OpenAI API keys remain in Keychain and are never included in iCloud backup.
- Errors: shared user-facing error mapping presents accessible banners, inline validation, alerts, and sanitized debug details without logging secrets or personal health values.
- Brand assets: Kalirova app icon, brand marks, icon assets, reference mockups, and namespaced semantic color assets live in the Xcode asset catalog.
- Analytics: none.

See `ARCHITECTURE.md`, `PRIVACY.md`, and `docs/performance.md` for details.

## HealthKit Entitlements

HealthKit requires:

- App target HealthKit capability.
- `com.apple.developer.healthkit` entitlement.
- Clear HealthKit purpose strings in the generated Info.plist.
- Permission requests scoped to the data types needed by the selected feature.

## iCloud Entitlements

iCloud/CloudKit entitlements are intentionally absent from local development builds. This allows physical-device signing with a Personal Development Team and bundle identifier `com.kalirova.app`.

To re-enable iCloud Backup for a paid Apple Developer account:

1. Add the iCloud capability and CloudKit service back to the Kalirova app target.
2. Add the CloudKit container entitlement for `iCloud.com.kalirova.app`.
3. Define `ENABLE_ICLOUD_BACKUP` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.
4. Verify provisioning with a paid team before distributing the build.

## SCRUM Artifacts

- `PRODUCT_BACKLOG.md`
- `SPRINT_BACKLOG.md`
- `SPRINT_REVIEW.md`
- `SPRINT_RETROSPECTIVE.md`
- `CHANGELOG.md`

## Security

Security automation lives in `.github/workflows/security.yml` and `.github/dependabot.yml`.

- Dependabot monitors GitHub Actions and Swift Package Manager.
- Dependency Review runs on pull requests.
- CodeQL analyzes Swift on source/workflow pull requests, scheduled runs, and manual runs.
- Conditional audit steps run for CocoaPods, npm, and Bundler if those lockfiles are later added.
- GitHub secret scanning and push protection are enabled for the public repository. Dependabot security updates are configured in the repo but must also be enabled in GitHub repository settings for advisory alerts.

See `SECURITY.md` for vulnerability reporting and secret-handling rules.

## Contributing

See `CONTRIBUTING.md`. Keep changes small, use conventional commits, update affected SCRUM/docs artifacts, and never commit secrets or personal health data.

## License

No license file is currently present. Until a license is added, all rights are reserved by the repository owner.
