#!/bin/bash
# Step 4: 影视仓 + SmartTube + Netflix, then configure 影视仓 (VOD lines through its dialog, live through its HTTP API).
source "$(dirname "$0")/lib.sh"; ensure_toolkit
YSC=com.huawei.himovceie; YSC_ACT="$YSC/com.github.tvbox.osc.ui.activity.HomeActivity"
LINE1_NAME="AoWu-OuLe-AiYiFan"; LINE1_URL="https://www.iyouhun.com/tv/aowu"     # 游魂嗷呜: has 欧乐/壹帆
LINE2_NAME="YouHun-DuoCang-24"; LINE2_URL="https://www.iyouhun.com/tv/dc"       # 游魂多仓
LIVE_NAME="游魂直播"; LIVE_URL="https://www.iyouhun.com/tv/zb"
for a in yingshicang-tv32-6.2.8.apk smarttube-32.68-armeabi-v7a.apk netflix-ninja-10.0.6.apk; do nc_install "$ASSETS/apks/$a" "$a" || exit 1; done

add_line() {   # add_line <name> <url>: the 配置 dialog; HTTP pushStore/api return ok but do nothing on 6.2.8
  uitap --text 配置 --wait 5 || return 1; sleep 2
  uitap --id input_source_url --wait 5 || return 1; sleep 1.5
  tvq "input text '$2'"; sleep 1
  uitap --id input_sourceName || return 1; sleep 1          # keyboard shifts the dialog: re-dump finds the new position
  tvq "input text '$1'"; sleep 1
  uitap --id inputSubmit || return 1; sleep 20
}
tv "am start -W -n $YSC_ACT | grep -E 'Status|Error'"; sleep 6
uitap --id confirmBtn --wait 10 && sleep 4          # 免责声明: button is enabled after a 4 s countdown
uitap --id confirmBtn --find >/dev/null 2>&1 && { sleep 3; uitap --id confirmBtn; sleep 4; }
add_line "$LINE1_NAME" "$LINE1_URL" || echo "line 1 dialog failed; check screenshot"
if ! uitap --contains "豆瓣┃推荐" --find >/dev/null 2>&1; then echo "line 1 not loaded yet; waiting"; sleep 15; fi
add_line "$LINE2_NAME" "$LINE2_URL" || echo "line 2 dialog failed"
tvq 'input keyevent KEYCODE_BACK'; sleep 1
curl -s -m 15 -X POST "http://$TV_HOST:9978/action" --data-urlencode "do=livePush" --data-urlencode "live_name=$LIVE_NAME" --data-urlencode "live_address=$LIVE_URL" -w ' livePush http=%{http_code}\n'
sleep 3; tvq 'input keyevent KEYCODE_HOME'
# The launcher stores library/home choices; a fresh install has none, so the theme's dock/hidden_apps apply as-is.
( cd "$TOOLKIT" && TV_HOST="$TV_HOST" TV_PORT="$TV_PORT" tools/theme.sh "$ASSETS/theme2" | tail -1 )
sleep 5; tvq 'input keyevent KEYCODE_HOME'; shot /tmp/ubox-04-home.png
echo "expect dock: 影视仓 / SmartTube / Netflix / 设置 and nothing else on Home"
