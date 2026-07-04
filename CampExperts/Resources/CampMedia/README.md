# CampMedia — drop-in spec

This folder ships inside the app bundle as a **folder reference** (blue in
Xcode), so anything placed here is bundled automatically on the next build.
No project-file edits, ever.

One folder per camp, named for the id in `CampCatalog.swift`:

```
CampMedia/
  c01/
    loop.mov      the map lens proxy  (required for a living lens)
    master.aivu   the immersive master (the destination)
  c02/
    ...
```

Media is git-ignored — bundle sizes here will be tens of gigabytes once
real footage lands, and that belongs on the expo build machine, not in
version control. Run `scripts/make_placeholders.sh` to generate stand-ins.

## loop.mov — the lens proxy

The small, muted, flat loop that lives inside a camp's circular lens on
the map. Twenty of these decode simultaneously, so keep them tiny:

- 512×512 (square — the lens is a circle cut from the center)
- 8–15 seconds, seamless loop preferred
- HEVC or H.264, ~1–2 Mb/s, 24 fps, no audio track needed (muted anyway)
- Slow imagery reads best at this size: water, light through trees,
  a drifting canoe. Nothing hectic — these are points of light, not TVs.

Encode example:

```
ffmpeg -i in.mov -vf "crop=ih:ih,scale=512:512" -r 24 \
  -c:v hevc_videotoolbox -b:v 1500k -tag:v hvc1 -an loop.mov
```

## master.aivu — the immersive master

Apple Immersive Video Universal, exactly as delivered from the Blackmagic
URSA Cine Immersive pipeline (DaVinci Resolve Studio exports .aivu
directly). 3–5 minutes; playback returns to the map automatically when
the file ends. Spatial audio travels inside the file.

Fallback chain while masters are pending, per camp:
`master.aivu` → `master.mov` (flat, any resolution) → `loop.mov`.
Flat stand-ins play as a floating screen in the dark rather than a full
envelopment — the journey stays testable end to end.
