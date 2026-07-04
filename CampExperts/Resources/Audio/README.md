# Audio — drop-in spec

Two files, both optional (every call site degrades to silence):

- `ambience.m4a` — the bed under the map. Near-silent, loopable,
  60–120 s. Think night air, distant water. It should be felt, not heard;
  the app plays it at 16% volume.
- `swell.m4a` — the crossing. A single low bloom, 4–6 s, that rises as
  the chosen lens approaches and decays into the dark hold. No melody,
  no branding sting.

This folder is a folder reference: drop files in, build, done.
`scripts/make_placeholders.sh` generates serviceable stand-ins for both.
