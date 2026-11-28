# OpenWRT-CI

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 的自用云编译项目，每周一北京时间 5:21 自动编译并发布 Release，仅保留以下平台：

- **IPQ60XX / IPQ807X**（[QCA-ALL](.github/workflows/QCA-ALL.yml)）：[VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) `owrt` 分支
- **IPQ60XX / IPQ807X（NSS）**（[LIBWRT-ALL](.github/workflows/LIBWRT-ALL.yml)）：[LiBwrt/LibWrt](https://github.com/LiBwrt/LibWrt) `25.12-nss` 分支，高通 NSS 硬件加速（ECM + nss-drv）
- **AIROHA**（[PONWRT-ALL](.github/workflows/PONWRT-ALL.yml)）：[zhoufla/ponwrt](https://github.com/zhoufla/ponwrt) `master`，Release 页展示的「源码/分支/提交」即实际编译所用源码

其余平台（IPQ53XX、IPQ95XX、MediaTek、Rockchip、X86）已停止定期编译；对应 `Config/*.txt` 保留，可通过 [WRT-TEST](.github/workflows/WRT-TEST.yml) 手动校验配置。

# 机型说明

| 工作流 | 平台 | 机型 |
|---|---|---|
| QCA-ALL | IPQ60XX | 京东云无线宝 RE-SS-01（亚瑟 AX1800 Pro）、RE-CS-02（雅典娜 AX6600）、RE-CS-07（太乙，仅 WIFI-NO） |
| | IPQ807X | 阿里云 AP8220 |
| LIBWRT-ALL | IPQ60XX | 同 QCA-ALL（NSS 加速版） |
| | IPQ807X | 同 QCA-ALL（NSS 加速版） |
| PONWRT-ALL | Airoha AN7581 | [ponwrt](https://github.com/zhoufla/ponwrt) 源码：AN7581 全系机型（10G PON + 2.5G LAN + NPU 硬件加速） |
| | Airoha AN7583 | Nokia XG-040G-MF（含 UBI 与非 UBI 版本） |

> IPQ60XX 固件文件名按 profile 命名：`jdcloud_re-ss-01-*`（亚瑟）、`jdcloud_re-cs-02-*`（雅典娜）、`jdcloud_re-cs-07-*`（太乙）。
> 太乙（RE-CS-07）无无线硬件，仅在 WIFI-NO 版本中产出（与上游配置一致）；AX6000 百里（MT7986A 平台）不在编译范围。

PONWRT-ALL 的配置与 QCA-ALL 一样按机型与插件拆分维护：`Config/PONWRT-AN7581.txt` / `Config/PONWRT-AN7583.txt` 仅保留机型选择（`TARGET_MULTI_PROFILE` + `TARGET_ALL_PROFILES`，一次编译产出该平台全部机型固件），插件集中在 ponwrt 专用的 `Config/GENERAL-PONWRT.txt`（与 QCA 平台用的 `GENERAL.txt` 分开维护，pon 驱动/用户态 feed 保持开启），由 WRT-CORE 按 `WRT_GENERAL_FILE` 指定的通用文件合并后 `make defconfig` 补全；插件集与上方清单相同，默认主题同为 aurora。

PONWRT-ALL 固件在状态概览页的「CPU 使用率 (%)」行展示 `USR/SYS/PPE` 负载与 Airoha PPE 流表占用，例如 `USR: 6% SYS: 4% PPE: 0/32768 (IPv4: 0 IPv6: 0)`（AN7581 流表容量 32768，AN7583 为 24576）。数据由 ponwrt 的 `target/linux/airoha/base-files/sbin/cpuusage` 提供，首次启动时经 `etc/uci-defaults/992_set-ppe-load.sh` 接入 luci 的 getCPUUsage RPC；在 LuCI「网络 → 防火墙」开启硬件加速（`flow_offloading_hw`）后 PPE/NPU 参与转发，PPE 占用值随之增长。

LIBWRT-ALL 使用 [LiBwrt/LibWrt](https://github.com/LiBwrt/LibWrt) 的 `25.12-nss` 分支（OpenWrt 主干 + JiaY-shi/qosmio 的 NSS 支持 + ImmortalWrt 的 LuCI/Packages，kernel 6.12）。NSS 相关包（`kmod-qca-nss-ecm`、`kmod-qca-nss-drv` 全家桶、`nss-firmware-*`、`kmod-qca-nss-dp`）由源码 `qualcommax` 的 `DEFAULT_PACKAGES` 默认提供，配置里不需要重复勾选。插件集与 QCA-ALL 共用 `Config/GENERAL.txt`，平台差异只放在 `Config/LIBWRT.txt`（由 `WRT_EXTRA_CONFIG` 在机型配置与通用配置之后追加）：

- NSS 内存档位 / 固件版本：`IPQ_MEM_PROFILE_256`、`NSS_MEM_PROFILE_HIGH`、`NSS_FIRMWARE_VERSION_11_4`、SKB recycler（取值参考 [ZqinKing/wrt_release](https://github.com/ZqinKing/wrt_release) 的 nss 片段）；
- NSS 常用模块：PPPoE / IGS / L2TPv2 / PPTP / LAG；
- 全锥 NAT：改用 LibWrt 自带的 firewall4 fullcone 补丁（`CONFIG_PACKAGE_kmod-nft-fullcone`，fw4 的 `defaults.fullcone` 开关），不使用 VIKINGYFY 源码专有的 `fullconenat-sonic`。

WIFI-NO 版本的差异：LibWrt 主线没有 `ipq6018/ipq8074-nowifi.dtsi`，构建时由 `Scripts/Settings.sh` 把 `DTS/ipq6018-nowifi.dtsi`（只含 `&q6_region` 覆写，故意不带 `#include`）拷入 dts 目录并追加到设备 dts 末尾，把 Q6 保留内存从 85MB（512M 档 55MB）缩到 8MB；设备 dts 结构与预期不符时自动跳过，仅保留「移除 ath11k 包」，构建不中断。IPQ807X（AP8220）暂不做 DTS 覆写，只剥 WiFi 包。

IPQ60XX / IPQ807X 每种机型发布两个版本：

- **WIFI-YES**：带 WiFi 驱动，正常无线路由用法
- **WIFI-NO**：去除 WiFi 驱动并将 DTS 替换为 nowifi 版本，释放 Q6 固件内存，适合有线路由 / 旁路由用法

# 插件说明

固件内包含的核心插件（完整清单及内核组件见 [docs/PLUGINS.md](docs/PLUGINS.md)）：

| 分类 | 插件 |
|---|---|
| 代理 | `luci-app-homeproxy`（sing-box 内核，唯一代理入口，已移除 passwall） |
| 内网穿透 | `luci-app-natmapt`（zhoufla fork）+ `natmapt-notify-script-telegram`（端口变更 Telegram 通知）+ `stuntman-client` |
| 网络 | `luci-app-ddns-go`、`luci-app-upnp`、`luci-app-zerotier`、`luci-proto-wireguard` |
| 存储 / 共享 | `luci-app-samba4`、`luci-app-mini-diskmanager`、`luci-app-msd_lite`（IPTV 组播转单播）、`automount` |
| 设备维护 | `luci-app-wolultra`、`luci-app-autoreboot`、`luci-app-uhttpd` |
| 界面 | `luci-theme-aurora` + `aurora-config`、简体中文语言包 |

- PONWRT 平台额外包含 `luci-app-airoha-npu`（Airoha SoC 状态：NPU/PPE/CPU；由 `Scripts/Packages.sh` 从 `luanmuc/luci-app-airoha-npu` 拉取，仅 airoha 目标启用）。

- 内核侧包含 nftables 全功能集、FullCone NAT、WireGuard/tun、USB 网卡与存储、NVMe / SATA、btrfs 等，按功能分类的明细见 [docs/PLUGINS.md](docs/PLUGINS.md)。
- 明确不编译：`vlmcsd`、`wol`（被 wolultra 取代）、`attendedsysupgrade`。
- 部分插件（openclash、mosdns、qbittorrent、多主题等）仅克隆备用、默认不编译，可手动编译时启用，或通过手动触发工作流的 **PACKAGE** 参数临时追加。

# 目录说明

| 目录 | 内容 |
|---|---|
| `.github/workflows` | CI 工作流（WRT-CORE 为公用编译核心） |
| `Scripts` | 插件拉取、设置、修补脚本 |
| `Patches` | 构建时自动应用到源码的补丁（当前为空，预留） |
| `DTS` | WIFI-NO 用的 DTS 覆写片段（`ipq6018-nowifi.dtsi`），由 `Scripts/Settings.sh` 在构建时拷入源码树并追加到设备 dts |
| `CustomPackages` | 源码树缺失时自动补入的本地软件包（当前为空，预留） |
| `Files` | 构建时注入固件的额外文件（仅 qualcommax）：PCDN IPv6 放行规则与 hotplug，`etc/sysctl.d/99-pcdn-conntrack-qca.conf`（UDP 连接跟踪 30/60） |
| `Config` | 各平台 .config 配置（每周仅编译 IPQ60XX/IPQ807X 与 PONWRT，其余保留供 WRT-TEST 手动校验） |
| `docs` | 插件清单等文档 |
