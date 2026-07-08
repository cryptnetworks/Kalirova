# Sprint Retrospective

## Sprint 0

Status: In Progress

What went well:
- The privacy-first architecture, SCRUM workflow, and main app surfaces were established in one foundation slice.
- Core health calculations were separated from HealthKit so they can be unit tested without private health samples.

What could improve:
- Local developer prerequisites need to be resolved before commits, builds, tests, and GitHub publishing can complete.

Action items:
- Accept the Apple SDK license from an interactive terminal.
- Re-authenticate GitHub CLI.
- Run `swift test` and an iOS simulator build after the license gate is resolved.
