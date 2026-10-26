# OpenWRT-CI

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 的自用云编译项目，每天北京时间 5:21 自动编译 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) `owrt` 分支并发布 Release；[PONWRT-ALL](.github/workflows/PONWRT-ALL.yml) 同时每日编译 [zhoufla/ponwrt](https://github.com/zhoufla/ponwrt) `master`。

# 机型说明

| 工作流 | 平台 | 机型 |
|---|---|---|
| QCA-ALL | IPQ807X | 阿里云 AP8220 |
| | IPQ60XX | 京东云 RE-CS-02（亚瑟）、RE-CS-07（百里）、RE-SS-01 |
| QCB-ALL | IPQ53XX | 京东云 RE-CS-06、RE-CS-08，小米 BE3600 Pro（P5/P8）、BE6500 |
| | IPQ95XX | 小米 BE7000、BE7000 Pro，Askey SBE1V1K，Nokia Beacon 10 |
| MTK-ALL | MediaTek Filogic | 上游全量机型（小米 / 华硕 / GL.iNet / TP-LINK / 京东云等 70+） |
| OWRT-ALL | Rockchip | NanoPi R2S/R4S/R5S/R6S、NanoPC-T4/T6、FastRhino R66S/R68S、Radxa E20C/E25/E52C、OrangePi 5 系列等 26 款 |
| | X86_64 | 通用 x86_64（含 mt7915/7921/7925 PCIe 网卡驱动） |
| | Airoha AN7581 | 全部配置 |
| PONWRT-ALL | Airoha AN7581 | [ponwrt](https://github.com/zhoufla/ponwrt) 源码：Nokia XG-040G-MD (UBI)，10G PON + 2.5G LAN + NPU 硬件加速 |

PONWRT-ALL 使用 ponwrt 源码自带的完整 `.config`（`Config/PONWRT-AN7581.txt`，与本地已验证构建一致，不追加 GENERAL.txt），插件集与上方清单相同，默认主题同为 aurora。

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

- 内核侧包含 nftables 全功能集、FullCone NAT、WireGuard/tun、USB 网卡与存储、NVMe / SATA、btrfs 等，按功能分类的明细见 [docs/PLUGINS.md](docs/PLUGINS.md)。
- 明确不编译：`vlmcsd`、`wol`（被 wolultra 取代）、`attendedsysupgrade`。
- 部分插件（openclash、mosdns、qbittorrent、多主题等）仅克隆备用、默认不编译，可手动编译时启用，或通过手动触发工作流的 **PACKAGE** 参数临时追加。

# 目录说明

| 目录 | 内容 |
|---|---|
| `.github/workflows` | CI 工作流（WRT-CORE 为公用编译核心） |
| `Scripts` | 插件拉取、设置、修补脚本 |
| `Config` | 各平台 .config 配置 |
| `docs` | 插件清单等文档 |
