#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 zhoufla

#将 Patches/ 目录下的补丁应用到源码树（当前目录为源码根）
#补丁按 -p1 相对 luci-mod-status 包目录（modules/luci-mod-status）编写，
#仅 PONWRT 构建需要（Airoha NPU 状态展示）

PATCH_DIR="$GITHUB_WORKSPACE/Patches"

[ -d "$PATCH_DIR" ] || exit 0
[[ "${WRT_CONFIG^^}" == PONWRT-* ]] || exit 0

for PATCH in "$PATCH_DIR"/*.patch; do
	[ -f "$PATCH" ] || continue

	NAME=$(basename "$PATCH")

	if git -C feeds/luci apply --directory=modules/luci-mod-status --reverse --check "$PATCH" >/dev/null 2>&1; then
		echo "$NAME: already applied"
	elif git -C feeds/luci apply --directory=modules/luci-mod-status "$PATCH"; then
		echo "$NAME: applied"
	else
		echo "$NAME: apply failed, skipped!"
	fi
done
