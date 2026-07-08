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
| S0-T7 | S0.3 | Run available tests/build checks and document any environment blockers. | Blocked by unaccepted Apple SDK license for `swift test`/`xcodebuild`; project and JSON lint checks passed. |
| S0-T8 | S0.1 | Initialize git, commit foundation changes, create GitHub repo, and push `main`. | Blocked by unaccepted Apple SDK license for `/usr/bin/git` and invalid GitHub CLI token. |

## Verification Log

- `plutil -lint HealthTrackAI.xcodeproj/project.pbxproj`: passed.
- `plutil -lint HealthTrackAI/HealthTrackAI.entitlements`: passed.
- Asset catalog JSON parsed with Ruby `JSON.parse`: passed.
- Generated artifact scan for `.DS_Store`, `.xcuserstate`, `.sqlite`, and `.env`: passed after cleanup.
- `swift test`: blocked by unaccepted Apple SDK license.
- `git init -b main`: blocked by unaccepted Apple SDK license.
- `gh auth status`: blocked because the saved GitHub token for `cryptnetworks` is invalid.

## Working Agreement

- Before each meaningful code change, identify the related story/task.
- After each completed change, run relevant checks when possible.
- Update backlog, changelog, and docs when behavior or workflow changes.
- Commit with a conventional commit message.
- Push every commit to GitHub once remote authentication is available.
