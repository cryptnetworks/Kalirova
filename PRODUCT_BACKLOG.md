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
- Xcode project opens as `Kalirova.xcodeproj` and builds the Kalirova app product.
- App bundle identifiers do not contain personal names and use `com.kalirova.app` for the app target.
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
- Height, date of birth or age, weight, biological sex, activity level, and goal weight support typed input.
- Imperial and metric input are supported.
- BMI updates immediately after height and weight are entered.
- BMI includes an info sheet explaining standard adult BMI categories and that BMI is a screening tool, not a diagnosis.

### Story S1.3: Choose preferred units
As a user, I want to choose imperial or metric units so health data is displayed in familiar units while storage remains normalized.

Acceptance criteria:
- User can choose Imperial or Metric during onboarding and in settings.
- Height, weight, distance, and body measurements display according to preference.
- Internal persisted values remain normalized in metric units where appropriate.
- Nutrition portion labels preserve user-entered context where applicable.

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
- First HealthKit authorization imports workouts from the last 90 days.
- Manual “Import Last 90 Days” action is available.
- Imports include workout type, start/end date, duration, distance, active energy, average heart rate when available, and source app/device when available.
- Duplicate imports are skipped using stable HealthKit identifiers.
- Import shows loading state and a summary of imported, skipped duplicate, and errored items.

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
- Meal entries do not require a user-provided title.
- Meals are grouped by date and meal type: breakfast, lunch, dinner, snack, or custom.
- Users can add multiple food items to the same meal/date container without duplicate meal sections.
- Dashboard displays meals grouped by day and meal type.

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

### Story S7.3: Estimate restaurant meals with ChatGPT
As a user, I want optional ChatGPT restaurant meal estimates so I can log meals when restaurant nutrition details are incomplete.

Acceptance criteria:
- User can enter restaurant name, food item, portion or measurement, and notes/modifications.
- User sees the exact meal information payload before sending it to OpenAI.
- OpenAI response includes calories, protein, carbs, fat, confidence, assumptions, and source or estimation notes when available.
- AI estimates are never saved automatically; user must confirm or edit before saving.
- UI clearly states restaurant estimates may vary by preparation and portion size.
- App still works without an API key.
- OpenAI API keys are saved only in iOS Keychain using service `com.kalirova.app` and account `openai_api_key`.
- Settings can load, mask, update, test, and delete the saved OpenAI API key without displaying or logging the full key.

## Epic E9: Apple Platform Experience

### Story S9.1: Align UI with Apple Human Interface Guidelines
As a user, I want Kalirova to feel like a native iOS app with accessible system behavior.

Acceptance criteria:
- Core flows use native SwiftUI `NavigationStack`, `Form`, `List`, `Section`, `Picker`, `DatePicker`, `Sheet`, `ConfirmationDialog`, `ToolbarItem`, and SF Symbols where appropriate.
- Spacing, hierarchy, typography, accessibility labels, Dynamic Type, and contrast are improved.
- Liquid Glass visual treatment is used where available on iOS 26 with availability checks and graceful fallbacks.

### Story S9.2: Apply Kalirova brand identity
As a user, I want the app to present consistently as Kalirova so the product feels cohesive and recognizable.

Acceptance criteria:
- Visible app display name is Kalirova.
- App bundle identifier is unique and uses the Kalirova brand.
- Xcode project, app target, test target, scheme, Swift package target, source folders, and repository references use Kalirova naming.
- HealthKit purpose strings mention Kalirova without changing HealthKit entitlements.
- App icon and brand assets from the Kalirova brand package are available in the Xcode asset catalog.
- README, backlog, changelog, privacy docs, and architecture docs use the Kalirova product name.

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
- No cloud database is used unless the user explicitly enables private iCloud Backup.

## Epic E10: Optional Private iCloud Backup

### Story S10.1: Opt in to iCloud Backup
As a user, I want to explicitly enable private iCloud backup so I can preserve Kalirova data across devices without changing the default local-first behavior.

Acceptance criteria:
- iCloud Backup is off by default.
- Settings includes an “Enable iCloud Backup” toggle.
- The app warns that Kalirova app data may be stored in the user's private iCloud account and should not be enabled on shared Apple IDs.
- The app shows iCloud availability and last backup time.
- Users can disable iCloud Backup and continue using local-only storage.
- Eligible data includes meals, food items, weight entries, goals, HealthKit-imported workouts, app-estimated calories, non-secret settings, and weekly summaries.
- OpenAI API keys, temporary logs, cache files, debug data, and OpenAI request data are not backed up.
- No data is sent to OpenAI as part of iCloud Backup.
