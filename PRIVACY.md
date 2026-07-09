# Privacy

Kalirova is designed for private, on-device wellness tracking.

## What Stays Local

By default, the following stay on the user's device:
- HealthKit imports.
- Manual meals, workouts, water, sleep, mood, notes, and custom metrics.
- User profile and goals.
- Device-reported calories.
- App-estimated calories.
- Local deterministic summaries.
- OpenAI API key stored in Keychain.

## Optional iCloud Backup

iCloud Backup is off by default and disabled in local development builds. Local development builds do not include iCloud/CloudKit entitlements, so supported app data remains on device.

For paid Apple Developer account builds, Kalirova can re-enable the iCloud capability and `ENABLE_ICLOUD_BACKUP` build flag. In those builds, if the user enables iCloud Backup in Settings, Kalirova may store supported app data in the user's private iCloud account through CloudKit.

Data eligible for iCloud Backup:
- Meals and food items.
- Weight entries and other saved health metrics.
- Goals.
- Workouts imported from HealthKit, including device-reported calories and app-estimated calories.
- User settings, excluding API keys and secrets.
- Local weekly summaries.

Data not included in iCloud Backup:
- OpenAI API key.
- Temporary logs.
- Cache files.
- Debug data.
- OpenAI request payloads or responses unless the user separately saves an AI-derived meal or summary as app data.

Users should not enable iCloud Backup on shared Apple IDs. Disabling iCloud Backup returns the app to local-only storage on the device. Local development builds always use local-only storage.

## What May Be Sent To ChatGPT

Only when the user opts in for a specific interaction, the app may send:
- Meal text entered by the user.
- Restaurant meal estimate fields entered by the user: restaurant name, food item, portion or measurement, and notes or modifications.
- Photo-derived meal descriptions if the user chooses to use that feature in the future.
- Nutrition targets needed for the request.
- Date-bounded summary statistics selected for a weekly summary.

Before sending, the app must show the exact payload. Restaurant meal estimates are not saved automatically; the user must review or edit the estimate before saving.

## What Must Not Be Sent By Default

- Full HealthKit history.
- Raw HealthKit samples unrelated to the request.
- Longitudinal personal health records unless explicitly selected.
- API keys in request payloads.

## Data Sharing

Kalirova does not sell health data or share health data with third-party analytics. CloudKit is used only in paid-team builds where optional iCloud Backup has been re-enabled and the user explicitly opts in.

## API Keys

API keys must be stored in Keychain or provided by a production backend token proxy. API keys, tokens, local config, and secrets must never be committed.

Error handling and diagnostics are sanitized. Kalirova logs high-level error titles, IDs, and source areas only; it does not log API keys, tokens, meal contents, HealthKit samples, weight values, or other personal health details.

## Disclaimer

This app is for wellness tracking only and is not medical advice.
