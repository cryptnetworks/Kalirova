# Sprint Backlog

## Sprint 0: Foundation And First Vertical Slice

Dates: 2026-07-08 to 2026-07-22

Goal: Create the repository, SCRUM documentation, SwiftUI app scaffold, local-first privacy architecture, deterministic core services, and first automated tests.

## Sprint Tasks

| ID | Story | Task | Status |
| --- | --- | --- | --- |
| S0-T1 | S0.1 | Add repository governance docs, privacy docs, changelog, and `.gitignore`. | Done |
| S0-T2 | S0.2 | Create Xcode SwiftUI app project with app target, entitlements, assets, and generated Info.plist purpose strings. | Done |
| S0-T3 | S0.2 | Add SwiftData models for required local entities. | Done |
| S0-T4 | S0.2 | Add SwiftUI screens for onboarding, dashboard, meals, exercise, metrics, trends, weekly summary, and settings. | Done |
| S0-T5 | S0.2 | Add isolated HealthKit, OpenAI, privacy consent, and Keychain services. | Done |
| S0-T6 | S0.3 | Add deterministic core services and SwiftPM test target. | Done |
| S0-T7 | S0.3 | Run available tests/build checks and document any environment blockers. | Done |
| S0-T8 | S0.1 | Initialize git, commit foundation changes, create GitHub repo, and push `main`. | Done |

## Verification Log

- `plutil -lint Kalirova.xcodeproj/project.pbxproj`: passed.
- `plutil -lint Kalirova/Kalirova.entitlements`: passed.
- Asset catalog JSON parsed with Ruby `JSON.parse`: passed.
- Generated artifact scan for `.DS_Store`, `.xcuserstate`, `.sqlite`, and `.env`: passed after cleanup.
- `swift test`: passed with 8 XCTest tests and 0 failures.
- `xcodebuild -list -project Kalirova.xcodeproj`: passed.
- `xcodebuild -scheme Kalirova -destination generic/platform=iOS\ Simulator build`: passed.
- `git init -b main`: passed after escalation.
- `git commit -m "feat: scaffold Kalirova app"`: passed with commit `8b03fc0`.
- `gh repo create Kalirova --private --source=. --remote=origin --push`: passed; `main` tracks `origin/main`.

## Working Agreement

- Before each meaningful code change, identify the related story/task.
- After each completed change, run relevant checks when possible.
- Update backlog, changelog, and docs when behavior or workflow changes.
- Commit with a conventional commit message.
- Push every commit to GitHub once remote authentication is available.

## Sprint 1: Units, Meals, Imports, And Native UI

Dates: 2026-07-08 to 2026-07-22

Goal: Improve onboarding/profile input, add unit preferences and BMI guidance, redesign meal logging around meal containers, add optional restaurant meal AI estimation with explicit privacy confirmation, import 90 days of HealthKit workouts, refine UI with native Apple patterns, and apply the Kalirova brand rename.

## Sprint Tasks

