# Changelog

All notable changes to HealthTrack AI will be documented here.

The format follows Keep a Changelog style, and commits use Conventional Commits.

## [Unreleased]

### Added
- Planned Sprint 1 work for profile/unit improvements, BMI guidance, restaurant AI meal estimation, meal grouping, Apple-standard UI refinements, and HealthKit 90-day import.
- Added typed onboarding inputs for profile measurements, unit selection, goal weight, and live BMI with adult BMI category guidance.
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
- Created private GitHub repository `cryptnetworks/HealthTrackAI` and pushed `main`.

### Fixed
- Corrected weekly summary test optional unwrapping.
- Added Swift 6 concurrency annotation for the Keychain service singleton.
- Corrected OpenAI payload preview error propagation.
