# Install

## Requirements

- macOS with full Xcode installed
- iOS 17 SDK or newer
- Swift 6 toolchain
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

## Command-Line Build

```sh
xcodebuild -project Kalirova.xcodeproj -scheme Kalirova -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

Run Swift package tests:

```sh
swift test
```