| ID | Story | Task | Status |
| --- | --- | --- | --- |
| S1-T1 | S1.1, S1.3, S2.1, S3.1, S7.3, S9.1 | Update product and sprint backlog for requested changes. | Done |
| S1-T2 | S1.1, S1.3 | Add unit preferences, typed onboarding fields, goal weight, BMI calculation, and BMI info sheet. | Done |
| S1-T3 | S1.3 | Apply unit preference display/input conversions across profile, workouts, metrics, and settings. | Done |
| S1-T4 | S3.1 | Redesign meal logging around date and meal type containers with multiple food items. | Done |
| S1-T5 | S7.3 | Add ChatGPT restaurant meal estimation payload preview, API call, confirmation/editing, and save flow. | Done |
| S1-T6 | S2.1, S2.2 | Add 90-day HealthKit workout import, duplicate skipping, heart-rate averaging, progress UI, and import summary. | Todo |
| S1-T7 | S9.1 | Refine screens with native SwiftUI forms/lists, card layouts, accessibility labels, Dynamic Type support, Apple Charts, and Liquid Glass-style material fallbacks. | Done |
| S1-T8 | S0.3 | Add or update tests for unit conversion, BMI, meal grouping, AI request payloads, and HealthKit duplicate handling. | Todo |
| S1-T9 | S0.3 | Run SwiftPM tests and Xcode simulator build. | Todo |
| S1-T10 | S9.2 | Rebrand project, Xcode targets, Swift package target, scheme, repository references, bundle identifier, docs, and brand assets to Kalirova. | Done |
| S1-T11 | S0.2 | Repair automatic signing and physical iPhone deployment for the Kalirova app target. | Done |
| S1-T12 | S7.3 | Persist OpenAI API keys in Keychain with masked Settings state, delete, and test connection controls. | Done |
| S1-T13 | S10.1 | Add opt-in iCloud Backup settings, CloudKit-backed SwiftData container selection, iCloud availability state, and privacy documentation. | Done |
| S1-T14 | S0.1, S0.2 | Remove personal identifiers from bundle IDs, Keychain service names, CloudKit container IDs, entitlements, and documentation. | Done |
| S1-T15 | S9.3 | Import Kalirova design system assets, create reusable SwiftUI theme/components, and normalize major screens to the supplied visual language. | Done |
| S1-T16 | S0.4 | Add CI, security scanning, Dependabot, repository templates, security policy, and wiki sync documentation. | Done |
| S1-T17 | S10.2 | Remove iCloud capability from local development signing and guard CloudKit-backed persistence behind a paid-team build flag. | Done |
| S1-T18 | S0.4 | Optimize GitHub Actions triggers, path-aware jobs, concurrency, caching, and CI efficiency documentation. | Done |
| S1-T19 | S9.4 | Audit and unify the app-wide color system, fix low-contrast text states, and validate Light/Dark Mode readability. | Done |
| S1-T20 | S1.1, S7.3 | Fix OpenAI API key keyboard dismissal and add validated profile username editing. | Done |
| S1-T21 | S0.4 | Update stable workflow dependency versions, review Dependabot PRs, and document current validated toolchain requirements. | Done |

## Sprint 1 Verification Log

