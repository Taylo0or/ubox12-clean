#!/bin/bash
# Step 1: install the prebuilt cleanyourtv launcher (2.5), make it Home, disable the Unblock launcher, push the theme.
source "$(dirname "$0")/lib.sh"; ensure_toolkit
STOCK=com.moons.mylauncher12
nc_install "$ASSETS/launcher/tvhome-2.5.apk" tvhome.apk || exit 1
tv 'am start -W -n com.gathin.tvhome/.MainActivity | grep -E "Status|Error"'
tvq 'am start -W -n com.gathin.tvhome/.MainActivity' | grep -q 'Status: ok' || { echo "launcher did not start; stock launcher left enabled"; exit 1; }
tv "pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION 2>/dev/null; cmd package compile -m speed -f com.gathin.tvhome >/dev/null; pm disable-user --user 0 $STOCK; cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"
HOME_NOW=$(tvq 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' | tail -1 | tr -d '\r')
case "$HOME_NOW" in com.gathin.tvhome/*) echo "Home = $HOME_NOW";; *) echo "Home is $HOME_NOW, restoring $STOCK"; tv "pm enable --user 0 $STOCK"; exit 1;; esac
# theme: dock 影视仓/SmartTube/Netflix/设置 (missing apps are skipped until step 4 installs them), aurora wallpaper, hidden apps
( cd "$TOOLKIT" && TV_HOST="$TV_HOST" TV_PORT="$TV_PORT" tools/theme.sh "$ASSETS/theme2" | tail -1 )
tv 'settings put secure screensaver_components com.gathin.tvhome/.ClockDream; settings put secure screensaver_enabled 1; input keyevent KEYCODE_HOME'
shot /tmp/ubox-01-home.png
