# Architecture

Kalirova is a local-first SwiftUI iPhone app built around explicit privacy boundaries and deterministic health calculations.

## Principles

- Health data stays on device by default.
- No cloud database in local development builds. Optional private iCloud Backup is preserved behind an explicit paid-team build flag.
- No third-party analytics.
- Optional ChatGPT calls are opt-in per interaction.
- The app shows the exact outbound AI payload before sending.
- Device-reported workout calories are stored separately from app-estimated calories.
- The app product, display name, bundle identifier, and HealthKit purpose strings use the Kalirova brand.

## App Layers

### SwiftUI Views

Screens:
- Step-by-step onboarding
- Home
- Meals
- Activity
- Insights
- Profile

Views use native tab navigation, grouped forms/lists, card-based summaries, SF Symbols, materials, Apple Charts, reusable Kalirova design-system components, and MVVM view models for formatting, derived state, and service orchestration.

### Design System

The `Kalirova/DesignSystem` module centralizes the supplied visual language:
- `Theme.swift` maps namespaced asset colors to semantic product roles such as primary, nutrition, exercise, AI, grouped background, and card background.
- `Spacing.swift`, `Typography.swift`, `CardStyles.swift`, `ButtonStyles.swift`, and `Animations.swift` define reusable layout, type, surface, action, and motion tokens.
- `Icons.swift` and `Components.swift` expose shared brand marks, dashboard tiles, insight cards, and search fields so screens do not duplicate styling.

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

SwiftData is used for persistence. The default `ModelConfiguration` is local-only. Local development builds do not include iCloud entitlements and do not create a CloudKit-backed store, which keeps physical-device signing compatible with Personal Development Teams.

The CloudKit-backed SwiftData path is preserved behind the `ENABLE_ICLOUD_BACKUP` Swift compilation condition. Paid Apple Developer account builds can re-enable the iCloud capability, add the `iCloud.com.kalirova.app` CloudKit container entitlement, define `ENABLE_ICLOUD_BACKUP`, and then allow users to opt into private iCloud Backup.

When enabled in a paid-team build, iCloud Backup includes meals, food items, body-mass and other metric entries, goals, HealthKit-imported workouts, app-estimated calories, non-secret settings, and weekly summaries. It excludes OpenAI API keys, temporary logs, cache files, debug data, and OpenAI request payloads.

### Services

- `HealthKitService`: permission requests and date-bounded Apple Health reads.
- `NutritionService`: local fallback meal parsing and nutrition aggregation.
- `CalorieBurnEstimator`: heart-rate and MET-based exercise calorie estimates.
- `OpenAIService`: optional meal and summary requests, isolated from persistence.
- `SummaryService`: deterministic daily and weekly summaries.
- `PersistenceService`: model container setup and local data lifecycle helpers.
- `ICloudBackupService`: iCloud availability and manual backup timestamp state, disabled unless the `ENABLE_ICLOUD_BACKUP` build flag is present.
- `PrivacyConsentService`: per-interaction AI consent and payload review state.
- `KeychainService`: secure local API key storage.

### Brand Assets

The Xcode asset catalog contains the Kalirova app icon concept, brand marks, icon assets, reference mockups, and namespaced color assets from the Kalirova design system. Asset groups are organized into Brand, Icons, Backgrounds, Charts, Components, AppIcon, and semantic color sets.

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
