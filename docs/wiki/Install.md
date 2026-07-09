# Install

## Requirements

- macOS with full Xcode installed
- Xcode 26.6 or newer stable Xcode when available
- Swift 6 toolchain. Current local validation uses Swift 6.3.3
- iOS 17 SDK or newer. Kalirova keeps iOS 17 as the deployment target for device compatibility
- A physical iPhone for HealthKit functionality
- Apple Developer signing team for physical-device builds

## Steps

1. Clone the repository:

   ```sh
   git clone https://github.com/cryptnetworks/Kalirova.git
   cd Kalirova
   ```

2. Open `Kalirova.xcodeproj` in Xcode.
3. Select the `Kalirova` scheme.
4. Select a simulator or a physical iPhone.
5. Configure a development team for signing.
6. Run the app with Product > Run.

Local development builds intentionally omit iCloud/CloudKit entitlements so Personal Development Teams can sign `com.kalirova.app`. iCloud Backup requires a paid Apple Developer account, the iCloud capability, the `iCloud.com.kalirova.app` CloudKit container entitlement, and the `ENABLE_ICLOUD_BACKUP` Swift compilation condition.

## Command-Line Build

```sh
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Run Swift package tests:

```sh
swift test
```
