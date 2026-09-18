#!/usr/bin/env bash
# iOS 시뮬레이터용 빌드 스크립트 (Xcode 27 RC 우선, 없으면 기본 Xcode 사용)
set -euo pipefail
cd "$(dirname "$0")/.."

XCODE_RC="/Applications/Xcode-27.0-RC.app/Contents/Developer"
if [ -d "$XCODE_RC" ]; then
  DEVELOPER_DIR="$XCODE_RC"
  XCODEBUILD="$XCODE_RC/usr/bin/xcodebuild"
else
  DEVELOPER_DIR="$(xcode-select -p)"
  XCODEBUILD="xcodebuild"
fi

DEVICE="${SIM_DEVICE:-iPhone 17}"
OS="${SIM_OS:-27.0}"

env DEVELOPER_DIR="$DEVELOPER_DIR" "$XCODEBUILD" \
  -project Knock.xcodeproj \
  -scheme Knock \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  -derivedDataPath build \
  -configuration Debug \
  build "$@"
