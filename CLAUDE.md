# CampExperts — visionOS 26 immersive showcase

Native visionOS app (SwiftUI + RealityKit), zero package dependencies.
Full design rationale, experience script, and asset specs: `README.md`.
Every tunable feel constant (timings, distances, colors): `CampExperts/App/DesignTokens.swift`.
Camp identity (names, coordinates, media folder ids): `CampExperts/Model/CampCatalog.swift` — placeholder data, flagged for replacement.

## Build & run from the CLI

**On Riley's Mac use `./scripts/manual_build.sh run`** (simulator) and
**`./scripts/device_build.sh install` + `./scripts/sync_media.sh`**
(Vision Pro). Both compile with swiftc and assemble the bundle by hand.

Why: xcodebuild and the Xcode GUI hang forever at "ExecuteExternalTool
clang -v -E -dM … -c /dev/null" (0% CPU; the clang is blocked in
`write()`). Root cause is NOT PC Matic (that was a wrong guess): macOS's
pipe-buffer memory is nearly exhausted on this long-uptime Mac (ChatGPT's
`codex` app-server was the largest holder), so new pipes get 512-byte
buffers and the probe's ~20 KB of output deadlocks against Swift Build's
reader. Check with a nonblocking-write probe (healthy = 16–64 KB before
EAGAIN; broken = 512). A real restart resets it, after which the standard
path below works.

Device installs: the app ships slim (52 MB, loops + audio); reinstall it
weekly (free-tier profile) with `./scripts/device_build.sh install`. Films
go separately and survive reinstalls: `scripts/sync_media.sh` sends each
in 256 MB parts to `Documents/CampMedia/<id>/incoming/<bytes>/`, ready
flag last; the app (MediaLibrary.swift) stitches complete films on launch
and on headset-on, stamping `master.ok` with the byte count. A LaunchAgent
(`scripts/install_sync_agent.sh`, log in `build-device/sync/agent.log`)
runs a pass every 5 minutes. `sync_media.sh status` shows what's on the
headset; `sync_media.sh <id>` force re-sends one film; replacing a master
on the Mac re-sends just that film automatically.

NEVER use devicectl's `--remove-existing-content`: it wipes the app's
entire Documents folder, not the named subfolder. Killing a devicectl
client doesn't stop CoreDeviceService's transfer — restart that service.

Booth-flow diagnostics (note `--info` — the flow log is info level):

```sh
xcrun simctl spawn booted log show --info --last 5m \
  --predicate 'subsystem == "com.campexperts.threshold"' --style compact
```

```sh
# Standard path (hangs on this Mac until a real restart — see above)
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
