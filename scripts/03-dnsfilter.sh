#!/bin/bash
# Step 3: personalDNSfilter with the baked-in block list; autostart through Android always-on VPN
# (this firmware never delivers BOOT_COMPLETED to third-party apps, so the app's own AUTOSTART is useless).
source "$(dirname "$0")/lib.sh"; ensure_toolkit
nc_install "$ASSETS/pdnsf/pdnsf-ubox.apk" pdnsf.apk || exit 1
tv 'am start -W -n dnsfilter.android/.DNSProxyActivity | grep -E "Status|Error"'
sleep 5
# VPN consent dialog (com.android.vpndialogs): press 确定 if it is on screen
uitap --text 确定 --pkg com.android.vpndialogs --wait 6 || echo "(no VPN consent dialog seen)"
sleep 6
tv 'settings put secure always_on_vpn_app dnsfilter.android; settings put secure always_on_vpn_lockdown 0; input keyevent KEYCODE_HOME'
echo "== check =="; tv 'ip addr show tun0 2>&1 | grep -E "inet |does not"; for h in stats.10moons.com ogw.syslib5978.com www.google.com; do printf "%-24s" $h; ping -c1 -W2 $h 2>&1 | head -1 | grep -oE "\([0-9a-f.:]+\)|unknown host"; done'
echo "expect: tun0 present, first two -> (127.0.0.1), google -> real IP"
