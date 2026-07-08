# Architecture

HealthTrack AI is a local-first SwiftUI iPhone app built around explicit privacy boundaries and deterministic health calculations.

## Principles

- Health data stays on device by default.
- No cloud database.
- No third-party analytics.
- Optional ChatGPT calls are opt-in per interaction.
- The app shows the exact outbound AI payload before sending.
- Device-reported workout calories are stored separately from app-estimated calories.

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

SwiftData is used for local persistence. User data exports, local stores, and generated datasets are ignored by git.

### Services

- `HealthKitService`: permission requests and date-bounded Apple Health reads.
- `NutritionService`: local fallback meal parsing and nutrition aggregation.
- `CalorieBurnEstimator`: heart-rate and MET-based exercise calorie estimates.
- `OpenAIService`: optional meal and summary requests, isolated from persistence.
- `SummaryService`: deterministic daily and weekly summaries.
- `PersistenceService`: model container setup and local data lifecycle helpers.
- `PrivacyConsentService`: per-interaction AI consent and payload review state.
- `KeychainService`: secure local API key storage.

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

