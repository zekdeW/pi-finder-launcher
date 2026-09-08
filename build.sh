#!/bin/bash
# build.sh — 一键构建访达工具栏 Pi 启动按钮
#
# 用法:
#   ./build.sh                 # 默认灰色 #8E8E93，安装到 /Applications/Pi.app
#   GRAY=6E6E73 ./build.sh     # 自定义灰色（不带 # 的 6 位 hex）
#
# 产物: /Applications/Pi.app（图标=官方 pi logo 灰色透明底）
# 之后手动: 在访达按住 ⌘ 把 /Applications/Pi.app 拖到工具栏

set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Pi"
GRAY="$(echo "${GRAY:-8E8E93}" | tr '[:lower:]' '[:upper:]' | tr -d '#')"
OUT_APP="/Applications/${APP_NAME}.app"

mkdir -p build assets

# ── 1. 获取官方 logo（网络失败时用本地兜底） ─────────────────────────
if curl -fsSL --max-time 15 https://pi.dev/logo-auto.svg -o build/pi-logo.svg 2>/dev/null; then
    echo "✅ 官方 logo 已从 pi.dev 获取"
else
    echo "⚠️  网络不可用，使用本地兜底 logo"
    cp assets/pi-logo-official.svg build/pi-logo.svg
fi

# ── 2. 去掉自适应配色，改为固定灰色（保留透明底） ─────────────────────
python3 - "$GRAY" <<'PYEOF'
import re, sys
gray = sys.argv[1]
path = "build/pi-logo.svg"
svg = open(path).read()
svg = re.sub(r"<style>.*?</style>",
             f"<style>.logo-mark {{ fill: #{gray}; }}</style>",
             svg, flags=re.S)
open(path, "w").write(svg)
PYEOF
echo "🎨 已改色为灰色 #$GRAY"

# ── 3. 渲染 iconset 各尺寸（矢量直接出图，小尺寸更锐利） ──────────────
# swiftc 只编译一次（swift 脚本模式每次解释执行要 20s+，11 次渲染不可接受）
echo "🔧 编译图标渲染工具..."
swiftc -O scripts/make_icon.swift -o build/make_icon
ICONSET="build/${APP_NAME}.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    build/make_icon build/pi-logo.svg "$ICONSET/icon_${s}x${s}.png" "$s" | sed "s/^/   [${s}px]  /"
    build/make_icon build/pi-logo.svg "$ICONSET/icon_${s}x${s}@2x.png" $((s * 2)) | sed "s/^/   [$((s*2))px] /"
done

# 自检: (45%,25%) 应为灰色填充、(45%,75%) 应透明（防全透明/全填充/上下翻转）
SAMPLE_OUT=$(build/make_icon build/pi-logo.svg "$ICONSET/icon_512x512.png" 512)
echo "   自检: $SAMPLE_OUT"
echo "$SAMPLE_OUT" | grep -q "#${GRAY}FF" || { echo "❌ 期望的灰色填充未出现在采样点，中止"; exit 1; }
echo "$SAMPLE_OUT" | grep -q "#00000000" || { echo "❌ 期望的透明区域未出现（可能全图被填充），中止"; exit 1; }

iconutil -c icns "$ICONSET" -o "build/${APP_NAME}.icns"
echo "✅ icns 已生成"

# ── 4. 编译 AppleScript 为 app ────────────────────────────────────────
rm -rf "build/${APP_NAME}.app"
osacompile -o "build/${APP_NAME}.app" src/pi-launcher.applescript

# ── 5. 替换图标（osacompile 的 Info.plist 指向 droplet.icns，两个都覆盖） ──
cp "build/${APP_NAME}.icns" "build/${APP_NAME}.app/Contents/Resources/droplet.icns"
cp "build/${APP_NAME}.icns" "build/${APP_NAME}.app/Contents/Resources/applet.icns"
touch "build/${APP_NAME}.app"

# ── 6. 安装到 /Applications ───────────────────────────────────────────
if [ -d "$OUT_APP" ]; then
    echo "ℹ️  已存在 ${OUT_APP}，替换"
    rm -rf "$OUT_APP"
fi
cp -R "build/${APP_NAME}.app" "$OUT_APP"
touch "$OUT_APP"

echo ""
echo "🎉 构建完成: $OUT_APP"
echo "   最后一步（手动）: 打开访达 → 应用程序，按住 ⌘ 把 Pi 拖到工具栏"
echo "   重新构建:  GRAY=6E6E73 ./build.sh   （换深一档的灰色）"
