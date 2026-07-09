# Architecture

Kalirova is a local-first SwiftUI iPhone app built around explicit privacy boundaries and deterministic health calculations.

## Principles

- Health data stays on device by default.
- No cloud database unless the user explicitly enables private iCloud Backup.
- No third-party analytics.
- Optional ChatGPT calls are opt-in per interaction.
- The app shows the exact outbound AI payload before sending.
- Device-reported workout calories are stored separately from app-estimated calories.
- The app product, display name, bundle identifier, and HealthKit purpose strings use the Kalirova brand.

## App Layers

### SwiftUI Views

Screens:
- Onboarding
- Dashboard
- Meal Log
- Exercise
- Metrics
- Trends
- Weekly Summary
- Settings

Views use MVVM view models for formatting, derived state, and service orchestration.

### SwiftData Persistence

Required models:
- `UserProfile`
- `DailySummary`
- `MealEntry`
- `FoodItem`
- `WorkoutEntry`
- `HealthMetricEntry`
- `Goal`
- `AISummary`
- `AppSettings`

SwiftData is used for persistence. The default `ModelConfiguration` is local-only. When the user explicitly enables iCloud Backup in Settings, the app recreates the SwiftData container with a private CloudKit database using `iCloud.com.michaeldesocio.kalirova`. This preserves local-first behavior while allowing eligible app data to sync through the user's private iCloud account.

iCloud Backup includes meals, food items, body-mass and other metric entries, goals, HealthKit-imported workouts, app-estimated calories, non-secret settings, and weekly summaries. It excludes OpenAI API keys, temporary logs, cache files, debug data, and OpenAI request payloads.

### Services

- `HealthKitService`: permission requests and date-bounded Apple Health reads.
- `NutritionService`: local fallback meal parsing and nutrition aggregation.
- `CalorieBurnEstimator`: heart-rate and MET-based exercise calorie estimates.
- `OpenAIService`: optional meal and summary requests, isolated from persistence.
- `SummaryService`: deterministic daily and weekly summaries.
- `PersistenceService`: model container setup and local data lifecycle helpers.
- `ICloudBackupService`: iCloud availability and manual backup timestamp state.
- `PrivacyConsentService`: per-interaction AI consent and payload review state.
- `KeychainService`: secure local API key storage.

### Brand Assets

The Xcode asset catalog contains the Kalirova app icon concept, brand board, and named color assets from the Kalirova brand package. The Swift module and target internals can remain stable while the app product presents as Kalirova.

### Core Algorithms

When heart-rate data is available, the estimator uses user profile, workout type, duration, body mass, and intensity zones. When heart-rate data is unavailable, it uses:

```text
calories = MET * 3.5 * bodyMassKg / 200 * durationMinutes
```

Confidence levels:
- High: heart rate, body mass, duration, and workout type.
- Medium: body mass, duration, and workout type.
- Low: missing body mass or generic activity estimate.

Each estimate stores an algorithm version.

## HealthKit Boundary

HealthKit integration is isolated so simulator previews and unit tests can use mock DTOs. Permission requests are scoped to required types and are initiated only after user action.

## OpenAI Boundary

OpenAI integration is optional. The app works without an API key. Requests must be date-bounded and minimized:
- Meal text or photo-derived descriptions.
- Nutrition targets.
- Date-bounded summary statistics.

The app must not send full HealthKit history unless the user explicitly chooses to.

OpenAI API keys are stored only in Keychain and are not represented in SwiftData, CloudKit, exports, logs, or screenshots.
