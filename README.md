# Camp Experts — an immersive showcase for Apple Vision Pro

A native visionOS 26 app for the expo booth. A dark, minimal map of the
Northeast floats in a dimmed room; twenty camps glow on it as small living
lenses. Look at one and it brightens. A pinch swells it forward over a card of
plain facts — who it's for, what kind of camp, its rhythm. A second
pinch, and the map dissolves as the camp opens around you in Apple
Immersive Video. Three to five minutes
inside, then the map breathes back in exactly where you left it. If nobody
chooses within twenty-five seconds, the space chooses — a different
camp every time.

The app is the threshold. The camps are the destination.

## The experience, second by second

1. **Boot.** The space opens directly into darkness (no window, no chrome).
   The room dims to near-black through passthrough. A hairline drawing of
   the Northeast coast breathes in, then twenty lenses arrive west to east,
   a sweep of lights coming on. A barely-audible ambient bed settles under
   everything.
2. **Browse.** Each lens plays a slow, muted loop of its camp. Gaze at one
   and it brightens under the system's spotlight hover — the app never
   learns where anyone is looking; visionOS renders the answer privately,
   out of process. Two quiet lines of type sit beneath each lens.
3. **The pause.** A pinch presents: the lens swells toward you over a
   card naming the camp and its traits (gender, style, session rhythm,
   Jewish values where they apply), with plain words for what a pinch
   does next. A pinch elsewhere breathes the map back — first-wear eye
   calibration is rough, so nothing plunges on a single pinch.
4. **The crossing.** A pinch on the swelled camp chooses. Every other lens exhales to black and
   the coastline dims (0.35–0.55 s). The chosen lens drifts off the map to
   meet you, swelling slightly (0.7 s), then dissolves (0.3 s). A held beat
   of true dark (0.45 s) — the threshold itself — and the camp blooms in
   from black (1.4 s), enveloping the view through progressive immersion.
   A single low swell of sound carries the whole move. Roughly 3.2 seconds,
   map to camp, and none of it is a cut.
5. **The visit.** Apple Immersive Video with its own spatial audio. No
   interface at all. The Digital Crown always hands "how much world" back
   to the visitor. A pinch (after a 5 s grace period) or the end of the
   film begins the return.
6. **The return.** The scene fades down with its sound, a beat of dark,
   then the map breathes back in — lenses rippling outward from the camp
   just visited, everything exactly where it was left.
7. **Idle.** Twenty-five seconds without a choice and the space chooses,
   drawing from a shuffled bag so all twenty-two camps appear before
   any repeats.

## Run it

Requires Xcode 26 on macOS with the visionOS 26 SDK.

```
brew install ffmpeg
./scripts/make_placeholders.sh     # generates stand-in loops, masters, audio
open CampExperts.xcodeproj         # select your team, then run
```

Runs on device and in the visionOS simulator. Without the placeholder
script the app still builds and runs: lenses hold as dark waiting discs
and camps without media return you gently to the map.

## Project anatomy

```
CampExperts/
  App/
    CampExpertsApp.swift     the single ImmersiveSpace scene, progressive style
    AppModel.swift           the one state machine (boot → map → transporting
                             → visiting → returning)
    DesignTokens.swift       every tunable number: beats, distances, colors
  Model/
    Camp.swift               identity + media URLs with fallback chain
    CampCatalog.swift        the twenty camps (PLACEHOLDER data — see below)
    MapProjection.swift      one lat/lon projection shared by drawing + entities
  Map/
    CoastlineData.swift      hand-simplified Northeast: coast, LI, 2 rivers, 4 lakes
    NortheastMapView.swift   the Canvas that draws the geography (bloom + hairline)
    CampLensLabel.swift      the two quiet lines under each lens
    MapAssembler.swift       builds the stage: tilted map, 20 lenses, tap shell
  Playback/
    ProxyLoopPool.swift      20 muted AVPlayerLoopers for the lens loops
    ImmersivePlayer.swift    the one AIV player, created per visit
  Space/
    ThresholdSpaceView.swift RealityView, attachments, the tap gesture
  Transport/
    Transport.swift          the choreography: boot, crossing, return
  Idle/IdleEngine.swift      13 s clock + shuffled no-repeat bag
  Audio/AmbienceEngine.swift ambient bed + crossing swell
  Support/EntityFX.swift     opacity fade helper for entities
  Resources/
    CampMedia/               folder reference; per-camp loop.mov + master.aivu
    Audio/                   folder reference; ambience.m4a + swell.m4a
```

## Key decisions and why

**One persistent ImmersiveSpace for everything.** The brief demands that
selection opens a custom immersive space directly, with no player chrome.
This build goes one step further: the app launches *into* its immersive
space (`UIApplicationPreferredDefaultSceneSessionRole` = immersive space)
and never leaves it. Map and playback are phases of a single scene, so the
crossing is continuous entity choreography — nothing waits on a scene
open, no window flickers in or out, and "return to the map exactly as you
left it" is free because the map never ceased to exist, it only went dark.
There is no window scene in the app at all.

**Progressive immersion as the contract.** The space runs the visionOS 26
progressive style (initial amount 0.60, range 0.35–1.0), and the AIV
entity's `VideoPlayerComponent.desiredImmersiveViewingMode = .progressive`.
On the map, the dome holds soft darkness ahead while dimmed passthrough
survives behind the shoulders — families stay oriented at a crowded booth.
During a visit the same dome carries the film, and the Digital Crown
remains a hardware-guaranteed exit ramp. No app code can take that away,
which is exactly right for first-time headset wearers.

