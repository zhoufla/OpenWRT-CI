# 项目规则

## 修改代码前先同步远端

- 动手修改任何文件前，先 `git fetch origin` 并确认本地与 `origin/main` 一致；落后则 `git pull --rebase`，有冲突先解决再改。
- 提交推送前再次 fetch 确认远端没有新提交；推送被拒（fetch first）时先 rebase 整合远端变更再推，禁止 `--force`。
- 本仓库每天有定时构建（北京时间 5:21），任何推送都会影响下一轮编译，推送前确认改动意图明确、提交信息写清原因。

## 环境备注

- 本机 `/etc/ssh` 配置属主异常，直接 push/fetch 会报 `Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`；统一使用 `GIT_SSH_COMMAND='ssh -F ~/.ssh/config' git fetch/push ...` 绕过系统级 ssh 配置。

## 项目决策（勿随上游漂移）

- 每日编译仅保留：QCA-ALL（IPQ60XX、IPQ807X，`VIKINGYFY/immortalwrt` `owrt`）与 PONWRT-ALL（AIROHA AN7581/AN7583，`zhoufla/ponwrt` `master`）；其余平台（IPQ53XX、IPQ95XX、MediaTek、Rockchip、X86）不编。
- AIROHA 平台固件统一由 PONWRT-ALL 用 zhoufla/ponwrt 源码发布，不采用上游 VIKINGYFY 源码的 AIROHA 构建（`AIROHA-ALL.yml`），避免同源重复编译。
- 默认主题保持 aurora + aurora-config，不跟随上游换 vantage；`Settings.sh` 中主题配套应用行保留（aurora 无对应包时 defconfig 自动忽略）。
- Release 页「源码/分支/提交」必须展示实际 clone 编译的源码（WRT-CORE 从真实 clone 取值，勿改回硬编码）。
- 停编平台的 `Config/*.txt` 保留，供 WRT-TEST 手动校验，不删除。
- 同步上游 VIKINGYFY/OpenWRT-CI 时按需 cherry-pick / 手动合并，不整仓 merge，避免带回已删除的工作流与不需要的平台。
