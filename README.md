# BallChart

Basketball academy app (Flutter) + Node API.

## iOS build (fix “Module audioplayers_darwin not found” / “Missing package product FlutterGeneratedPluginSwiftPackage”)

Flutter 3.44+ links most plugins via **Swift Package Manager**. The package lives under `ios/Flutter/ephemeral/` and is **not** in git — Xcode will fail if it is missing.

**Before opening Xcode**, run:

```bash
./ios/open_in_xcode.sh
```

Or manually:

```bash
./ios/prepare_for_xcode.sh
open ios/Runner.xcworkspace
```

If you see **Missing package product 'FlutterGeneratedPluginSwiftPackage'**, you opened Xcode before running the steps above (or ran `flutter clean`). Close Xcode, run `./ios/prepare_for_xcode.sh`, then reopen the **workspace**.

If pods are stale:

```bash
flutter clean && flutter pub get
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter build ios --no-codesign
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# BallChart
