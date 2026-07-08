# Product Backlog

## Epic E0: Project Foundation

### Story S0.1: Establish repo governance
As a maintainer, I want durable documentation and privacy guardrails so every future change follows the same workflow.

Acceptance criteria:
- Repository has `README.md`, `PRODUCT_BACKLOG.md`, `SPRINT_BACKLOG.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, and `PRIVACY.md`.
- Repository has an Xcode/Swift/macOS `.gitignore`.
- Documentation states that secrets, HealthKit data, personal health data, generated user data, and exports must never be committed.
- Commits use conventional commit messages.

### Story S0.2: Create native app scaffold
As a user, I want a native SwiftUI iPhone app shell so the product can grow feature by feature.

Acceptance criteria:
- Xcode project opens as `HealthTrackAI`.
- App uses SwiftUI entry point.
- App has navigable screens for onboarding, dashboard, meals, exercise, metrics, trends, weekly summary, and settings.
- App includes mock data for previews and simulator flows.

### Story S0.3: Add deterministic core tests
As a maintainer, I want unit tests for core calculations so health estimates remain explainable and repeatable.

Acceptance criteria:
- Calorie burn estimator has unit tests.
- Nutrition parsing fallback model has unit tests.
- HealthKit mapping logic has unit tests using mock DTOs.
- Summary generation has unit tests.

## Epic E1: Privacy-First Onboarding

### Story S1.1: Capture user profile locally
As a user, I want to enter age, sex, height, weight, activity level, and goals so estimates can be personalized on device.

Acceptance criteria:
- User profile is stored locally.
- The profile can be edited.
- The app works without network connectivity.

### Story S1.2: Explain privacy before permissions
As a user, I want to understand what stays local before granting HealthKit access.

Acceptance criteria:
- Privacy explanation appears during onboarding.
- HealthKit permissions are requested only after user action.
- Purpose strings are clear and specific.

## Epic E2: HealthKit Import

### Story S2.1: Import Apple Health metrics
As a user, I want to import workouts, heart rate, steps, distance, active energy, basal energy, body mass, dietary energy, macros, water, sleep, and exercise minutes from HealthKit.

Acceptance criteria:
- HealthKit service exposes permission requests and date-bounded reads.
- Imported values keep source metadata where available.
- Import can be manually triggered from settings.

### Story S2.2: Preserve device calories separately
As a user, I want device-reported calories shown separately from app estimates so I can compare them.

Acceptance criteria:
- Workout records have `deviceReportedCalories`.
- Workout records have `appEstimatedCalories`.
- UI shows both values and confidence level.

## Epic E3: Manual Logging

### Story S3.1: Log meals manually
As a user, I want to log foods and nutrition manually so I can track intake without AI.

Acceptance criteria:
- Meals can contain multiple food items.
- Calories, protein, carbs, fat, fiber, sugar, and sodium can be edited before saving.
- Saved meals appear in dashboard totals.

### Story S3.2: Log workouts manually
As a user, I want to log workouts manually so non-watch activities are included.

Acceptance criteria:
- Workout type, duration, effort, distance, and calories can be entered.
- App estimate runs when enough data exists.

### Story S3.3: Log metrics manually
As a user, I want to track weight, body fat, water, sleep, mood, notes, and custom metrics.

Acceptance criteria:
- Metric entries support a type, value, unit, date, and note.
- Metrics appear in trends.

## Epic E4: Calorie Burn Estimation

### Story S4.1: Estimate calories from METs
As a user, I want calorie estimates based on body mass, duration, activity type, and intensity when heart rate is missing.

Acceptance criteria:
- Formula uses `MET * 3.5 * bodyMassKg / 200 * durationMinutes`.
- Estimate stores algorithm version.
- Confidence is medium when body mass, duration, and activity type are present.

### Story S4.2: Estimate calories from heart-rate intensity
As a user, I want higher-confidence calorie estimates when heart rate is available.

Acceptance criteria:
- Estimator uses user profile and heart-rate zones.
- Confidence is high when heart rate, body mass, duration, and workout type are present.
- Missing body mass or generic activity produces low confidence.

## Epic E5: Dashboards And Trends

### Story S5.1: Show daily dashboard
As a user, I want calories, macros, weight trend, workouts, and quick logs on one screen.

Acceptance criteria:
- Dashboard shows consumed, burned, net calories.
- Dashboard shows macro progress.
- Dashboard shows today's workouts and quick actions.

### Story S5.2: Show trends by date range
As a user, I want daily, weekly, monthly, and yearly views to understand progress.

Acceptance criteria:
- Trends include calories in, calories out, net calories, weight, macros, workouts, steps, hydration, sleep, and adherence.
- Charts support date filters.

## Epic E6: Goals And Summaries

### Story S6.1: Track goals
As a user, I want goals for weight, calories, protein, steps, workouts, water, and sleep.

Acceptance criteria:
- Goals store type, target, unit, cadence, and active state.
- Dashboard compares actuals against active goals.

### Story S6.2: Generate weekly local summary
As a user, I want a deterministic weekly summary that works without AI.

Acceptance criteria:
- Summary includes calorie intake, exercise, weight trend, protein adherence, sleep, and consistency.
- Summary avoids medical advice.

## Epic E7: Optional ChatGPT Assistance

### Story S7.1: Parse meals with ChatGPT
As a user, I want optional natural-language meal analysis so meal logging is faster.

Acceptance criteria:
- User sees exact payload before sending.
- API call is opt-in per interaction.
- Response is structured JSON.
- User can edit before saving.
- App works with AI disabled.

### Story S7.2: Generate optional AI weekly summary
As a user, I want optional coaching-style insights based on a bounded weekly summary.

Acceptance criteria:
- User sees date range and exact fields before sending.
- Full HealthKit history is never sent unless explicitly selected.
- Summary includes wellness disclaimer and avoids medical advice.

## Epic E8: Data Control

### Story S8.1: Export and delete local data
As a user, I want to export or delete my data at any time.

Acceptance criteria:
- Export is local and user-initiated.
- Delete all data requires confirmation.
- No cloud database is used.

