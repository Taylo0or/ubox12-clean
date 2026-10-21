---
name: ubox12-clean
description: 把安博 UBOX 12（Unblock Tech，全志 H618，Android 12）清成纯净 Android TV 盒子：装 cleanyourtv 启动器、禁用全部安博包、本机 DNS 封锁安博域名、装影视仓(点播/直播已配)+SmartTube+Netflix、时区/开机动画/4K 输出，并重启验证。全部素材和脚本都在本目录，按顺序跑脚本即可，不需要重新探测或下载。
---

# UBOX 12 一键清理（复刻 2026-10-21 在 luke 家那台上的结果）

## 什么时候用
用户说要清理 / 刷纯净 的安博 UBOX 12（或同固件盒子）。先问清楚盒子 IP，其它不用问。
目标效果 = `REFERENCE-first-run-report.md`。如果用户要求不同（比如不要 Netflix、换直播源），只改对应一步里的变量。

## 固件事实（别再探测，直接用）
- ADB 在 **7896 端口**，不是 5555；`ro.adb.secure=0` 无需授权；ADB 要保持开启，**绝不执行 `settings put global adb_enabled 0`**。
- 所有 adb 操作必须用 `~/src/ubox/cleanyourtv/tools/venv/bin/python tools/tv.py`（lib.sh 的 `tv` 函数）。Homebrew python3 和原生 adb 都被 macOS 本地网络权限挡（No route to host）。
- `adb push`/sync 在这台 adbd 上超时，**传 APK 一律 `nc_install`**（盒子 `nc -l` + Mac `nc`，44MB 几秒）。
- ABI 只有 armeabi-v7a → 全部装 32 位 APK（已打包在 assets/apks）。
- 整机所有包用同一把泄露的阿里 YunOS 测试密钥签名，签名分不出安博/全志；分类见 assets/classification.md，禁用清单 assets/debloat.txt（10 个包，A 组安博 6 个 + 用户选的 4 个）。
- 固件**不给第三方 app 投递 BOOT_COMPLETED**：任何靠开机广播自启的东西都起不来；DNS 过滤靠 `always_on_vpn_app` 这个 secure 设置让系统拉起。
- 固件自带 root 后门（/system/xbin/su + qw daemon）、SELinux permissive。按规则不用 root。
- 安博的 u-boot bootlogo 在 bootloader 分区，换不了；只能把 Android 层的 mp4 片头换成 AOSP 动画（05 步）。
- 启动器 UI 帧缓冲永远 1080p，4K 只是 HDMI 输出；截图都是 1080p，属正常。
- 影视仓 6.2.8 的 HTTP 推送接口 `pushStore`/`api` 返回 ok 但不生效，点播线路只能走它的「配置」弹窗（脚本用 uiautomator 找控件再 `input tap/text`，坐标会随软键盘变）；`livePush` 接口有效。
- 影视仓包名 `com.huawei.himovceie` 是作者伪装的，不是华为。YouTube 用 SmartTube 替代（官方新版只有 arm64 且盒子无 Google 账号）。Netflix 只能 SD：Widevine 只有 L3（没烧 keybox），设备未认证。

## 跑法
```bash
export TV_HOST=192.168.1.X          # 盒子 IP（用 mDNS/ARP 确认是 UBOX，别拿错设备：同网段的 Chromecast 也开 5555）
cd ~/.claude/skills/ubox12-clean
scripts/run-all.sh                   # 或者按顺序单跑 scripts/00..06
```
每一步脚本末尾都打印了「expect」或检查项；对照不符就停下看 `/tmp/ubox-0X-*.png` 截图（用 Read 看图）。

| 步骤 | 做什么 | 不可逆？ |
|---|---|---|
| 00-check.sh | 连接 + 核对固件指纹（brand2=Unblocktech, sun50iw9p1, armeabi-v7a）。不匹配就退出 | 否 |
| 01-launcher.sh | 装 assets/launcher/tvhome-2.5.apk → 设为 HOME → 禁安博启动器 → 推 theme2 → Clock 屏保 | pm disable-user，可回滚 |
| 02-debloat.sh | `tools/disable.sh assets/debloat.txt`（先写恢复记录到 ~/.cleanyourtv/） | 可回滚 |
| 03-dnsfilter.sh | 装 pdnsf-ubox.apk（26 域名已内置、公共广告列表全关）→ 点 VPN 授权 → always-on | 可卸载 |
| 04-apps.sh | 装影视仓/SmartTube/Netflix → 影视仓加「游魂嗷呜」(含欧乐/壹帆)+「游魂多仓」两条线路 + 游魂直播源 → 重推主题 | 可卸载 |
| 05-system.sh | 时区 America/Vancouver（TZ_ID 可改）、开机动画回落 AOSP、按 EDID 切 4K60 | setprop，可改回 |
| 06-verify.sh | 重启 → 核对 HOME/无安博包/无安博进程/tun0/封锁生效/时区/HDMI/ADB 仍开 | 否 |

## 做完要给用户的
1. 06 的输出（逐项都对）+ 最终 Home 截图。
2. `assets/block-domains.txt` 让他加到路由器（盒子上已有本机封锁，路由器是双保险）。
3. 回滚命令：`cd ~/src/ubox/cleanyourtv && TV_HOST=<ip> TV_PORT=7896 tools/restore.sh ~/.claude/skills/ubox12-clean/assets/debloat.txt com.moons.mylauncher12`；主题回退 `tools/theme.sh --reset`。
4. 提醒：SmartTube/Netflix 要在电视上登录；Netflix 最多 SD；开机最早一闪的安博图去不掉。

## 常见偏差怎么处理
- 00 报指纹不符：别硬跑。对照 REFERENCE 报告重新做一次分类（只改 debloat.txt），其余步骤通常照用。
- uitap 找不到控件：`scripts/uitap.py --dump` 看当前界面，改 `--text/--id` 再点；影视仓弹窗里软键盘弹出后控件 y 坐标会从 ~828 变成 ~478，脚本每次都重新 dump 所以不受影响。
- 03 之后 tun0 没起：手动 `am start -n dnsfilter.android/.DNSProxyActivity` 看屏幕，VPN 授权框点「确定」再跑一次 03。
- 06 后 Home 不是 com.gathin.tvhome：`cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity`。
- 主屏多出不想要的 tile（Chrome/Play/personalDNSfilter）：`pm clear com.gathin.tvhome` 后重推主题（启动器私有数据里的"应用库加到主屏"记录会压过 hidden_apps）。
- 改封锁清单：改盒子上 `/sdcard/Android/data/dnsfilter.android/files/PersonalDNSFilter/additionalHosts.txt`，app 里「重新加载过滤器」。
- 影视仓线路失效：换 `04-apps.sh` 顶部的 LINE*/LIVE 变量，候选接口见 https://github.com/youhunwl/TVAPP README。

## 目录
- `scripts/lib.sh` 共用函数（tv / nc_install / uitap / wait_for_box）· `scripts/uitap.py` UI 定位点击 · `scripts/0X-*.sh` 步骤 · `scripts/run-all.sh`
- `assets/` debloat.txt · block-domains.txt · classification.md · theme2/ · launcher/tvhome-2.5.apk · pdnsf/（重打包 APK + 配置 + 签名 keystore，密码 ubox-pdnsf）· apks/（影视仓 32 位 6.2.8 / SmartTube 32.68 armeabi-v7a / Netflix 10.0.6）· md5sums.txt
- `REFERENCE-first-run-report.md` 第一次做的完整报告（硬件、DRM、每个坑的来龙去脉）
