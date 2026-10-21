#!/bin/bash
# Step 5: time zone, boot animation fallback, 4K HDMI output (only if the TV's EDID lists 4K60).
source "$(dirname "$0")/lib.sh"; ensure_toolkit
TZ_ID="${TZ_ID:-America/Vancouver}"
tv "setprop persist.sys.timezone $TZ_ID; settings put global auto_time_zone 0; echo tz=\$(getprop persist.sys.timezone)"
# Unblock boot video -> AOSP 'android' animation (the earlier u-boot splash lives in the bootloader partition; cannot be changed)
tv 'setprop persist.sys.bootanim.video_file /system/media/no-video; echo bootanim=$(getprop persist.sys.bootanim.video_file)'
# 4K: check the sink first
tvq --pull /sys/class/hdmi/hdmi/attr/edid /tmp/ubox-edid.bin >/dev/null 2>&1
if python3 -I - <<'PY'
d=open('/tmp/ubox-edid.bin','rb').read(); vics=[]
for b in range(1,len(d)//128):
    blk=d[b*128:(b+1)*128]
    if blk[0]!=2: continue
    i=4
    while i<blk[2]:
        tag=blk[i]>>5; ln=blk[i]&0x1f
        if tag==2: vics+=[v&0x7f for v in blk[i+1:i+1+ln]]
        i+=1+ln
print('EDID 4K60:', 97 in vics); raise SystemExit(0 if 97 in vics else 1)
PY
then
  tvq 'am start -a android.settings.DISPLAY_SETTINGS' >/dev/null; sleep 3
  uitap --text 高级显示设置 --wait 5 && sleep 2 && uitap --text HDMI输出模式 --wait 5 && sleep 2 && \
  uitap --text "4K 60Hz (3840x2160)" --scroll 4 --wait 3 && sleep 4
  tv 'echo "hdmi cfg=$(getprop persist.disp.device_config.hdmi)  (4,34,... = 2160p60; 4,10,... = 1080p60)"'
  tvq 'input keyevent KEYCODE_HOME'
else
  echo "TV EDID has no 4K60 (VIC 97); leaving 1080p"
fi
