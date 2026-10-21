#!/bin/bash
# Step 0: connect and verify this is the same UBOX 12 firmware. Read-only.
source "$(dirname "$0")/lib.sh"; ensure_toolkit
echo "== port $TV_HOST:$TV_PORT =="
if ! nc -z -G 3 "$TV_HOST" "$TV_PORT" 2>/dev/null; then
  if ping -c1 -W1 "$TV_HOST" >/dev/null 2>&1; then echo "box answers ping but port $TV_HOST:$TV_PORT is closed: ADB/网络调试 is off on the box (settings -> developer options), or this is not the UBOX (its adbd is on 7896, not 5555)."
  else echo "box unreachable: wrong IP, box in standby (HDMI-CEC off turns Wi-Fi off), or Mac on VPN. Find it with: dns-sd -B _adb._tcp local (name adb-<serial>, host Android-*.local)"; fi
  exit 3
fi
INFO=$(tvq 'echo "fp=$(getprop ro.build.fingerprint)"; echo "brand2=$(getprop ro.product.brand2)"; echo "hw=$(getprop ro.hardware)"; echo "abi=$(getprop ro.product.cpu.abilist)"; echo "secure=$(getprop ro.adb.secure)"; echo "serial=$(getprop ro.serialno)"; echo "home=$(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1)"; echo "disabled=$(pm list packages -d | tr "\n" " ")"; echo "third=$(pm list packages -3 | tr "\n" " ")"')
echo "$INFO"
case "$INFO" in
  *"brand2=Unblocktech"*hw=sun50iw9p1*abi=armeabi-v7a*) echo "MATCH: UBOX 12 (Allwinner H618, 32-bit) - safe to continue";;
  *) echo "WARNING: not the same firmware profile. Compare with REFERENCE-first-run-report.md before running the other steps."; exit 2;;
esac
echo "$INFO" | grep -q 'fp=google/blueline/blueline:12/SP1A.210812.015' || echo "NOTE: fingerprint differs from the first box (SP1A.210812.015); UI tap targets may differ, watch the screenshots."
