#!/bin/bash
# Regenerates FlutterGeneratedPluginSwiftPackage (required by Xcode SPM on Flutter 3.44+).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ flutter pub get (generates ios/Flutter/ephemeral/...)"
flutter pub get

PKG="$ROOT/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
if [[ ! -f "$PKG" ]]; then
  echo "→ flutter build ios --no-codesign (SPM package still missing after pub get)"
  flutter build ios --no-codesign
fi

echo "→ pod install"
cd ios
pod install

echo "→ Resolving Swift packages"
xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner >/dev/null

echo ""
echo "Ready. Open ios/Runner.xcworkspace in Xcode (not Runner.xcodeproj)."
echo "Tip: run ./ios/open_in_xcode.sh to prepare and open the workspace automatically."
