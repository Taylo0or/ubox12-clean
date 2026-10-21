# UBOX 12 包分类（探测于 2026-10-21，盒子 192.168.1.X:7896，124 个包，/data/app 为空）

整机所有系统包（含 AOSP 的 com.android.*）都用同一把泄露的阿里 YunOS 测试平台密钥签名
（CN=tangrong, O=Alibaba, SHA256 5fdede2d…），所以"签名"不能用来区分安博/全志，判断依据改为：
包名、label、类名前缀 com.moons.*、版本号、APK 内的域名/URL、运行中的进程与服务。

## A. 安博全家桶（建议禁用，共 6 个，按此顺序禁）
| 包名 | APK | label / 证据 | 备注 |
|---|---|---|---|
| com.moons.detection | /system/app/Factory_detection | 「工厂测试」，开机自启常驻，APK 内 http://stats.10moons.com ×9 | 统计上报 |
| com.example.Upgrade | /system/app/H618_UpgradeV3 | 「升级」，服务类名 com.moons.Update.UpdateService 常驻；URL ogw.syslib5978.com/ubdown/update/google/（= ro.sw.upgrade_url）、china-ota.com、42.121.236.55；有 REQUEST_INSTALL_PACKAGES | 安博 OTA |
| com.yanggis.chinatunnelCOM | /system/app/UBTunnel.6 | 「UBTunnel」6.3.0，常驻；并通过固件自带的 su 起了一个 **root 进程** chinatunnel_armeabi-v7a（PPID=1，二进制在该 app 的 files/ 目录）；域名 sfo.yanggis.com；盒子对外监听 0.0.0.0:8443 / 8123 疑为它的代理口 | 禁包后现有 root 进程要到重启才消失（shell 杀不了 root 进程） |
| com.moons.browser | /system/app/browser-v1.1 | 「浏览器」，持有 INSTALL_PACKAGES（安博装应用的通道），URL app.wukongiot.net | |
| com.moons.settingwizard | /system/app/settingwizard | 「设置向导」版本 5.0.8H618_UBOX，开机自启常驻，入口是 BluetoothRemoteActivity（首次开机的遥控配对向导）；persist.sys.SettingWizard=complete 已完成 | 之后配遥控走 设置→遥控器与配件 |
| com.moons.mylauncher12 | /system/app/I19_I20 | 「安博啟動器」，当前 HOME，360 加固（com.stub.StubApp），有 REQUEST_INSTALL_PACKAGES；域名 zipupsysdwlink.com、csupdata.com、c.appjiagu.com | **最后禁**，必须等 com.gathin.tvhome 成为 HOME |

非包、无法用 pm 处理但要知道的：
- /system/xbin/su（rwsrwsrwx，root setuid）+ /system/bin/qw（init 起的 su daemon）：固件自带 root 后门，任何 app 都能提权。这就是 UBTunnel 拿 root 的方式。按你的规则我不会用它。
- /system/bin/appsdisable、/system/bin/gmsopt：出厂脚本，首次开机把所有 com.google.android.* 的 BOOT_COMPLETED 接收器 pm disable 掉（已执行，start_disable=1）。所以 Play 商店的 BootCompletedReceiver、GMS 的一批组件现在是禁用状态。不动，但你要知道。

## B. 必须保留（厂商/全志/AOSP 底层）
- android、所有 com.android.*（含 com.android.bluetooth、com.android.tv.settings = 响应 android.settings.SETTINGS 的唯一包、com.android.inputmethod.latin 键盘、com.android.systemui、各 provider/apex/overlay、CTS shim）
- 全志：com.softwinner.*（TvdVideo/fireplayer/TvdFileManager/ImageParser/timerswitch/awlogsettings/awmanager/provision/screenshot/settingssetup/miracastReceiver/theme.*/update）、com.allwinnertech.packageoverride
- com.google.android.apps.inputmethod.zhuyin（谷歌注音输入法，Google 的旧证书 CN=Unknown/O=Google, Inc；不是安博，保留）
- com.android.chrome（Google 证书 F0:FD:6C:5B…，与 Play 商店同一把；v2/v3 签名块被固件打包时剥掉，v1 仍是 Google 的）

## C. Google 框架 —— 全部是正牌，保留
| 包 | 版本 | 证书 |
|---|---|---|
| com.google.android.gms | 21.48.57 | O=Google Inc., SHA256 7ce83c1b71f3d572fed04c8d40c5cb10ff75e6d87d9df6fbd53f0468c2905053 |
| com.google.android.gsf | 11 | 同上 |
| com.android.vending | 29.2.15 | O=Google Inc., SHA256 F0:FD:6C:5B:41:0F:25:CB:25:C3:B5:33:46:C8:97:2F:AE:30:F8:EE:74:11:DF:91:04:80:AD:6B:2D:60:DB:83（Play 商店标准证书） |
| com.android.chrome | 76.0.3809.111 | 同 vending |

## D. 不确定，你拍板
| 包名 | 是什么 | 为什么不确定 | 我的建议 |
|---|---|---|---|
| com.example.android.autopair | BLEAutoPair，蓝牙遥控自动配对服务，常驻 | 类名含 moons.auto*，是安博改的；但它是遥控配对功能本身。已配对的遥控不受影响；新配对可走 设置→遥控器与配件 | 先保留；全部弄完后最后单独试禁，遥控不对劲就 restore |
| com.mitac.android.i2ctool | 「呼吸灯控制」，前面板 LED 的 PWM 服务，常驻 | 含 moons.factory 字串，安博做的硬件小工具；禁了只影响呼吸灯 | 随你；我倾向禁（少一个常驻） |
| com.nanosic.nanootable | NanoOtaBle，Nanosic（遥控器厂）的遥控固件 OTA 工具，常驻，连 47.98.206.54 | 不是安博写的，但它是个 OTA 更新器 | 禁 |
| com.hpplay.happyplay.aw | 乐播投屏 HappyCast 8.13.32，乐播签名，开机自启，上报 yuntiancloud.com / snssdk.com | 第三方投屏 SDK，安博捆绑；你若不用手机投屏就没用 | 禁（Miracast 由 com.softwinner.miracastReceiver 提供，保留） |
| com.chaozhuo.filemanager | 超卓文管 CZ File Manager（Phoenix OS 的） | 第三方捆绑，不常驻，无害 | 随你；全志自带 TvdFileManager 可替代 |
| com.softwinner.update | 全志「本地升级」2.1.0，连 api.bigbigcloud.cn（全志 OTA 云） | 规则说 softwinner 不碰；但它是 OTA 入口之一（U 盘/云） | 按规则保留；域名加进封锁清单即可 |
| com.softwinner.dragonbox / dragonatt / agingdragonbox | 全志工厂老化测试工具，dragonatt/dragonbox 开机常驻 | 全志的，不是安博 | 按规则保留 |
