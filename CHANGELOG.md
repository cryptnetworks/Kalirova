# Changelog

All notable changes to Kalirova will be documented here.

The format follows Keep a Changelog style, and commits use Conventional Commits.

## [Unreleased]

### Added
- Added GitHub Actions CI, security scanning, wiki sync, Dependabot configuration, repository issue/PR templates, `SECURITY.md`, `CONTRIBUTING.md`, and wiki-ready docs under `docs/wiki/`.
- Applied the supplied Kalirova design system with namespaced color assets, app icon assets, brand marks, reference mockups, semantic SwiftUI theme tokens, typography, spacing, card styles, button styles, icon helpers, and reusable dashboard/search/insight components.
- Redesigned the core SwiftUI experience with five native tabs, step-by-step onboarding, card-based Home/Meals/Activity/Insights/Profile surfaces, Apple Charts trend cards, guided meal entry, polished empty states, and Dynamic Type-friendly hierarchy.
- Added opt-in iCloud Backup settings, private CloudKit SwiftData container selection, iCloud availability display, manual backup request state, and documentation for backed-up versus excluded data.
- Planned Sprint 1 work for profile/unit improvements, BMI guidance, restaurant AI meal estimation, meal grouping, Apple-standard UI refinements, and HealthKit 90-day import.
- Rebranded the full project to Kalirova, including Xcode project, app/test targets, Swift package/core target, scheme, bundle identifier, source folders, repository references, and Kalirova brand assets.
- Added typed onboarding inputs for profile measurements, unit selection, goal weight, and live BMI with adult BMI category guidance.
- Added unit-aware dashboard, workout, and body-mass metric display/input while preserving normalized metric storage.
- Added meal containers grouped by date and meal type, with multiple food items per container and dashboard grouping.
- Added ChatGPT restaurant meal estimates with explicit privacy confirmation, structured nutrition output, source notes, assumptions, and editable review before saving.
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
- Created private GitHub repository `cryptnetworks/Kalirova` and pushed `main`.

### Fixed
- Removed iCloud/CloudKit capability and entitlement keys from local development builds, preserving CloudKit-backed persistence behind `ENABLE_ICLOUD_BACKUP` for future paid Apple Developer account builds.
- Removed personal identifiers from app/test bundle identifiers, Keychain service names, CloudKit container references, entitlements, and documentation.
- Persisted the OpenAI API key in iOS Keychain under `openai_api_key`, added masked Settings state, update/delete controls, connection testing, and Keychain CRUD tests.
- Enabled physical iPhone build and deployment by repairing automatic signing metadata and generating the Kalirova iOS development provisioning profile.
- Corrected weekly summary test optional unwrapping.
- Added Swift 6 concurrency annotation for the Keychain service singleton.
- Corrected OpenAI payload preview error propagation.
