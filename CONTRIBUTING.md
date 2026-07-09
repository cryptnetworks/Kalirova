# Contributing

Kalirova uses a small-change workflow. Keep pull requests focused, traceable to backlog items, and easy to review.

## Development Workflow

1. Create a branch from `main`.
2. Update `PRODUCT_BACKLOG.md` or `SPRINT_BACKLOG.md` when the change affects product scope.
3. Make the smallest production-quality change that solves the task.
4. Run relevant validation:

   ```sh
   swift test
   xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
   ```

5. Update `CHANGELOG.md` and docs when behavior, setup, privacy, security, or architecture changes.
6. Open a pull request using the template.

## Commit Style

Use conventional commits:

- `feat: add workout import summary`
- `fix: persist OpenAI API key in Keychain`
- `docs: update privacy policy`
- `test: add calorie estimator coverage`
- `chore: update CI workflows`

## Security And Privacy Rules

Never commit:

- API keys, tokens, passwords, or certificates
- HealthKit data or personal health data
- Generated user data, local databases, exports, logs, or caches
- Local Xcode, simulator, or DerivedData artifacts

OpenAI API keys must stay in iOS Keychain. Health data must remain local unless the user explicitly enables iCloud Backup.
