# UBOX 12 清理报告（2026-10-21）

盒子：安博 UBOX 12，Allwinner H618（sun50iw9p1），Android 12，build 伪装成 Google Pixel 3 / blueline。
连接：**192.168.1.X，ADB 端口 7896**（安博改的，不是 5555），`ro.adb.secure=0` 无需授权。
所有脚本要带 `TV_HOST=192.168.1.X TV_PORT=7896`。

## 结果
- Home = `com.gathin.tvhome`（cleanyourtv 启动器，release 包 415 KB，本机 JDK 21 + build-tools 34.0.0 编译）。
- 重启后验证：`pm list packages -e | grep -iE 'ubox|unblock|moons|yanggis'` 为空；`ps -A` 无安博进程；
  UBTunnel 的 root 进程 `chinatunnel_armeabi-v7a` 和它对外开的 0.0.0.0:8443 / 8123 监听口都消失；
  WiFi 已连（<家里 Wi-Fi>，RSSI -31）、蓝牙 ON、HDMI-CEC 启用、音频输出正常、屏保 = `com.gathin.tvhome/.ClockDream`。
- dock（10-21 最终）：影视仓、YouTube(SmartTube)、Netflix、设置；Chrome / Play 商店 / personalDNSfilter 不上主屏，只在「应用库」里（hidden_apps）。主题 = `theme2/`（aurora 壁纸 + 暗化 20% + advanced_effects），改完 `tools/theme.sh ~/src/ubox/theme2`。注意：启动器把「应用库」里手动加到主屏的 app 记在自己的私有数据里，hidden_apps 压不过它；要清掉得 `pm clear com.gathin.tvhome` 再推一次主题（10-21 已这么做过一次）。

## 禁了哪些（debloat.txt，共 10 个，全部 `pm disable-user --user 0`）
| 包 | 是什么 |
|---|---|
| com.moons.detection | 安博「工厂测试」，stats.10moons.com 统计上报 |
| com.example.Upgrade | 安博 OTA（com.moons.Update.UpdateService，ogw.syslib5978.com） |
| com.yanggis.chinatunnelCOM | UBTunnel，带 root 子进程 |
| com.moons.browser | 安博浏览器（INSTALL_PACKAGES） |
| com.moons.settingwizard | 安博设置向导 5.0.8H618_UBOX |
| com.moons.mylauncher12 | 安博启动器（由 build-and-install.sh 在新启动器成为 HOME 后禁用） |
| com.mitac.android.i2ctool | 呼吸灯控制（安博） |
| com.nanosic.nanootable | 遥控器固件 OTA（Nanosic） |
| com.hpplay.happyplay.aw | 乐播投屏 |
| com.chaozhuo.filemanager | 超卓文管 |

## 保留了哪些及原因
- 全部 `android` / `com.android.*`：AOSP 系统组件；`com.android.tv.settings` 是唯一响应设置 intent 的包。
- 全部 `com.softwinner.*` / `com.allwinnertech.*`：全志 SDK 自带（含 `com.softwinner.update` 本地升级、dragonbox/dragonatt 工厂测试），按规则不动。
- `com.example.android.autopair`：蓝牙遥控自动配对，安博改过但就是配对功能本身，按你的决定保留。
- Google 框架：gms / gsf 证书 Google Inc. 7ce83c1b…；Play 商店 / Chrome 证书 Google 的 F0:FD:6C:5B…。全部正牌。
- `com.google.android.apps.inputmethod.zhuyin`：谷歌注音输入法，Google 旧证书，不是安博。
- `com.android.inputmethod.latin`、bluetooth、CEC、音频、WiFi、DRM 等底层：未触碰。

## 无法用 pm 处理、需要你知道的
- 固件自带 root 后门：`/system/xbin/su`（setuid root，全局可执行）+ `/system/bin/qw`（init 起的 su daemon，常驻）。任何 app 都能提权。不刷机去不掉。
- 出厂脚本 `/system/bin/appsdisable`、`gmsopt` 首次开机把所有 Google 包的 BOOT_COMPLETED 接收器 disable 了（Play 商店 BootCompletedReceiver 等）。未动。想恢复 Play 自动更新可以 `pm enable` 那些组件。
- `service.adb.tcp.port=7896` 是固件设的，每次开机 adbd 都会在 7896 监听（只要 adb_enabled=1）。
- **ADB 保持开启**（用户 10-21 决定）。10-21 01:22 曾误执行 `settings put global adb_enabled 0` + reboot 把它关掉了；重新打开：电视上 设置 → 设备偏好设置 → 关于 → 「版本号」连按 7 次 → 开发者选项 → 打开「USB 调试」（有「网络调试」也一起打开），然后 `nc -vz 192.168.1.X 7896` 应为 succeeded。