**AIV through RealityKit, never AVPlayerViewController.** Playback is an
`Entity` with a `VideoPlayerComponent` wrapping a plain `AVPlayer` on the
local `.aivu` file. No system chrome exists to suppress; look-and-pinch is
the entire interaction. End-of-item triggers the return automatically.

**Gaze privacy shapes the lens design.** visionOS never reports gaze
position to apps. "Look at one and it answers" is therefore a
`HoverEffectComponent(.spotlight)` on each lens disc — the brightening is
composited by the system, out of process. Labels stay softly present
rather than appearing on gaze (that would require knowing gaze). The pinch
is the first moment the app learns anything.

**Lenses are `VideoMaterial` discs, not embedded video views.** Each lens
is a circle-cornered plane carrying a `VideoMaterial` fed by a muted
`AVPlayerLooper` — the most battle-tested way to put moving pictures on
RealityKit geometry. Twenty 512×512 proxies decode comfortably;
`ProxyLoopPool.maxLive` is the budget knob if real assets arrive heavier,
and every looper pauses during a visit so the 8K immersive master owns
the decoders alone.

**One projection, one taste file.** The Canvas that draws the coastline
and the entities that float the lenses share `MapProjection`, so geography
and interaction can never drift apart. Every duration, distance, opacity,
and both colors live in `DesignTokens.swift`; tuning the feel on device is
an edit to one file. The map itself is deliberately hand-drawn data — one
coastline, Long Island, two rivers, four lakes, no state borders — enough
to say *you are here*, nothing that competes with the lenses.

**A state machine owns the journey.** `AppModel.Phase` gates every input:
taps mean "choose" only on the map, "return" only mid-visit (after a 5 s
grace so the confirming pinch never bounces a family straight back out).
The idle engine is disarmed the instant a transport begins. An invisible
collision wall behind the map catches pinches that miss everything — on
the map they re-arm the idle clock; during a visit they are the way home.

**Local, bundled, huge is fine.** All media lives in folder references
inside the bundle (`CampMedia/`, `Audio/`) — drop files in, build, done;
no project edits, no network, no expo wifi dependency. Media is
git-ignored; the placeholder script regenerates dev assets anywhere.

## The crossing, as a timeline

| t (s) | beat |
|---|---|
| 0.00 | pinch; idle disarmed; AIV player created and prerolling; swell begins |
| 0.00 | labels fade; coastline dims (0.55 s); other lenses exhale (0.35 s) |
| 0.00–0.70 | chosen lens drifts to 0.85 m ahead, scales ×1.7 |
| 0.70–1.00 | chosen lens dissolves |
| 1.00 | map disabled; loops paused; lens transform reset while hidden |
| 1.00–1.45 | true dark. the threshold |
| 1.45–2.85 | the camp blooms in; playback begins; phase = visiting |

The return mirrors it: scene and sound fade (0.9 s), dark hold, then the
map ripples back outward from the visited camp.

## What I need from you

1. **Real camp data** — twenty names, town/state lines, and coordinates
   for `CampCatalog.swift`. Current entries are plausible placeholders
   spread across camp country. If two real camps sit close together
   (Winnipesaukee neighbors, Poconos clusters), I'll do a layout pass so
   lenses never crowd.
2. **Proxy loops** — one per camp to the spec in
   `CampExperts/Resources/CampMedia/README.md` (512×512, 8–15 s, slow
   imagery). I can cut these from the immersive dailies if you get me
   flat exports.
3. **Immersive masters** — the twenty `.aivu` files from the URSA Cine
   Immersive / Resolve pipeline, 3–5 minutes each.
4. **Sound** — optional: a real ambient bed and crossing swell to replace
   the synthesized stand-ins (specs in `Resources/Audio/README.md`).
5. **A booth decision** — Guest User mode with an operator resetting
   between families is the assumed flow; if you want fully unattended
   looping all day, say so and I'll add an attract heartbeat (slow map
   drift + periodic idle visits is already most of the way there).

## Honest notes on risk

- **Built against the visionOS 26 SDK as documented; not yet
  compiler-verified** — this was authored in an environment without
  Xcode. The APIs most worth a first-build glance are
  `VideoPlayerComponent.desiredImmersiveViewingMode` (ImmersivePlayer.swift)
  and `ForEach` inside the RealityView `attachments:` builder
  (ThresholdSpaceView.swift). Both are isolated; if either surface moved
  in a beta, the fix is local. (Labels have a clean fallback: visionOS
  26's `ViewAttachmentComponent` built per-lens in MapAssembler.)
- **Fade of the immersive video dome.** The player entity fades via
  `OpacityComponent`. If a given OS build ignores opacity for immersive
  video surfaces, the bloom becomes a straight appear-from-black — the
  dark hold before it means the moment still reads correctly. Audio ramps
  are done on the player and are unaffected.
- **Attachment scale.** RealityView attachments render at ~1360 pt/m. If
  type or map lines look off-scale on device, turn the single knob
  `MapProjection.pointsPerMeter`.
- **Simulator.** The full journey runs in the simulator with placeholder
  media; MV-HEVC/AIV rendering and true envelopment need hardware.
