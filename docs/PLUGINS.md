# 固件插件清单

本文档说明本项目固件包含的插件、内核模块与系统组件，以及各自的作用。

- 生成依据：`Config/*.txt`、`Scripts/Packages.sh`、`Scripts/Settings.sh`、`Scripts/Handles.sh`、`.github/workflows/WRT-CORE.yml`
- 配置变动后请同步更新本文档
- **权威清单**以 Release 说明中的「插件列表」为准（由 `WRT-CORE.yml` 从固件 manifest 自动提取）

## 一、插件是如何进固件的（三层机制）

| 层 | 位置 | 作用范围 |
|---|---|---|
| 1 | `Config/GENERAL.txt`（QCA 平台）/ `Config/GENERAL-PONWRT.txt`（PONWRT 平台） | 通用插件，由 `WRT_GENERAL_FILE` 指定，追加到对应非 TEST 配置之后（`WRT-CORE.yml` 的 Custom Settings 步骤） |
| 2 | `Config/平台.txt` | 各平台/机型专属（设备列表、WiFi 驱动、平台硬件支持） |
| 3 | `Scripts/Settings.sh` | 强制追加 `luci`、简体中文语言包、`luci-theme-aurora`、`luci-app-aurora-config` |

> **关键点**：`Scripts/Packages.sh` 中的 `UPDATE_PACKAGE` 只是把第三方仓库克隆到 `./package`，
> **不等于编译进固件**。OpenWrt 只编译被 `CONFIG_PACKAGE_xxx=y` 选中的包及其依赖。
> 因此大部分被克隆的插件（openclash、mosdns、qbittorrent、各主题等）默认**不在固件内**，
> 仅作为备选，可在手动编译时通过 `PACKAGE` 参数启用。

配置合并规则（`WRT-CORE.yml`）：

- 配置名包含 `test`（如 `TEST.txt`）→ 只用该文件，**不合并**通用配置
- 其余配置 → `Config/<配置名>.txt` + 通用配置合并；通用配置由 `WRT_GENERAL_FILE` 指定：
  - QCA 等配置（默认）→ `Config/GENERAL.txt`
  - `PONWRT-*` 配置（`PONWRT-ALL.yml` 显式指定，`WRT-TEST.yml` 按前缀自动派生）→ `Config/GENERAL-PONWRT.txt`

## 二、通用插件（QCA 平台固件均包含）

来源：`Config/GENERAL.txt`。PONWRT 平台的通用插件见 `Config/GENERAL-PONWRT.txt`，差异在本节末尾。

### 网络与代理

| 插件 | 作用 |
|---|---|
| `luci-app-homeproxy` | 基于 sing-box 的透明代理客户端，**唯一代理入口**（来自 VIKINGYFY/packages 修改版） |
| `luci-app-natmapt` | 内网穿透/端口映射，解决无公网 IP 下的全锥形 NAT（源码取自 zhoufla 的 muink 分支） |
| `natmapt-notify-script-telegram` | natmapt 端口更新后的 Telegram 电报提醒脚本，装到 `/etc/natmap/notify/Telegram`，在 LuCI「natmap → Notify Scripts」中选择使用 |
| `luci-app-ddns-go` | 动态域名解析，支持阿里、腾讯、Cloudflare 等服务商（sirpdboy 封装 ddns-go） |
| `luci-app-upnp` | UPnP IGD 自动端口映射，方便 BT 下载、游戏联机 |
| `luci-app-zerotier` | ZeroTier 虚拟局域网（异地组网） |
| `luci-proto-wireguard` | WireGuard 协议在 LuCI 网络配置中的支持（配合 `kmod-wireguard`） |

> Telegram 提醒用法：LuCI「网络 → natmap → Notify Scripts」中勾选 EnNotify、选择 `Telegram`，
> 在 Tokens 里填 `TOKEN=<机器人token>` 与 `CHAT_ID=<会话ID>` 两条，Text content 填自定义文本
> （可用 natmap 变量，如 `${addr}:${port}`），Private API Domain 留空即用官方 `api.telegram.org`。

### 存储与共享

| 插件 | 作用 |
|---|---|
| `luci-app-mini-diskmanager` | 磁盘管理：分区、格式化、挂载、共享配置（4IceG） |
| `luci-app-samba4` | SMB/CIFS 文件共享（配合内核 `kmod-fs-ksmbd`） |
| `luci-app-msd_lite` | 组播转单播代理，用于内网观看 IPTV |
| `automount` | USB 存储设备自动挂载 |