## 回滚
```
cd ~/src/ubox/cleanyourtv
TV_HOST=192.168.1.X TV_PORT=7896 tools/restore.sh ~/src/ubox/debloat.txt com.moons.mylauncher12
```
恢复记录在 `~/.cleanyourtv/recovery-192.168.1.X-8a98f1cb.json`（禁包前的状态，唯一一份，别删）。
启动器主题回退：`tools/theme.sh --reset`；卸掉新启动器：`tools/tv.py 'pm uninstall com.gathin.tvhome'`（先 restore）。

## 封域名
见 `block-domains.txt`（26 个域名 + 2 个裸 IP）。裸 IP 要在路由器上封。

## 封域名（已装到盒子上）
装了 **personalDNSfilter 1.50.61.5**（开源 GPL，包名 `dnsfilter.android`，本地 DNS 过滤 VPN，不需要 root）。
APK 是官方 release 重打包：只改了 `assets/dnsfilter.conf`（关掉全部公共广告列表、关首启弹窗、关流量日志、AUTOSTART=true）
和 `assets/additionalHosts.txt`（= block-domains.txt 的 26 个域名，含子域），用自签名 key 重签。
文件：`pdnsf/pdnsf-ubox.apk`、`pdnsf/assets/`、`pdnsf/ubox-pdnsf.keystore`（密码 ubox-pdnsf）。
- 验证：盒子上 `ping stats.10moons.com` 解析到 127.0.0.1；google.com 等正常。
- **开机自启**：这台固件的开机广播（BOOT_COMPLETED）根本不投递给第三方 app（logcat 里没有它的 Start proc，appops/待机桶都正常，原因没查到），所以 pDNSf 自己的 AUTOSTART 无效。改用 Android 的 always-on VPN：`settings put secure always_on_vpn_app dnsfilter.android`（lockdown=0）。重启验证：系统在 onUserUnlocked 时 startAlwaysOnVpn 把它拉起，开机约 30 秒后 tun0 建立。别清这个设置；pDNSf 卸载前先 `settings put secure always_on_vpn_app ""`。
- 以后改清单不用重打包：改盒子上 `/sdcard/Android/data/dnsfilter.android/files/PersonalDNSFilter/additionalHosts.txt`（adb push），
  再在 app 里按「重新加载过滤器」或重启盒子。
- 想顺带封广告：打开 app →「高级设置」→ 勾选 1Hosts / Hagezi 等列表（我默认全关了）。
- 卸载：`pm uninstall dnsfilter.android`。注意：设置里「私人 DNS」要保持关闭，否则会绕过它。


## 后装的应用（2026-10-21，adb push 在这台 adbd 上不可用，全部用 `nc-install.sh` 经 netcat 传输后 pm install）
| 应用 | 包名 | 来源 / 签名 | 说明 |
|---|---|---|---|
| 影视仓 6.2.8（32 位） | com.huawei.himovceie | youhunwl/TVAPP 仓库，CN=TVBOX 自签 | 包名是作者故意仿华为视频以躲黑名单，不是华为的。盒子 ABI 只有 armeabi-v7a，所以装 32 位 |
| SmartTube 32.68 | org.smarttube.stable | GitHub yuliskov/SmartTube，O=SmartTube | 代替官方 YouTube：官方 YouTube TV 新版只有 arm64，Aptoide 上 32 位的只剩 2018 年的 3.01，而且盒子没登 Google 账号装不了 Play；SmartTube 开源、无广告、可登 Google 账号 |
| Netflix 10.0.6（Android TV 版） | com.netflix.ninja | Aptoide 社区仓，签名 O=Netflix, Inc.（已 apksigner 验证，未改包） | 盒子不是 Google 认证设备，Netflix 可能只给 SD 或直接提示不支持，要在电视上登录试 |
| personalDNSfilter | dnsfilter.android | 见上节 | |

### 影视仓配置
- 点播：通过「配置」弹窗加了两个线路（HTTP 推送接口 /action 返回 ok 但不生效，只能走弹窗 + adb input）：
  1. `AoWu-OuLe-AiYiFan` = https://www.iyouhun.com/tv/aowu（游魂┃嗷呜线路，76 个站点，含 `🌍欧乐┃墙外`(csp_OlyyAmns) 和 `🌍壹帆┃墙外`(csp_AiyfAmns)），当前生效。
  2. `YouHun-DuoCang-24` = https://www.iyouhun.com/tv/dc（游魂多仓，24 条线路；其中 高天流云/驸马 也有欧乐、爱壹帆）。
  在「线路」里切换。主页左上角站点名可切换站点。
