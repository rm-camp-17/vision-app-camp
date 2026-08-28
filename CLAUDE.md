# CampExperts — visionOS 26 immersive showcase

Native visionOS app (SwiftUI + RealityKit), zero package dependencies.
Full design rationale, experience script, and asset specs: `README.md`.
Every tunable feel constant (timings, distances, colors): `CampExperts/App/DesignTokens.swift`.
Camp identity (names, coordinates, media folder ids): `CampExperts/Model/CampCatalog.swift` — placeholder data, flagged for replacement.

## Build & run from the CLI

```sh
# Build for the simulator (predictable output path via -derivedDataPath)
xcodebuild -project CampExperts.xcodeproj -scheme CampExperts \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  -derivedDataPath build build

# Run it
open -a Simulator
xcrun simctl boot "Apple Vision Pro" 2>/dev/null || true
xcrun simctl install booted build/Build/Products/Debug-xrsimulator/CampExperts.app
xcrun simctl launch --console-pty booted com.campexperts.threshold

# Logs from a running app
xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "campexperts" OR process == "CampExperts"' --level debug
```

- The shared scheme `CampExperts` is checked in; `xcodebuild -list` should always work on a fresh clone.
- Device installs go through Xcode or `xcrun devicectl` with a paired Vision Pro.
- Bundle id: `com.campexperts.threshold`.

## Media (the important local-machine part)

- Media is bundled via **folder references**: drop files into
  `CampExperts/Resources/CampMedia/<campID>/` (`loop.mov`, `master.aivu`) and
  `CampExperts/Resources/Audio/` (`ambience.m4a`, `swell.m4a`), rebuild, done.
  Never edit the pbxproj for media.
- Dev placeholders: `./scripts/make_placeholders.sh` (needs ffmpeg).
- Real masters live on an external drive. **Copy real bytes into CampMedia —
  never symlink or use Finder aliases**; links break inside a signed app
  bundle. Resolve aliases first if the drive holds links rather than files.
- Iterate with a 2–3 camp subset of real masters; the full 20-camp load is a
  "release build" (copy + codesign of tens of GB dominates build time).
- All media patterns are git-ignored. Never commit `.mov`/`.aivu`/`.m4a`.

## Gotchas

- First build after installing Xcode can stall many minutes in
  "Create build description" (toolchain probe + Gatekeeper/AV interception).
  Not a project problem — see README "Honest notes on risk".
- Two API spots to sanity-check on first compile against the installed SDK:
  `ImmersivePlayer.swift` (`desiredImmersiveViewingMode`) and
  `ThresholdSpaceView.swift` (`ForEach` inside the attachments builder).
- The simulator runs the whole journey with flat placeholder media; true AIV
  envelopment (.aivu) needs hardware.
- The app has no window scene — it launches straight into its immersive
  space. If nothing appears, check the two `UIApplicationSceneManifest` keys
  in `CampExperts/Info.plist` before suspecting code.
