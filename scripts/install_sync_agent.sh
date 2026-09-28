#!/bin/zsh
# Install (or remove) the background film sync.
#   ./scripts/install_sync_agent.sh              install and start
#   ./scripts/install_sync_agent.sh --uninstall  stop and remove
set -e
cd "$(dirname "$0")/.."
REPO=$(pwd)
LABEL=com.campexperts.filmsync
DEST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [[ "$1" == "--uninstall" ]]; then
  rm -f "$DEST"
  echo "Background film sync removed."
  exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents" build-device/sync
sed "s|__REPO__|$REPO|g" scripts/$LABEL.plist > "$DEST"
launchctl bootstrap "gui/$(id -u)" "$DEST"
echo "Background film sync installed: checks every 5 minutes while this Mac is awake."
echo "Progress:  tail -f $REPO/build-device/sync/agent.log"
echo "Status:    ./scripts/sync_media.sh status"
