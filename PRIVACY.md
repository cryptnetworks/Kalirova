# Privacy

HealthTrack AI is designed for private, on-device wellness tracking.

## What Stays Local

By default, the following stay on the user's device:
- HealthKit imports.
- Manual meals, workouts, water, sleep, mood, notes, and custom metrics.
- User profile and goals.
- Device-reported calories.
- App-estimated calories.
- Local deterministic summaries.
- OpenAI API key stored in Keychain.

## What May Be Sent To ChatGPT

Only when the user opts in for a specific interaction, the app may send:
- Meal text entered by the user.
- Photo-derived meal descriptions if the user chooses to use that feature in the future.
- Nutrition targets needed for the request.
- Date-bounded summary statistics selected for a weekly summary.

Before sending, the app must show the exact payload.

## What Must Not Be Sent By Default

- Full HealthKit history.
- Raw HealthKit samples unrelated to the request.
- Longitudinal personal health records unless explicitly selected.
- API keys in request payloads.

## Data Sharing

HealthTrack AI does not sell health data, share health data with third-party analytics, or use a cloud database.

## API Keys

API keys must be stored in Keychain or provided by a production backend token proxy. API keys, tokens, local config, and secrets must never be committed.

## Disclaimer

This app is for wellness tracking only and is not medical advice.

