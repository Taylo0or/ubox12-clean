#!/bin/bash
# Step 2: disable the Unblock packages (pm disable-user only; recovery record goes to ~/.cleanyourtv/).
source "$(dirname "$0")/lib.sh"; ensure_toolkit
HOME_NOW=$(tvq 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' | tail -1 | tr -d '\r')
case "$HOME_NOW" in com.gathin.tvhome/*) ;; *) echo "run 01-launcher.sh first (Home is $HOME_NOW)"; exit 1;; esac
( cd "$TOOLKIT" && TV_HOST="$TV_HOST" TV_PORT="$TV_PORT" tools/disable.sh "$ASSETS/debloat.txt" 2>&1 | grep -E 'new state|^package:|Skipping|ERROR|recorded' )
echo "== still running from the list? =="; tv 'ps -A -o USER,PID,NAME | grep -E "moons|Upgrade|nanosic|mitac|yanggis|chinatunnel|hpplay|chaozhuo" || echo none'
echo "== listeners (8443/8123 must be gone) =="; tv 'netstat -tlnW 2>/dev/null | grep LISTEN'
