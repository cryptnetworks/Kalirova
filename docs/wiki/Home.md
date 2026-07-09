# Kalirova Wiki

Kalirova is a native SwiftUI iPhone app for local-first weight and health tracking.

## Navigation

- [Install](Install): set up Xcode, clone the repo, and run the app.
- [Usage](Usage): use onboarding, dashboard, meals, activity, insights, profile, OpenAI, HealthKit, and local-first storage.
- [Development](Development): project structure, validation commands, and contribution workflow.
- [Security](Security): vulnerability reporting, security scans, and secret-handling rules.

## Privacy Model

Health data stays on device by default. Local development builds do not include iCloud entitlements. Optional iCloud Backup can be re-enabled later for paid Apple Developer account builds and still requires explicit user opt-in. OpenAI requests are optional and show the exact outbound meal or summary payload before sending.
