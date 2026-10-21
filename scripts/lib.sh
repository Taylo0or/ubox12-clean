#!/bin/bash
# Shared helpers for the ubox12-clean skill. Source this from every step script.
#   TV_HOST  box IP (required)      TV_PORT  adb port, 7896 on UBOX 12 firmware (default)
#   TOOLKIT  cleanyourtv checkout with tools/venv (default ~/src/ubox/cleanyourtv)
set -u
: "${TV_HOST:?set TV_HOST=<box ip>}"
export TV_HOST TV_PORT="${TV_PORT:-7896}"
export TOOLKIT="${TOOLKIT:-$HOME/src/ubox/cleanyourtv}"
export SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ASSETS="$SKILL_DIR/assets"
PY="$TOOLKIT/tools/venv/bin/python"
TVPY="$TOOLKIT/tools/tv.py"

ensure_toolkit() {
  if [ ! -f "$TVPY" ]; then
    mkdir -p "$(dirname "$TOOLKIT")"
    git clone --depth 1 https://github.com/Gathin23/cleanyourtv "$TOOLKIT" || { echo "clone failed"; exit 1; }
  fi
  if [ ! -x "$PY" ]; then
    python3 -m venv "$TOOLKIT/tools/venv" && "$PY" -m pip -q install -r "$TOOLKIT/tools/requirements.txt" || { echo "venv failed"; exit 1; }
  fi
  # tv.py's 120 s read timeout is fine; the 30 s variant from the first run breaks b64push/long commands.
  grep -q 'def connect(timeout=120)' "$TVPY" || sed -i '' 's/def connect(timeout=[0-9]*)/def connect(timeout=120)/' "$TVPY"
}

# tv '<shell command>'   run on the box (venv python: Homebrew python3 is blocked by macOS local-network privacy)
tv() { "$PY" -I "$TVPY" "$@" 2>&1 | grep -vE '^(\s|Traceback)'; }   # keeps the final "Exception: ..." line, drops the stack
tvq() { "$PY" -I "$TVPY" "$@" 2>/dev/null; }

# nc_install <local.apk> <remote-name>   adb push/sync is broken on this adbd; netcat works in seconds.
nc_install() {
  local APK="$1" NAME="$2" PORT=5556 LOG
  LOG=$(mktemp)
  "$PY" -I "$TVPY" "rm -f /data/local/tmp/$NAME; nc -l -p $PORT > /data/local/tmp/$NAME; md5sum /data/local/tmp/$NAME" > "$LOG" 2>&1 &
  local LPID=$!
  sleep 3
  for i in $(seq 1 30); do nc -w 5 "$TV_HOST" $PORT < "$APK" 2>/dev/null && break; sleep 1; done
  wait $LPID
  local R L; R=$(grep -oE '^[0-9a-f]{32}' "$LOG"); L=$(md5 -q "$APK"); rm -f "$LOG"
  if [ "$R" != "$L" ]; then echo "nc transfer md5 mismatch for $NAME (remote=$R local=$L)"; return 1; fi
  local OUT; OUT=$(tvq "pm install -r /data/local/tmp/$NAME 2>&1 | tail -1; rm -f /data/local/tmp/$NAME")
  echo "$NAME: $OUT"; case "$OUT" in *Success*) return 0;; *) return 1;; esac
}

# uitap: tap / find UI nodes by resource-id suffix or text. See uitap.py.
uitap() { "$PY" -I "$SKILL_DIR/scripts/uitap.py" "$@"; }

shot() { tvq "screencap -p /data/local/tmp/shot.png" >/dev/null; tvq --pull /data/local/tmp/shot.png "${1:-/tmp/ubox-shot.png}" >/dev/null; echo "screenshot: ${1:-/tmp/ubox-shot.png}"; }

wait_for_box() {   # wait_for_box [max_seconds]  after a reboot: port down, then up, then boot_completed
  local MAX="${1:-240}" t=0
  until ! nc -z -G 1 "$TV_HOST" "$TV_PORT" 2>/dev/null; do sleep 2; t=$((t+2)); [ $t -ge 60 ] && break; done
  until nc -z -G 1 "$TV_HOST" "$TV_PORT" 2>/dev/null; do sleep 3; t=$((t+3)); [ $t -ge $MAX ] && { echo "box did not come back"; return 1; }; done
  sleep 20
  until [ "$(tvq 'getprop sys.boot_completed' | tr -d '\r\n ')" = "1" ]; do sleep 5; t=$((t+5)); [ $t -ge $MAX ] && { echo "boot not completed"; return 1; }; done
  echo "box is up ($t s)"
}

reboot_box() {   # tv.py blocks on 'reboot' until its read timeout, so detach it
  ( "$PY" -I "$TVPY" 'reboot' >/dev/null 2>&1 & ); sleep 5
}
