# Changelog

All notable changes to HealthTrack AI will be documented here.

The format follows Keep a Changelog style, and commits use Conventional Commits.

## [Unreleased]

### Added
- Started Sprint 0 repository foundation.
- Added SCRUM product backlog and sprint backlog.
- Added privacy-first project documentation.
- Added Xcode/Swift/macOS `.gitignore` with secrets and health-data exclusions.
- Added Xcode SwiftUI iOS app project scaffold.
- Added SwiftData local models for profiles, summaries, meals, food items, workouts, metrics, goals, AI summaries, and app settings.
- Added onboarding, dashboard, meal log, exercise, metrics, trends, weekly summary, and settings screens.
- Added HealthKit, Keychain, OpenAI, and privacy consent service boundaries.
- Added deterministic calorie burn estimator, nutrition parser, HealthKit mapping, and summary service.
- Added SwiftPM core test target and Xcode unit-test target.
- Initialized local git repository on `main` and created initial commit `8b03fc0`.

### Blocked
- `swift test` and `xcodebuild` are blocked until the Apple SDK license is accepted locally.
- GitHub repository creation and push are blocked until `gh auth login -h github.com` refreshes the invalid GitHub token.
