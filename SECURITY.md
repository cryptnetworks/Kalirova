# Security Policy

Kalirova is a local-first health and weight-tracking app. Security and privacy changes should preserve the default behavior that health data stays on device unless the user explicitly enables iCloud Backup.

## Reporting A Vulnerability

Do not open a public issue for a suspected vulnerability that includes exploit details, secrets, HealthKit data, or personal health data.

Report privately through GitHub private vulnerability reporting if enabled for the repository. If private reporting is not enabled, contact the repository owner directly and include:

- A short summary of the issue
- Affected versions or commits
- Reproduction steps using synthetic data only
- Impact and suggested remediation, if known

## Supported Branch

Security fixes are made on `main` unless a release branch is introduced.

## Dependency And Security Audit

Current audit findings:

- App framework: native SwiftUI iOS app in `Kalirova.xcodeproj`.
- Build system: Xcode project plus Swift Package Manager package for core logic.
- Dependency manager: Swift Package Manager.
- External SwiftPM dependencies: none detected by `swift package show-dependencies`.
- CocoaPods: no `Podfile` or `Podfile.lock` detected.
- npm: no `package.json` or npm lockfile detected.
- Ruby/Bundler: no `Gemfile` or `Gemfile.lock` detected.
- CI/CD: GitHub Actions workflows in `.github/workflows/`.

Available checks:

```sh
swift package show-dependencies
swift test
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

GitHub security automation:

- Dependabot monitors GitHub Actions and Swift Package Manager.
- Dependency Review runs on pull requests.
- CodeQL analyzes Swift on pushes, pull requests, scheduled runs, and manual dispatch.
- The security workflow runs available ecosystem audit commands only when lockfiles are present.

## Secret Handling

Never commit API keys, tokens, HealthKit data, personal health data, generated user data, exports, local databases, logs, or local configuration.

OpenAI API keys are stored only in iOS Keychain using account `openai_api_key` and service `com.kalirova.app`. Do not print full keys to logs, screenshots, crash reports, analytics, or test output.

GitHub secret scanning and push protection should be enabled in repository settings for public repositories. For local checks, use a secret scanner such as `gitleaks` before pushing security-sensitive changes.
