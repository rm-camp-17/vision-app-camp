#!/usr/bin/env bash
#
# Generates stand-in media so the whole journey — map, look, select,
# transport, play, return — runs before a single frame of real footage
# exists. Run once on a Mac with ffmpeg (`brew install ffmpeg`), then
# build in Xcode; the media folders are folder references, so new files
# are picked up automatically.
#
# Per camp:
#   loop.mov    512x512, 8 s, silent, slow drifting color field + grain.
#               Stands in for the flat 2D proxy loop on the map lens.
#   master.mov  1920x1080, 25 s, with quiet sound. Stands in for the
#               .aivu immersive master; plays as a flat screen in the
#               dark until real Apple Immersive Video is dropped in.
#               Kept short on purpose so the auto-return is testable.
#
# Shared:
#   ambience.m4a  the near-silent bed under the map
#   swell.m4a     the low bloom that carries the crossing
#
set -euo pipefail
cd "$(dirname "$0")/.."

MEDIA="CampExperts/Resources/CampMedia"
AUDIO="CampExperts/Resources/Audio"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "ffmpeg is required: brew install ffmpeg" >&2
  exit 1
}

CAMPS=(c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14 c15 c16 c17 c18 c19 c20)

for i in "${!CAMPS[@]}"; do
  id="${CAMPS[$i]}"
  hue=$(( i * 18 ))   # each camp gets its own corner of the spectrum
  mkdir -p "$MEDIA/$id"
  echo "→ $id (hue $hue)"

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "gradients=size=512x512:duration=8:speed=0.015:nb_colors=3:seed=$(( i * 7 + 3 ))" \
    -vf "hue=h=${hue}:s=0.35,eq=brightness=-0.18:saturation=0.9,noise=alls=5:allf=t,format=yuv420p" \
    -r 24 -c:v libx264 -crf 26 -movflags +faststart -an \
    "$MEDIA/$id/loop.mov" </dev/null

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "gradients=size=1920x1080:duration=25:speed=0.01:nb_colors=3:seed=$(( i * 11 + 5 ))" \
    -f lavfi -i "anoisesrc=color=pink:duration=25:amplitude=0.03" \
    -vf "hue=h=${hue}:s=0.30,eq=brightness=-0.15,format=yuv420p" \
    -r 24 -c:v libx264 -crf 24 -c:a aac -shortest -movflags +faststart \
    "$MEDIA/$id/master.mov" </dev/null
done

mkdir -p "$AUDIO"
echo "→ ambience"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "anoisesrc=color=brown:duration=90:amplitude=0.5" \
  -af "lowpass=f=260,volume=0.25,afade=t=in:d=4,afade=t=out:st=86:d=4" \
  -c:a aac "$AUDIO/ambience.m4a" </dev/null

echo "→ swell"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=98:duration=5" \
  -f lavfi -i "sine=frequency=147:duration=5" \
  -filter_complex "[0][1]amix=inputs=2,volume=0.6,lowpass=f=800,afade=t=in:d=1.8,afade=t=out:st=3:d=2" \
  -c:a aac "$AUDIO/swell.m4a" </dev/null

echo "Placeholder media written. Build and run in Xcode."
