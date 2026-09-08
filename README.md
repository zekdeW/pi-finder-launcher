# pi-finder-launcher

访达工具栏的「Pi 启动按钮」：点击后在**访达当前目录**打开终端并运行 `pi`。

图标为 [pi.dev](https://pi.dev) 官方 logo（像素风 "pi" 字标）的灰色透明底版本。

## 使用

1. `./build.sh` 构建并安装到 `/Applications/Pi.app`
2. 打开访达 → 应用程序，**按住 ⌘ 把 Pi 拖到访达工具栏**（一次性手动操作）
3. 在任意目录的访达窗口点击 π 按钮 → 自动打开 Terminal.app 并在该目录运行 pi

行为细节：
- 点击时无选中项 → 用最前访达窗口的目录
- 点击时有选中项 → 文件夹用其本身，文件用其所在目录
- 没有访达窗口 → 回退到主目录
- pi 是 TUI，退出后 shell 保留

## 构建

```bash
./build.sh                  # 默认灰色 #8E8E93
GRAY=6E6E73 ./build.sh      # 深一档的灰
```

流程：拉取官方 SVG（离线用 `assets/pi-logo-official.svg` 兜底）→ 本地改色 →
`scripts/make_icon.swift`（NSImage 渲染 SVG，需 macOS 11+）渲染 iconset 全尺寸 →
`iconutil` 打包 icns → `osacompile` 编译 `src/pi-launcher.applescript` → 覆盖图标 → 安装。

## 自定义

| 想改什么 | 改哪里 |
|----------|--------|
| 灰色深浅 | `GRAY=<hex> ./build.sh` |
| 用 iTerm2 而非 Terminal | `src/pi-launcher.applescript` 末尾 `launchPi`（文件内有现成注释模板） |
| 应用名 | `build.sh` 顶部 `APP_NAME` |
| 打开新标签而非新窗口 | AppleScript 资源：`do script ... in window 1` |

## 目录结构

```
├── build.sh                     # 一键构建
├── src/pi-launcher.applescript  # 按钮逻辑（AppleScript）
├── scripts/make_icon.swift      # SVG → 透明 PNG（含渲染自检）
├── assets/pi-logo-official.svg  # 官方 logo 离线兜底
└── build/                       # 构建中间产物（.gitignore）
```
