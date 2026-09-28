#!/bin/zsh
# Keep the Vision Pro's films in step with CampExperts/Resources/CampMedia.
#
#   ./scripts/sync_media.sh              send anything missing or changed; keeps
#                                        retrying while the headset is asleep
#   ./scripts/sync_media.sh modin        re-send just these films (by camp id)
#   ./scripts/sync_media.sh status       what's on the headset right now
#   ./scripts/sync_media.sh --agent      one quiet pass (the background agent)
#
# Films travel in 256 MB parts, so the headset sleeping mid-transfer costs
# at most one part (~1–2 min). Parts land in the app's Documents container
# under CampMedia/<id>/incoming/<bytes>/ with a ready-<n> flag sent last;
# the app stitches each complete film into master.aivu the next time it
# launches or someone puts the headset on. A film counts as synced once
# the headset holds it at the Mac's exact byte size (stitched, or fully
# delivered and awaiting stitching). Replace a master.aivu on the Mac and
# only that film is re-sent. Nothing is ever deleted on the headset from
# here (devicectl's remove-existing-content wipes all of Documents).
cd "$(dirname "$0")/.."

DEVICE=4A31FA7E-8196-58BA-A3F9-8CB3DEB6EA32
BUNDLE=com.campexperts.threshold
MEDIA=CampExperts/Resources/CampMedia
STATE=build-device/sync
PART_SIZE=256m
mkdir -p "$STATE/parts"
: > "$STATE/empty-flag"

MODE=interactive
FORCE=()
case "$1" in
  --agent) MODE=agent ;;
  status)  MODE=status ;;
  "")      ;;
  *)       FORCE=("$@") ;;
esac

say()    { print -r -- "$(date '+%H:%M:%S')  $*"; }
notify() { [[ $MODE == agent ]] && osascript -e "display notification \"$1\" with title \"Camp Experts films\"" >/dev/null 2>&1; }

IDS=(_intro ${(f)"$(ls "$MEDIA" | grep -v -e '^_intro$' -e README)"})

listing() { xcrun devicectl device info files --device "$DEVICE" --timeout 60 \
              --domain-type appDataContainer --domain-identifier "$BUNDLE" \
              --subdirectory Documents --json-output "$STATE/files.json" >/dev/null 2>&1; }
send()    { xcrun devicectl device copy to --device "$DEVICE" --timeout 900 \
              --domain-type appDataContainer --domain-identifier "$BUNDLE" \
              --source "$1" --destination "Documents/$2" >>"$STATE/last.log" 2>&1; }

# Headset file sizes, as "relative/path bytes" lines, for everything under CampMedia.
headset_files() {
  listing || return 1
  python3 - "$STATE/files.json" <<'EOF'
import json, sys
for f in json.load(open(sys.argv[1]))["result"]["files"]:
    p = f["relativePath"]
    if p.startswith("CampMedia/") and not f["resources"]["isDirectory"]:
        print(p, f["metadata"]["size"])
EOF
}

# Split a film into parts once (kept until the film is delivered).
parts_for() {
  local id=$1 bytes=$2 dir="$STATE/parts/$1/$2"
  if [[ ! -f "$dir/.complete" ]]; then
    rm -rf "$STATE/parts/$id"; mkdir -p "$dir"
    split -b $PART_SIZE -a 3 "$MEDIA/$id/master.aivu" "$dir/part-" && touch "$dir/.complete"
  fi
  print -r -- "$dir"
}

# Single-runner lock, so the background agent and a manual run never collide.
LOCK="$STATE/lock"
if [[ $MODE != status ]]; then
  if ! mkdir "$LOCK" 2>/dev/null; then
    if kill -0 "$(cat "$LOCK/pid" 2>/dev/null)" 2>/dev/null; then
      [[ $MODE == agent ]] && exit 0
      say "a sync is already running (pid $(cat "$LOCK/pid")) — progress: tail -f $STATE/agent.log"
      exit 0
    fi
    rm -rf "$LOCK"; mkdir "$LOCK"
  fi
  echo $$ > "$LOCK/pid"
  trap 'rm -rf "$LOCK"' EXIT
