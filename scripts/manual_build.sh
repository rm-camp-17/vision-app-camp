#!/bin/zsh
# Manual simulator build — bypasses xcodebuild's build service, which
# PC Matic wedges on this machine (SWBBuildService spawns probes whose
# output is never drained). swiftc + hand-assembled bundle is enough for
# this single-target app: no packages, no asset catalogs, folder-reference
# resources. Media is cloned (APFS, instant, no extra space).
#
#   ./scripts/manual_build.sh          # build
#   ./scripts/manual_build.sh run      # build + install + launch
set -e
cd "$(dirname "$0")/.."

APP=build/Manual/CampExperts.app
SDK=$(xcrun -sdk xrsimulator --show-sdk-path)

mkdir -p "$APP"
echo "— compiling"
xcrun -sdk xrsimulator swiftc \
  -parse-as-library \
  -target arm64-apple-xros26.0-simulator \
  -Onone -g \
  -module-name CampExperts \
  CampExperts/**/*.swift \
  -o "$APP/CampExperts"

echo "— assembling bundle"
cp CampExperts/Info.plist "$APP/Info.plist"
# pb <key> <type> <value>: Set (no type) if present, else Add (with type)
pb() { /usr/libexec/PlistBuddy -c "Set :$1 $3" "$APP/Info.plist" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$APP/Info.plist"; }
pb CFBundleExecutable string CampExperts
# Expand the build-setting placeholders xcodebuild would substitute:
pb CFBundleIdentifier string com.campexperts.threshold
pb CFBundleName string CampExperts
pb CFBundleDevelopmentRegion string en
# Keys xcodebuild would inject from build settings:
/usr/libexec/PlistBuddy -c "Delete :UIDeviceFamily" "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIDeviceFamily array" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Add :UIDeviceFamily:0 integer 7" "$APP/Info.plist"
pb MinimumOSVersion string 26.0
pb DTPlatformName string xrsimulator
pb CFBundlePackageType string APPL

for folder in CampMedia Audio; do
  rm -rf "$APP/$folder"
  cp -Rc "CampExperts/Resources/$folder" "$APP/$folder"
done

echo "— compiling app icon"
xcrun actool CampExperts/Assets.xcassets --compile "$APP" \
  --platform xrsimulator --minimum-deployment-target 26.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$APP/.actool-partial.plist" >/dev/null 2>&1
pb CFBundleIconName string AppIcon
rm -f "$APP/.actool-partial.plist"

codesign --force --sign - "$APP" >/dev/null 2>&1

echo "— built $APP"

if [[ "$1" == "run" ]]; then
  xcrun simctl boot "Apple Vision Pro" 2>/dev/null || true
  open -a Simulator
  xcrun simctl install booted "$APP"
  xcrun simctl launch booted com.campexperts.threshold
fi
