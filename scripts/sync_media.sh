#!/bin/zsh
# Copy the immersive films into the installed app's Documents container,
# one film at a time. Resumable: every completed film gets a master.ok
# marker and is skipped on later runs, so the 50 GB library can land in
# short stints (the headset only transfers while it's awake — on a head).
# Films persist across app reinstalls, so weekly re-signing never
# repeats this.
#
#   ./scripts/sync_media.sh          # sync everything not yet on the headset
#
# Safe to Ctrl-C and re-run anytime. Interrupted films restart from zero
# (a film is 1.6–3 GB, ~3–6 min on a good link); finished ones never do.
cd "$(dirname "$0")/.."

DEVICE=4A31FA7E-8196-58BA-A3F9-8CB3DEB6EA32
BUNDLE=com.campexperts.threshold
MEDIA=CampExperts/Resources/CampMedia
STATE=build-device/sync
mkdir -p "$STATE"
echo ok > "$STATE/master.ok"

# Intro first (it's the first thing a guest sees), then everything else.
IDS=(_intro ${(f)"$(ls "$MEDIA" | grep -v -e '^_intro$' -e README)"})
TOTAL=${#IDS}

dc() { xcrun devicectl device "$@" --device "$DEVICE" \
         --domain-type appDataContainer --domain-identifier "$BUNDLE"; }

done_on_device() {
  dc info files --subdirectory Documents --json-output "$STATE/files.json" >/dev/null 2>&1 || return 1
  python3 - "$STATE/files.json" <<'EOF'
import json, sys
files = json.load(open(sys.argv[1]))["result"]["files"]
for f in files:
    if f["relativePath"].endswith("/master.ok"):
        print(f["relativePath"].split("/")[1])
EOF
}

attempt=0
while true; do
  have=("${(@f)$(done_on_device)}")
  if [[ $? -ne 0 ]]; then
    echo "… headset not reachable (asleep?) — put it on; retrying in 20s"
    sleep 20; continue
  fi
  remaining=()
  for id in $IDS; do
    (( ${have[(Ie)$id]} )) || remaining+=$id
  done
  echo "=== $((TOTAL - ${#remaining})) of $TOTAL films on the headset ==="
  (( ${#remaining} == 0 )) && { echo "=== ALL FILMS SYNCED ==="; exit 0; }

  id=$remaining[1]
  src="$MEDIA/$id/master.aivu"
  [[ -f "$src" ]] || { echo "!! no master for $id locally — skipping"; IDS=(${IDS:#$id}); TOTAL=${#IDS}; continue; }
  size=$(du -h "$src" | cut -f1)
  echo "→ $id ($size) …  $(date +%H:%M:%S)"
  if dc copy to --source "$src" --destination "Documents/CampMedia/$id/master.aivu" >"$STATE/last.log" 2>&1 \
     && dc copy to --source "$STATE/master.ok" --destination "Documents/CampMedia/$id/master.ok" >>"$STATE/last.log" 2>&1; then
    echo "✓ $id  $(date +%H:%M:%S)"
    attempt=0
  else
    attempt=$((attempt + 1))
    echo "✗ $id interrupted (headset asleep or link dropped) — retrying in 20s [$attempt]"
    sleep 20
  fi
done