- 直播：`游魂直播` = https://www.iyouhun.com/tv/zb（用 /action do=livePush 推送成功），已加载央视/卫视/港澳台/台湾/咪咕/体育等分组。
- 这些接口全是仓库 README 里公开分享的第三方聚合源，稳定性和内容合法性由源方负责，失效了换 README 里别的接口即可。
- 自定义多仓文件 `dl/tvapp/ubox-dc.json`（嗷呜/高天流云/驸马排前面）已推到 /sdcard/Android/data/com.huawei.himovceie/files/，但 file:// 方式没生效，留作备用。


## 时区 / 开机动画 / SELinux（10-21 晚）
- 时区：`cmd time_zone_detector` 对 shell 无权限，用 `setprop persist.sys.timezone America/Vancouver` + `settings put global auto_time_zone 0`，重启后生效（date 已显示 PDT）。
- 开机动画：这台的 `/system/bin/bootanimation` 是全志改的，按 `persist.sys.bootanim.video_file`（出厂 = /system/media/bootanimation.mp4，安博片头）播 mp4；该属性 shell 可写。已改成不存在的路径 `/system/media/no-video`，整机没有任何 bootanimation.zip，于是回落到 AOSP 内置的「android」发光字动画（不是 Google 认证 Android TV 那个带 Google 标的，那个没有包）。恢复：`setprop persist.sys.bootanim.video_file /system/media/bootanimation.mp4`。用户 10-21 实测：安博 mp4 片头没了，能看到 android 发光字。**开机最早一闪而过的安博图是 u-boot 的 bootlogo，存在 bootloader_a/b 分区（mmcblk0p1/p2）里，Android 文件系统里找不到对应文件；只有 root 后 dd 重写 bootloader 分区才能换，写坏会变砖，不建议动。**它还认 `/data/local/bootanim/bootanimation.mp4` / `/product/media/bootanimation.zip` 等路径，但 shell 写不进去。
- 这台固件 **SELinux 是 permissive**（logcat avc 行 permissive=1），加上 su 后门，安全性基本为零；只在局域网里用。


## 硬件与 DRM（10-21 实测）
- Allwinner H618：4×Cortex-A53 @1.5GHz，Mali-G31 MP2（GLES 3.2），4GB RAM，64GB eMMC（可用 49GB），内核 5.4.125，**32 位用户空间**。硬解 OMX.allwinner H.264/HEVC/VP9，无 AV1。
- HDMI 输出 10-21 已切到 **4K 60Hz (3840x2160)**：设置→显示和声音→高级显示设置→HDMI输出模式；对应 persist.disp.device_config.hdmi 从 `4,10,0,0,4,257`（1080p60）变成 `4,34,3,0,4,257`（mode 34 = 2160p60）。Android 的 UI 帧缓冲仍是 1920x1080（`wm size`/dumpsys display 都报 1080p，这是全志的做法：UI 1080p 由显示引擎放大到 4K 输出，视频层按片源原生分辨率走），所以截图还是 1080p。电视是 某 LG 电视，EDID 支持到 4K60 / HDMI 2.0 600MHz。改回去在同一个菜单选 1080p 60Hz。
- **Widevine 只有 L3**：shaka support 页实测 com.widevine.alpha 的 robustness 仅 SW_SECURE_CRYPTO，无 HW_SECURE_*；`ro.boot.drmkey=false` 说明没烧 keybox，虽然有 drm@1.4 widevine HAL + secure OS，等于没用。HDCP 未启用（hdcp_enable=0）。
- 结论：Netflix 最多 SD（480p），且设备未经 Netflix 认证，app 可能直接报不支持；4K/HD 不可能。YouTube(SmartTube) 不走 DRM，1080p/4K 看解码和输出设置即可。

## 文件
- `debloat.txt` 禁用清单 · `classification.md` 四组分类 · `block-domains.txt` 封锁清单
- `packages-all.txt` / `pkg-table.txt` / `pkg-meta.txt` 探测原始数据 · `apks/` 拉下来的 APK · `urls/` `domains/` 字符串提取
- `shots/` 截图：before.png（安博桌面）→ after.png（新启动器）→ after-reboot.png → final-home.png
- `01-probe.sh` 探测脚本 · `theme/config.json` 启动器 dock 配置
