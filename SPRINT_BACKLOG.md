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
| S1-T7 | S9.1 | Refine screens with native SwiftUI forms/lists, accessibility labels, Dynamic Type support, and Liquid Glass availability fallbacks. | Todo |
| S1-T8 | S0.3 | Add or update tests for unit conversion, BMI, meal grouping, AI request payloads, and HealthKit duplicate handling. | Todo |
| S1-T9 | S0.3 | Run SwiftPM tests and Xcode simulator build. | Todo |
| S1-T10 | S9.2 | Rebrand project, Xcode targets, Swift package target, scheme, repository references, bundle identifier, docs, and brand assets to Kalirova. | Done |
| S1-T11 | S0.2 | Repair automatic signing and physical iPhone deployment for the Kalirova app target. | Done |
| S1-T12 | S7.3 | Persist OpenAI API keys in Keychain with masked Settings state, delete, and test connection controls. | Done |

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
- S1-T10: `xcodebuild -scheme Kalirova -configuration Debug build` reached signing and failed only because no physical-device provisioning profile exists for `com.michaeldesocio.kalirova`.
- S1-T10: `xcodebuild -scheme Kalirova -configuration Debug -destination generic/platform=iOS\ Simulator build` passed.
- S1-T11: `xcodebuild -list` showed project `Kalirova`, targets `Kalirova` and `KalirovaTests`, and scheme `Kalirova`.
- S1-T11: `xcrun devicectl list devices` showed `Michael’s iPhone` connected.
- S1-T11: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
- S1-T11: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'id=00008150-00021C341AF2401C' -configuration Debug build` passed.
- S1-T11: `xcrun devicectl device install app --device A9BC3D31-0520-5A69-AB2D-BBC29DBCCE18 .../Kalirova.app` installed `com.michaeldesocio.kalirova` on the connected iPhone.
- S1-T12: `plutil -lint Kalirova.xcodeproj/project.pbxproj Kalirova/Kalirova.entitlements` passed.
- S1-T12: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test` passed with 5 tests and 0 failures.
- S1-T12: `xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build` passed.
