# CI Efficiency

Kalirova uses GitHub Actions for iOS builds, tests, security checks, and wiki publishing. The workflows are path-aware so routine documentation changes do not spend macOS runner minutes.

## Workflow Triggers

### CI

`.github/workflows/ci.yml` runs on pull requests and pushes to `main` when app, package, workflow, or documentation files change. It can also be started manually with `workflow_dispatch`.

The CI workflow is split into cheap and expensive work:

- `Detect Changes` runs on Ubuntu and classifies changed files.
- `Validate Repo Metadata` runs on Ubuntu and validates workflow YAML plus required wiki pages.
- `Swift Package Tests` runs on macOS only for Swift/package/project/workflow changes or manual runs.
- `iOS Build and Tests` runs on macOS only after Swift package tests pass.

Docs-only changes run the Ubuntu validation job and skip the macOS iOS build/test jobs.

### Security

`.github/workflows/security.yml` runs on pull requests, a weekly schedule, and manual dispatch. It does not run on every push to `main`.

- Dependency Review runs on pull requests.
- Ecosystem audits run on Ubuntu when dependency files change, on schedule, or on manual runs.
- Swift Package inventory runs on macOS only when Swift dependency files change, on schedule, or on manual runs.
- CodeQL for Swift runs on source/workflow changes, on schedule, or on manual runs.

### Wiki Sync

`.github/workflows/wiki-sync.yml` runs on pushes to `main` only when `docs/wiki/**` or the wiki workflow changes. It can also be started manually. Pull requests do not push to the wiki.

If GitHub has not created the wiki repository yet, the workflow exits successfully with a warning when only `GITHUB_TOKEN` is available. Create the first wiki page in GitHub or configure a `WIKI_PUSH_TOKEN` secret with wiki write access, then rerun the workflow manually.

## Caching

The CI and security workflows cache Swift Package Manager state:

- `.build`
- `~/.swiftpm`
- `~/Library/Caches/org.swift.swiftpm`

The cache key is based on `Package.swift` and `Package.resolved`. This avoids caching secrets and avoids unstable Xcode `DerivedData` artifacts. DerivedData is intentionally not cached.

CocoaPods, npm, and Bundler caches are not configured because this repository currently has no `Podfile.lock`, npm lockfile, or `Gemfile.lock`.

## Action Versions

Workflows use current stable action versions and major tags where the upstream action provides a maintained stable major:

- `actions/checkout@v7`
- `actions/cache@v6`
- `actions/dependency-review-action@v5`
- `github/codeql-action@v4`
- `dorny/paths-filter@v4`
- `maxim-lobanov/setup-xcode@v1.7.0`

Dependabot groups GitHub Actions updates so compatible action bumps can be reviewed together.

## Manual Runs

Use GitHub Actions `Run workflow` for:

- A full CI check after infrastructure changes.
- A scheduled-style security check before releases.
- A wiki sync retry after changing wiki pages.

Local equivalents:

```sh
swift package show-dependencies
swift test
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build
xcodebuild test -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Estimating Savings

Use the Actions run duration page to compare:

1. A docs-only pull request before and after the path-aware split.
2. A source-code pull request that still runs SwiftPM tests and iOS build/tests.
3. Weekly security runs versus security-on-every-push behavior.

The biggest savings come from skipping macOS jobs for docs-only work and removing security scans from every push to `main` while keeping PR, scheduled, and manual coverage.
