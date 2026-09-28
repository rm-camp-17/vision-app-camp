#!/bin/zsh
# Signed DEVICE build without xcodebuild — this machine's Swift Build
# service hangs on toolchain probes (everywhere: CLI, Terminal, Xcode
# GUI), so we compile with swiftc, assemble the bundle by hand, and
# sign with the certificate + Xcode-managed profile that the Signing
# pane mints without building. Install/launch go through devicectl,
# which does not touch Swift Build.
#
#   ./scripts/device_build.sh                 # build + sign (slim, ~50 MB)
#   ./scripts/device_build.sh install         # ... then install to headset
#   ./scripts/sync_media.sh                   # then copy the films, resumably
#
# Free-tier note: the profile expires weekly; re-run Xcode's Signing
# pane (open project, let it refresh) if signing starts failing, then
# re-run this script.
set -e
cd "$(dirname "$0")/.."

APP=build-device/Manual/CampExperts.app
IDENTITY="Apple Development: rileymcdono@aol.com (TTQS5M8V29)"
PROFILE="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/bef4c332-6836-4094-91bb-fce3b1bafb21.mobileprovision"
DEVICE=4A31FA7E-8196-58BA-A3F9-8CB3DEB6EA32   # Riley's Apple Vision Pro

rm -rf "$APP"; mkdir -p "$APP"

echo "— compiling (device, arm64)"
xcrun -sdk xros swiftc \
  -parse-as-library \
  -target arm64-apple-xros26.0 \
  -O \
  -module-name CampExperts \
  CampExperts/**/*.swift \
  -o "$APP/CampExperts"

echo "— assembling bundle"
cp CampExperts/Info.plist "$APP/Info.plist"
pb() { /usr/libexec/PlistBuddy -c "Set :$1 $3" "$APP/Info.plist" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$APP/Info.plist"; }
pb CFBundleExecutable string CampExperts
pb CFBundleIdentifier string com.campexperts.threshold
pb CFBundleName string CampExperts
pb CFBundleDevelopmentRegion string en
/usr/libexec/PlistBuddy -c "Delete :UIDeviceFamily" "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIDeviceFamily array" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Add :UIDeviceFamily:0 integer 7" "$APP/Info.plist"
pb MinimumOSVersion string 26.0
pb DTPlatformName string xros
pb CFBundlePackageType string APPL

for folder in CampMedia Audio; do
  cp -Rc "CampExperts/Resources/$folder" "$APP/$folder"
done

# The films never ride inside the device app: a 50 GB bundle means a
# 2-hour, all-or-nothing install every time the free profile expires.
# The app ships slim (loops + audio) and scripts/sync_media.sh copies
# the masters into its Documents container one film at a time; they
# survive reinstalls, so weekly re-signing never moves them again.
find "$APP/CampMedia" \( -name master.aivu -o -name master.mov \) -delete

echo "— compiling app icon"
xcrun actool CampExperts/Assets.xcassets --compile "$APP" \
  --platform xros --minimum-deployment-target 26.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$APP/.actool-partial.plist" >/dev/null 2>&1
pb CFBundleIconName string AppIcon
rm -f "$APP/.actool-partial.plist"

echo "— signing"
ENT=build-device/entitlements.plist
security cms -D -i "$PROFILE" > build-device/profile.plist
python3 - "$ENT" <<'EOF'
import plistlib, sys
with open('build-device/profile.plist','rb') as f:
    prof = plistlib.load(f)
with open(sys.argv[1],'wb') as f:
    plistlib.dump(prof['Entitlements'], f)
EOF
cp "$PROFILE" "$APP/embedded.mobileprovision"
codesign --force --sign "$IDENTITY" --entitlements "$ENT" "$APP"
codesign --verify --deep "$APP" && echo "— signed OK"

echo "— built $APP"

if [[ "$1" == "install" || "$2" == "install" ]]; then
  echo "— installing to Vision Pro (the big copy — be patient)"
  xcrun devicectl device install app --device "$DEVICE" "$APP"
fi