- S1-T2: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T2: `xcodebuild -scheme Kalirova -destination generic/platform=iOS\ Simulator build` passed.
- S1-T3: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T3: `xcodebuild -scheme Kalirova -destination generic/platform=iOS\ Simulator build` passed.
- S1-T4: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T4: `xcodebuild -scheme Kalirova -destination generic/platform=iOS\ Simulator build` passed.
- S1-T5: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T5: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T5: `xcodebuild -scheme Kalirova -destination generic/platform=iOS\ Simulator build` passed.
- S1-T10: `plutil -lint Kalirova.xcodeproj/project.pbxproj` passed.
- S1-T10: Kalirova asset catalog `Contents.json` files parsed with Ruby `JSON.parse`.
- S1-T10: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T10: `xcodebuild -list` showed project `Kalirova`, targets `Kalirova` and `KalirovaTests`, and scheme `Kalirova`.
- S1-T10: required grep for legacy names returned no results.
- S1-T10: `xcodebuild -scheme Kalirova -configuration Debug build` reached signing and failed only because no physical-device provisioning profile exists for `com.kalirova.app`.
- S1-T10: `xcodebuild -scheme Kalirova -configuration Debug -destination generic/platform=iOS\ Simulator build` passed.
- S1-T11: `xcodebuild -list` showed project `Kalirova`, targets `Kalirova` and `KalirovaTests`, and scheme `Kalirova`.
- S1-T11: `xcrun devicectl list devices` showed `Michael’s iPhone` connected.
- S1-T11: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T11: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'id=00008150-00021C341AF2401C' -configuration Debug build` passed.
- S1-T11: `xcrun devicectl device install app --device A9BC3D31-0520-5A69-AB2D-BBC29DBCCE18 .../Kalirova.app` installed `com.kalirova.app` on the connected iPhone.
- S1-T12: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T12: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T12: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T13: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T13: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T13: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T13: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug -allowProvisioningUpdates build` failed because the current personal development team does not support the iCloud capability required for CloudKit provisioning.
- S1-T14: Project-wide personal-identifier search returned no results outside Git history.
- S1-T14: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T14: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -configuration Debug clean` passed.
- S1-T14: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T14: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T14: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug -allowProvisioningUpdates build` failed because the current personal development team does not support the iCloud capability required for CloudKit provisioning.
- S1-T7: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T7: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T15: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T15: Kalirova asset catalog `Contents.json` files parsed with Ruby `JSON.parse`.
- S1-T15: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T15: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T15: Final simulator build warning scan showed only Xcode's benign AppIntents metadata warning for an app with no AppIntents dependency.
- S1-T16: Repository audit found native SwiftUI/Xcode app, Swift Package Manager package, no CocoaPods, no npm, no Ruby/Bundler, and GitHub Actions CI/CD.
- S1-T16: Workflow, Dependabot, and issue template YAML parsed successfully with Ruby `YAML.load_file`.
- S1-T16: `swift package show-dependencies` reported no external dependencies.
- S1-T16: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T16: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T16: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T16: `gh repo edit --visibility public --accept-visibility-change-consequences` completed; repository was already public.
- S1-T16: `gh repo edit --enable-wiki --enable-secret-scanning --enable-secret-scanning-push-protection` completed.
- S1-T16: Patched `wiki-sync.yml` to initialize the wiki repository on first sync if GitHub has not created it yet.
- S1-T17: Xcode project target capabilities inspected; local development target keeps HealthKit and removes iCloud.
- S1-T17: `rg "com.apple.iCloud|com.apple.developer.icloud|iCloud.com.kalirova.app|CloudKit" Kalirova.xcodeproj Kalirova/Kalirova.entitlements` returned no results.
- S1-T17: `plutil -p Kalirova/Kalirova.entitlements` showed only `com.apple.developer.healthkit`.
- S1-T17: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T17: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build` passed.
- S1-T17: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug -allowProvisioningUpdates build` passed with bundle identifier `com.kalirova.app`.
- S1-T17: `codesign -d --entitlements :- .../Debug-iphoneos/Kalirova.app` showed HealthKit only, with no iCloud or CloudKit entitlements.
- S1-T17: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T17: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T18: Workflow audit found CI was running macOS build/test jobs for docs-only changes and security scans were running on every push to `main`.
- S1-T18: `ruby -e 'require "yaml"; ...' .github/workflows/*.yml .github/dependabot.yml` parsed all workflow and Dependabot YAML successfully.
- S1-T18: CI now runs Ubuntu validation for docs-only changes and gates macOS Swift/iOS jobs behind Swift, package, Xcode project, workflow, or manual changes.
- S1-T18: Security now runs on pull requests, weekly schedule, and manual dispatch, with CodeQL gated to source/workflow changes plus scheduled/manual runs.
- S1-T18: `swift package show-dependencies` reported no external dependencies.
- S1-T18: Secret pattern scan returned no matches.
- S1-T18: Unsafe logging scan for `print`, `debugPrint`, `NSLog`, and `os_log` returned no matches.
- S1-T18: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T18: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T18: `xcodebuild test -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17'` passed with 7 tests and 0 failures.
- S1-T19: Hardcoded color audit found one-off `.secondary`, `.red`, `.orange`, `.white`, white stroke, and background opacity usages across shared components and major screens; the follow-up scan returned no direct matches in app views.
- S1-T19: Custom semantic accent/status contrast check showed Light Mode ratios from 5.50:1 to 6.70:1 on white and Dark Mode ratios from 8.38:1 to 11.94:1 on a dark system-background approximation.
- S1-T19: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T19: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T20: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T20: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T20: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug test` passed with 9 tests and 0 failures.
- S1-T21: Repository audit found Swift Package Manager only; no CocoaPods, Carthage, Fastlane, Ruby/Bundler, Node, Python, Docker, or external SwiftPM dependencies were present.
- S1-T21: Local toolchain check showed Xcode 26.6 and Swift 6.3.3; Swift tools version remains 6.0 and app deployment target remains iOS 17 for compatibility.
- S1-T21: Reviewed Dependabot PRs #1, #2, and #3 for CodeQL v4, dependency-review v5, and checkout v7; all were superseded by the consolidated local workflow update.
- S1-T21: Workflow and Dependabot YAML parsed successfully with Ruby `YAML.load_file`.
- S1-T21: Stale GitHub Actions version scan found no old action references after updates.
- S1-T21: `swift package show-dependencies` reported no external dependencies.
- S1-T21: Code scanning API returned no open alerts; Dependabot alerts API reported that Dependabot alerts are disabled in repository settings.
- S1-T21: Secret-pattern scan matched only documented example scan commands, not real credentials.
- S1-T21: Unsafe logging scan for `print`, `debugPrint`, `NSLog`, and `os_log` returned no matches in app or test sources.
- S1-T21: `swift test` passed with 9 XCTest tests and 0 failures.
- S1-T21: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T21: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 9 tests and 0 failures.