fi

forced=("${FORCE[@]}")
while true; do
  typeset -A dev
  dev=()
  if ! lines=$(headset_files); then
    [[ $MODE != interactive ]] && { say "headset not reachable (asleep or off Wi-Fi)"; exit 0; }
    say "headset not reachable — put it on; retrying in 20s"
    sleep 20; continue
  fi
  for line in ${(f)lines}; do dev[${line% *}]=${line##* }; done

  # Classify every film.
  todo=(); synced=(); pending=()
  for id in $IDS; do
    bytes=$(stat -f %z "$MEDIA/$id/master.aivu" 2>/dev/null) || continue
    base="CampMedia/$id"
    stitched=0; delivered=0
    [[ -n ${dev[$base/master.ok]} && ${dev[$base/master.aivu]} == $bytes ]] && stitched=1
    for k in ${(k)dev}; do [[ $k == $base/incoming/$bytes/ready-* ]] && delivered=1; done
    if (( ${forced[(Ie)$id]} )) && (( ! delivered )); then todo+=$id
    elif (( stitched )); then synced+=$id
    elif (( delivered )); then pending+=$id
    else todo+=$id; fi
  done
  total=$(( ${#synced} + ${#pending} + ${#todo} ))
  on=$(( ${#synced} + ${#pending} ))

  if [[ $MODE == status ]]; then
    print "Films on the headset: $on of $total"
    for id in $IDS; do
      [[ -f "$MEDIA/$id/master.aivu" ]] || continue
      if (( ${synced[(Ie)$id]} )); then mark="✓ ready to play"
      elif (( ${pending[(Ie)$id]} )); then mark="✓ delivered — stitches next time the app opens"
      else
        got=0; for k in ${(k)dev}; do [[ $k == CampMedia/$id/incoming/*/part-* ]] && got=$((got+1)); done
        (( got )) && mark="… $got parts so far" || mark="— not yet"
      fi
      printf "  %-16s %6s  %s\n" "$id" "$(du -h "$MEDIA/$id/master.aivu" | cut -f1)" "$mark"
    done
    exit 0
  fi

  say "=== $on of $total films on the headset ==="
  if (( ${#todo} == 0 )); then
    say "=== ALL FILMS DELIVERED ==="
    [[ ! -f "$STATE/all-done" ]] && notify "All $total films are on the headset."
    touch "$STATE/all-done"
    exit 0
  fi
  rm -f "$STATE/all-done"

  id=$todo[1]
  bytes=$(stat -f %z "$MEDIA/$id/master.aivu")
  dir=$(parts_for $id $bytes)
  local_parts=("$dir"/part-*)
  dest="CampMedia/$id/incoming/$bytes"
  (( ${forced[(Ie)$id]} )) && forced_now=1 || forced_now=0
  say "→ $id ($(du -h "$MEDIA/$id/master.aivu" | cut -f1), ${#local_parts} parts)"

  failed=0; sent=0
  for part in $local_parts; do
    name=${part:t}
    if (( ! forced_now )) && [[ ${dev[$dest/$name]} == $(stat -f %z "$part") ]]; then continue; fi
    if send "$part" "$dest/$name"; then
      sent=$((sent + 1)); print -rn -- "  ▪ $name"
    else
      failed=1; break
    fi
  done
  print
  if (( ! failed )) && send "$STATE/empty-flag" "$dest/ready-${#local_parts}"; then
    say "✓ $id delivered ($sent parts sent)"
    forced=(${forced:#$id})
    rm -rf "$STATE/parts/$id"
    notify "$id is on the headset ($((on + 1)) of $total)."
  else
    [[ $MODE == agent ]] && { say "✗ $id paused (headset asleep?) — next pass picks up where this left off"; exit 0; }
    say "✗ $id paused (headset asleep or link dropped) — retrying in 20s; finished parts are kept"
    sleep 20
  fi
done
