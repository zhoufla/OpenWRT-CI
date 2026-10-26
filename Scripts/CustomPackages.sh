#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 zhoufla

#安装 CustomPackages/ 下的本地软件包（源码树中已有同名包时跳过，
#避免覆盖 ponwrt 源码自带的同名包）

CUSTOM_DIR="$GITHUB_WORKSPACE/CustomPackages"

[ -d "$CUSTOM_DIR" ] || exit 0

mkdir -p ./package

for SRC in "$CUSTOM_DIR"/*/; do
	[ -d "$SRC" ] || continue

	NAME=$(basename "$SRC")

	if [ -d "./package/$NAME" ]; then
		echo "$NAME: already provided by source tree, skipped"
	elif cp -rf "${SRC%/}" "./package/"; then
		echo "$NAME: installed from CustomPackages"
	else
		echo "$NAME: install failed!"
	fi
done
