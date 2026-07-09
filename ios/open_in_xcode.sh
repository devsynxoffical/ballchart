#!/bin/bash
# Prepare iOS deps and open the correct Xcode workspace (never Runner.xcodeproj).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/ios/prepare_for_xcode.sh"

echo "→ Resolving Swift packages in Xcode workspace"
xcodebuild -resolvePackageDependencies \
  -workspace "$ROOT/ios/Runner.xcworkspace" \
  -scheme Runner >/dev/null

echo "→ Opening Runner.xcworkspace"
open "$ROOT/ios/Runner.xcworkspace"
