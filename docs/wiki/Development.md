# Development

## Stack

- Native SwiftUI iOS app
- Xcode project: `Kalirova.xcodeproj`
- Scheme: `Kalirova`
- Swift Package Manager package: `Package.swift`
- Tests: SwiftPM tests under `Tests/` and Xcode tests under `KalirovaTests/`
- CI/CD: GitHub Actions in `.github/workflows/`

## Local Validation

```sh
swift package show-dependencies
swift test
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Run Xcode tests on an available simulator:

```sh
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug test
```

## Workflow

- Keep commits small and conventional.
- Update backlog and changelog for meaningful changes.
- Preserve local-first privacy behavior.
- Do not commit generated data, local config, HealthKit data, or secrets.
- Prefer native SwiftUI controls and the shared Kalirova design system.

## Wiki Sync

Wiki pages live in `docs/wiki/`. The `wiki-sync.yml` workflow pushes them to the GitHub Wiki when they change. If `GITHUB_TOKEN` cannot write to the wiki, create a repository secret named `WIKI_PUSH_TOKEN` with a fine-grained token that can write the wiki repository.
