# Sprint Review

## Sprint 0

Status: In Progress

Completed:
- Repository governance docs, privacy docs, changelog, backlog, sprint review, and retrospective.
- Xcode SwiftUI project scaffold with app target, unit-test target, HealthKit entitlement, asset catalog, and Info.plist purpose strings.
- SwiftData models for all required local entities.
- SwiftUI screens for onboarding, dashboard, meal log, exercise, metrics, trends, weekly summary, and settings.
- Isolated services for HealthKit, OpenAI, privacy consent, and Keychain API-key storage.
- Deterministic core services and unit tests for calorie estimates, meal parsing, HealthKit mapping, and summary generation.

Demo Notes:
- Open `HealthTrackAI.xcodeproj` after accepting the Apple SDK license and selecting full Xcode.
- Core package tests are available through `swift test` once the license gate is resolved.

Environment Notes:
- `xcodebuild` requires full Xcode selection before command-line app builds can run.
- `swift test`, `xcodebuild`, and `/usr/bin/git` currently exit with the Apple SDK license error.
- `sudo xcodebuild -license accept` was approved but could not run because `sudo` requires an interactive password.
- `gh auth status` reports an invalid token for `cryptnetworks`; GitHub publish is pending re-authentication.