### 设备维护

| 插件 | 作用 |
|---|---|
| `luci-app-wolultra` | 网络唤醒增强版（来自 VIKINGYFY/packages） |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-uhttpd` | uhttpd Web 服务器参数配置界面 |

### 界面与语言

| 插件 | 作用 |
|---|---|
| `luci-theme-aurora` + `luci-app-aurora-config` | 默认主题及配置器（由 `Settings.sh` 按 `WRT_THEME: aurora` 强制启用） |
| `luci` + `LUCI_LANG_zh_Hans` | LuCI 本体与简体中文语言包 |

### 明确关闭的插件

| 插件 | 取值 | 说明 |
|---|---|---|
| `luci-app-vlmcsd` | `=n` | KMS 激活服务，不编译 |
| `luci-app-wol` | `=n` | 原版网络唤醒，已被 wolultra 取代 |
| `luci-app-attendedsysupgrade` | `=n` | 在线升级；`Settings.sh` 同时从 feeds 的 luci collections 中删除该项，避免被集合依赖重新引入 |

### PONWRT 平台差异（GENERAL-PONWRT.txt）

`Config/GENERAL-PONWRT.txt` 是 ponwrt 源码专用的通用配置，与 QCA 的 `GENERAL.txt` 分开维护：

| 项 | 内容 |
|---|---|
| 代理 | `luci-app-homeproxy`（同 QCA，sing-box 内核） |
| 插件 | `luci-app-natmapt` + Telegram 通知、`luci-app-ddns-go`、`luci-app-autoreboot`、`luci-app-mini-diskmanager`、`luci-app-msd_lite`、`luci-app-samba4`、`luci-app-uhttpd`、`luci-app-zerotier`、`luci-app-iptv`、`luci-app-cpufreq`、`luci-app-pon`（pon_userspace feed）、`luci-proto-wireguard` |
| 组件 | `autocore`、`automount`、`curl`、`wireguard-tools`、`stuntman-client`（natmapt STUN）、`kmod-nf-tproxy`/`kmod-nft-tproxy`（透明代理）、`kmod-nf-conntrack-bridge`（AN7583 已无 profile 默认提供） |
| 关闭 | `luci-app-vlmcsd`、`luci-app-wol`、`luci-app-attendedsysupgrade`（与 QCA 相同） |
| 参数 | `CONFIG_FEED_pon_drivers/pon_userspace=y`（pon feed 必须开启，与 QCA 的 `=n` 相反）、`CONFIG_TARGET_ROOTFS_INITRAMFS=y`、`CCACHE`/`DEVEL` |
| 相对 QCA 少 | `luci-app-upnp`、`luci-app-wolultra`、fullconenat-sonic 与各 kmod/组件清单（PONWRT 的内核组件由 ponwrt 源码 target 默认提供） |

## 三、平台专属差异

各平台机型配置相对其通用配置（QCA 为 `GENERAL.txt`，PONWRT 为 `GENERAL-PONWRT.txt`）的差异（已用 diff 核实）：

| 配置 | 差异内容 | 说明 |
|---|---|---|
| `PONWRT-AN7581` / `PONWRT-AN7583` | 仅 `CONFIG_TARGET_airoha(_an7581/_an7583)` + `TARGET_MULTI_PROFILE` + `TARGET_ALL_PROFILES` | 一次构建子平台全部机型；TF-A/U-Boot/NPU 固件由 profile 默认值自动选择 |
| `IPQ60XX-WIFI-NO` | 显式关闭 `kmod-ath`、`kmod-ath11k(-ahb/-pci)` 及 ath11k 固件 | 无 WiFi 编译；`Settings.sh` 会将 DTS 替换为 `ipq6018-nowifi.dtsi`，释放 Q6 内存 |
| `IPQ807X-WIFI-NO` | 同上（另有 `ath10k-firmware-qca9887`） | 同上，DTS 替换为 `ipq8074-nowifi.dtsi` |
| `IPQ60XX-WIFI-YES` / `IPQ807X-WIFI-YES` | 无额外包 | WiFi 驱动由平台默认配置提供 |
| `MEDIATEK-WIFI-YES` / `NO` | 增加 `kmod-cryptodev=y`、`kmod-tls=y` | 硬件加密加速接口、内核 TLS 卸载 |
| `MEDIATEK-WIFI-NO` | 另有 `luci-app-axonhub=y` | VIKINGYFY 自用插件 |
| `ROCKCHIP` | mt79 全系驱动与固件（7915/7916/7921/7922/7925）+ `wpad-openssl=y` + DRM GPU（`kmod-drm-rockchip`、`kmod-drm-panfrost`） | 均为 `-e`（PCIe）变体，供 M.2 无线网卡使用；完整版 wpad（支持 WPA3、802.11r 漫游）；GPU 显示支持 |
| `X86` | 同 ROCKCHIP 的 mt79 全系 + `wpad-openssl=y`，另有 `kmod-hwmon-w83627ehf/hf`、`kmod-w83627hf-wdt` | 主板硬件监控（温度/风扇）与看门狗 |
| `TEST.txt` | 独立自检配置，含 `gecoosac`、`partexp` | 不合并 GENERAL.txt，不产出发布固件 |

> 注意：mt79 系列驱动属于 ROCKCHIP/X86 平台配置（为其外接无线网卡服务），
> MEDIATEK 平台的 WiFi 驱动由源码 target 默认配置提供，不体现在配置文件中。

## 四、内核模块与系统组件（GENERAL.txt 的「内核/组件调整」段）

这些不是 LuCI 插件，但同样占固件体积，按功能归类：

| 类别 | 包 | 用途 |
|---|---|---|
| 网络加速/防火墙 | `fullconenat-sonic`、`kmod-nft-arp/bridge/connlimit/core/dup-inet/fib/nat/netdev/offload/queue/socket/tproxy/xfrm`、`kmod-nf-nat(-nat6)` | 全锥形 NAT（P2P/游戏联机）、nftables 完整功能集（防火墙4、透明代理、硬件卸载、限速） |
| VPN/隧道 | `kmod-wireguard`、`kmod-tun`、`kmod-ovpn-backports` | WireGuard、TUN/TAP（代理与 VPN 必需）、OpenVPN 数据通道加速 |
| 网络诊断 | `kmod-inet-diag`、`kmod-inet-mptcp-diag`、`kmod-netlink-diag` | 套接字诊断，部分代理工具与 MPTCP 依赖 |
| 虚拟接口 | `kmod-dummy`、`kmod-veth`、`kmod-dsa`、`kmod-bonding` + `proto-bonding` | 容器/插件虚拟网卡、交换机架构、链路聚合 |
| USB 网络 | `kmod-usb-net` 及 `rndis`、`cdc-ncm`、`cdc-mbim`、`cdc-ether`、`cdc-eem`、`cdc-subset`、`huawei-cdc-ncm`、`ipheth`、`asix(-ax88179)`、`rtl8150`、`rtl8152`、`sierrawireless` | 手机 USB 共享网络、4G/5G 模块、各类 USB 有线网卡 |
| 手机相关 | `libimobiledevice`、`usbmuxd`、`usb-modeswitch`、`usbutils` | iPhone USB 共享网络、4G 上网卡模式切换、USB 设备查看 |
| 存储支持 | `kmod-usb-storage(-extras/-uas)`、`kmod-usb3`、`kmod-usb-core`、`kmod-usb-dwc3/ehci/ohci/uhci`、`kmod-nvme` + `libnvme` + `nvme-cli`、`kmod-fs-btrfs`、`kmod-fuse`、`kmod-fs-ksmbd`、`kmod-ata-ahci` + `kmod-ata-core` | U 盘/移动硬盘、NVMe SSD、btrfs、FUSE（ntfs-3g 等依赖）、内核态 SMB 服务、SATA 控制器 |
| 分区与格式化 | `fdisk`、`sfdisk`、`cfdisk`、`cgdisk`、`gdisk`、`sgdisk`、`blkid`、`lsblk`、`exfat-fsck`、`exfat-mkfs`、`xz-utils` | 分区工具、exFAT 支持、压缩解压 |
| 硬件管理 | `autocore`、`cpufreq`、`smartmontools` + `smartmontools-drivedb`、`mmc-utils`、`nand-utils` | 状态监控、CPU 调频、硬盘 S.M.A.R.T. 健康检测、eMMC/NAND 操作 |
| 音频 | `kmod-sound-core`、`kmod-usb-audio` | 声卡与 USB 音频支持 |
| 系统/调试 | `kmod-mtd-rw`、`kmod-cryptodev`*、`iperf3`、`htop`、`curl`、`dmesg`、`coremark`、`ip-full`、`openssh-keygen`、`openssh-sftp-server`、`openssl-util`、`stuntman-client` | MTD 分区可写（刷写）、带宽测试、进程监控、网络诊断、CPU 跑分、完整版 iproute2、SSH 密钥与 SFTP、OpenSSL 命令行、STUN 客户端（natmapt 依赖） |

\* `kmod-cryptodev` 仅 MEDIATEK 平台配置启用。

## 五、已克隆但默认不编译的插件

以下由 `Scripts/Packages.sh` 克隆到构建树，但没有任何配置选中它们，
**不会出现在固件里**，仅供手动编译时按需启用：

| 分类 | 插件 |
|---|---|
| 主题 | argon、fluent、footstrap、kucat、kucat-config、shadcn |
| 代理 | momo、nikki、openclash |
| 存储/下载 | diskman（sbwml 版）、openlist2、qbittorrent、quickfile、mosdns |
| sirpdboy 系列 | netspeedtest、netwizard、timecontrol（partexp 仅 TEST 配置用） |
| LianXia233 系列 | airpi3000m-fancontrol、chfs、fm350、h5000m-netmode、mt5700、mt5700m、netmonitor、qmodem-generic |
| 其他 | easytier、vnt、qmodem、`luci-app-tailscale`（本地自定义条目） |

其中 `viking` 条目（`VIKINGYFY/packages`）特殊：克隆前会先从 feeds 删除
`axonhub gecoosac sing-box luci-app-homeproxy luci-app-timewol luci-app-wolplus luci-app-wolultra`
对应的原版目录，再整体克隆——因此固件里的 `homeproxy` 与 `wolultra` 实际来自
VIKINGYFY 的修改版仓库，而非官方 feeds。

## 六、如何临时增减插件

手动触发工作流（`workflow_dispatch`）时，在 **PACKAGE** 输入框填写
（多个用 `\n` 分隔，`Settings.sh` 会追加进 `.config`）：

```
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-tailscale=y
```

或新建 `Config/PRIVATE.txt`（`Settings.sh` 自动合并，当前不存在），
用于本地长期私有配置，不必写入平台通用配置（QCA 为 `GENERAL.txt`，PONWRT 为 `GENERAL-PONWRT.txt`）。

## 七、当前会运行的编译任务

`Auto-Clean` 每天 UTC 21:21（北京时间 5:21）运行，清理旧 Release 后，
通过 `workflow_run` 依次触发以下工作流：

| 工作流 | 平台配置 | 源码 |
|---|---|---|
| QCA-ALL | IPQ60XX-WIFI-YES、IPQ60XX-WIFI-NO、IPQ807X-WIFI-YES、IPQ807X-WIFI-NO | `VIKINGYFY/immortalwrt` 分支 `owrt` |
| PONWRT-ALL | PONWRT-AN7581、PONWRT-AN7583 | `zhoufla/ponwrt` 分支 `master` |

AIROHA 平台固件统一由 PONWRT-ALL 编译发布，Release 页展示的「源码/分支/提交」
取自实际 clone 的仓库与提交，即真实使用的源码（`zhoufla/ponwrt`）。

其余平台（IPQ53XX、IPQ95XX、MediaTek、Rockchip、X86）已停止每日编译，
`Config/*.txt` 保留，可通过 `WRT-TEST` 手动校验配置。

所有平台共用默认参数：

| 参数 | 值 |
|---|---|
| 登录地址 | `192.168.10.1`（PONWRT-ALL 为 `192.168.40.1`） |
| 主机名 / WiFi 名 | `OWRT`（PONWRT-ALL 为 `ponwrt` / `PONWRT`） |
| WiFi 密码 | `12345678` |
| 主题 | aurora |
| 编译产物 | QCA 平台每设备独立 rootfs（`TARGET_PER_DEVICE_ROOTFS`）且不生成 initramfs（`GENERAL.txt`）；PONWRT 平台按源码默认（生成 initramfs，未启用每设备独立 rootfs） |
