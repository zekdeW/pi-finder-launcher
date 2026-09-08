// make_icon.swift — 官方 pi logo SVG → 指定尺寸透明底 PNG
//
// 用法: swift make_icon.swift <input.svg> <output.png> <size>
//
// 说明:
//   - macOS 11+ 的 NSImage 原生支持 SVG，按 viewBox 等比绘制，天然保留透明通道
//   - 官方 logo 的 viewBox 为 800×800，图形本身只占中间约 59%（自带留白），
//     符合 macOS 图标 proportions，无需额外加 padding
//   - 输出后回读两个采样点打印到 stdout，用于构建脚本自检：
//       sample(45%,25%) 应为灰色填充（P 顶部），sample(45%,75%) 应为全透明
//       （同时验证渲染方向正确：若两点结果互换说明发生了上下翻转）

import AppKit

let args = CommandLine.arguments
guard args.count >= 4, let size = Int(args[3]), size > 0 else {
    FileHandle.standardError.write("Usage: make_icon.swift <input.svg> <output.png> <size>\n".data(using: .utf8)!)
    exit(2)
}
let (svgPath, pngPath) = (args[1], args[2])
let px = CGFloat(size)

guard let image = NSImage(contentsOfFile: svgPath) else {
    FileHandle.standardError.write("错误: NSImage 无法加载 SVG（需要 macOS 11+）\n".data(using: .utf8)!)
    exit(1)
}

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0) else {
    FileHandle.standardError.write("错误: 创建位图失败\n".data(using: .utf8)!)
    exit(1)
}
rep.size = NSSize(width: px, height: px)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: px, height: px),
           from: NSRect.zero,
           operation: .sourceOver,
           fraction: 1.0)
NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("错误: PNG 编码失败\n".data(using: .utf8)!)
    exit(1)
}
do {
    try pngData.write(to: URL(fileURLWithPath: pngPath))
} catch {
    FileHandle.standardError.write("错误: 写入 PNG 失败: \(error)\n".data(using: .utf8)!)
    exit(1)
}

// 自检采样: (45%,25%) 实心 / (45%,75%) 透明
func sample(_ fx: Double, _ fy: Double) -> String {
    let x = Int(px * fx), y = Int(px * fy)
    guard let c = rep.colorAt(x: x, y: y) else { return "nil" }
    let r = Int(round(c.redComponent * 255))
    let g = Int(round(c.greenComponent * 255))
    let b = Int(round(c.blueComponent * 255))
    let a = Int(round(c.alphaComponent * 255))
    return "(\(x),\(y))=#\(String(format: "%02X%02X%02X%02X", r, g, b, a))"
}
print("sample \(sample(0.45, 0.25)) \(sample(0.45, 0.75))")
