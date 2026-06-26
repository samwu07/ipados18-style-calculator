#!/bin/bash
set -euo pipefail

TEAM_ID="${1:-}"
if [ -z "$TEAM_ID" ]; then
  echo "Usage: ./package_ipa_macos.sh YOUR_APPLE_TEAM_ID"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$ROOT_DIR/iPadOS18StyleCalculator.xcodeproj"
ARCHIVE="$ROOT_DIR/build/iPadOS18StyleCalculator.xcarchive"
EXPORT_DIR="$ROOT_DIR/build/export"

rm -rf "$ROOT_DIR/build"
mkdir -p "$EXPORT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme iPadOS18StyleCalculator \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT_DIR/ExportOptions.plist" \
  -allowProvisioningUpdates

echo "IPA generated at: $EXPORT_DIR/iPadOS18StyleCalculator.ipa"
