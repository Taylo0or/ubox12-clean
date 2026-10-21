# ubox12-clean

Claude Code skill：把安博 UBOX 12（Unblock Tech，Allwinner H618，Android 12）清成纯净 Android TV 盒子，一次跑完：

cleanyourtv 启动器 → 禁用全部安博包 → 本机 DNS 封锁安博域名 → 影视仓（点播/直播已配）+ SmartTube + Netflix → 时区 / 开机动画 / 4K 输出 → 重启验证。

不 root、不刷机、不卸载，只用 `pm disable-user`，有回滚记录。全部 APK 和配置都在 `assets/`，不需要联网下载。

## 安装这个 skill

```bash
git clone https://github.com/Taylo0or/ubox12-clean ~/.claude/skills/ubox12-clean
```

然后在 Claude Code 里说：**用 ubox12-clean 处理 192.168.1.X**（盒子 IP）。Claude 会按 `SKILL.md` 跑 `scripts/00..06`。

也可以不经 Claude 直接跑：

```bash
export TV_HOST=192.168.1.X
cd ~/.claude/skills/ubox12-clean && scripts/run-all.sh
```

## 前提

- macOS（Apple Silicon 也行），Python 3，`nc`；第一次跑脚本会自动 clone [cleanyourtv](https://github.com/Gathin23/cleanyourtv) 到 `~/src/ubox/cleanyourtv` 并建 venv（只用它的 `tools/tv.py` 做 ADB）。
- 盒子和 Mac 同一局域网，盒子开发者选项里「网络调试」开着（这台固件 adbd 在 **7896** 端口）。
- 盒子固件指纹要和 `00-check.sh` 里的一致（Unblocktech / sun50iw9p1 / armeabi-v7a），不一致脚本会停。

## 内容

- `SKILL.md` — 固件事实、步骤表、常见偏差处理
- `scripts/` — `lib.sh`（tv / nc_install / uitap）、`uitap.py`（uiautomator 定位点击）、`00-check` … `06-verify`、`run-all.sh`
- `assets/` — `debloat.txt`、`block-domains.txt`、`classification.md`、`theme2/`、`launcher/tvhome-2.5.apk`、`pdnsf/`（personalDNSfilter 重打包 + 配置 + keystore）、`apks/`（影视仓 32 位 6.2.8、SmartTube 32.68、Netflix 10.0.6）、`md5sums.txt`
- `REFERENCE-first-run-report.md` — 第一次在真机上做的完整报告（硬件、DRM、每个坑）

## 说明

- 第三方 APK 均为原包：SmartTube 来自 GitHub releases，影视仓来自 youhunwl/TVAPP，Netflix 来自 Aptoide（apksigner 验证为 Netflix, Inc. 签名）；personalDNSfilter 是 GPL 项目的重打包（只改了 assets 配置，自签名）。
- 影视仓的接口是 TVAPP README 公开的第三方聚合源，稳定性与内容合法性由源方负责。
- Netflix 在这台盒子上只能 SD（Widevine L3，设备未认证）。
