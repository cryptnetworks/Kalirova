# Performance

Kalirova is local-first and should keep routine tracking responsive without unnecessary network, HealthKit, or persistence work.

## Optimized Areas

- Dashboard totals now summarize meals, workouts, and health metrics in single passes instead of repeatedly filtering and reducing the same SwiftData query results.
- Insight snapshots now accumulate per-day meals, workouts, and metrics with dictionary-backed grouping instead of filtering every record for every day.
- Long-running AI meal estimates and HealthKit imports are cancellable when the user leaves the flow.
- OpenAI requests use an ephemeral `URLSession`, explicit request/resource timeouts, no persistent URL cache, and status-only diagnostics.
- HealthKit workout import no longer caps the 90-day import at 100 workouts and skips duplicate workout identifiers before inserting new records.
- Lightweight `os.Logger` diagnostics cover app lifecycle, persistence mode, HealthKit authorization/import status, and OpenAI HTTP status without logging API keys, meal text, weight values, or health samples.

## Local Checks

```sh
swift package show-dependencies
swift test
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS' -configuration Debug build
xcodebuild test -project Kalirova.xcodeproj -scheme Kalirova -destination 'platform=iOS Simulator,name=iPhone 17'
```

SwiftLint is optional. CI runs it only when installed.

## Manual Instruments Pass

Use Xcode Instruments on a physical iPhone for the checks that command-line builds cannot measure well:

- Time Profiler: cold launch, first dashboard render, Meals add flow, Insights chart rendering.
- Allocations: repeated tab switching and meal/workout import flows.
- Energy Log: 90-day HealthKit import and OpenAI test/estimate flows.
- Network: confirm OpenAI requests happen only after explicit user action and do not retry automatically.
- Points of Interest or OSLog: verify diagnostics are sparse and contain no personal health values or full API keys.

## Known Limits

- SwiftData `@Query` screens still fetch broad local collections. This is acceptable for early local datasets, but large long-term stores should move high-volume views to date-bounded fetches.
- Real battery and launch performance still require profiling on device with representative local data.
- HealthKit average heart-rate import remains limited by available workout metadata; expanded sample queries should be profiled before adding more HealthKit reads.
