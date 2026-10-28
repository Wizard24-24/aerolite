import AppKit

// Renders AeroLite's app icon and writes an .iconset directory for `iconutil`.
//
// Drawn rather than shipped as a binary asset so the icon stays in source control as code and can
// be regenerated at any size. The mark is the product: one tall pane on the left, two stacked
// panes on the right — a tiling layout, which is exactly what the app does.

func drawIcon(in size: CGFloat) -> NSBitmapImageRep {
    let px = Int(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let ctx = NSGraphicsContext.current!.cgContext

    // macOS app icons sit on a squircle with a little breathing room around it.
    let inset = size * 0.045
    let body = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = size * 0.225
    let squircle = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)

    // Soft vertical gradient, dark slate — reads well on both light and dark docks.
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.13, green: 0.14, blue: 0.18, alpha: 1),
        NSColor(srgbRed: 0.22, green: 0.24, blue: 0.30, alpha: 1),
    ])!
    gradient.draw(in: squircle, angle: -90)

    // No hairline rim: macOS masks and shades icons itself, and a 1px stroke disappears below
    // 32 px — leaving only a muddy double edge at the sizes people actually see.

    // Panes: one tall left, two stacked right.
    let area = body.insetBy(dx: size * 0.155, dy: size * 0.155)
    let gap = size * 0.052
    let paneRadius = size * 0.028

    let leftWidth = area.width * 0.52 - gap / 2
    let rightX = area.minX + leftWidth + gap
    let rightWidth = area.maxX - rightX
    let rightHalf = (area.height - gap) / 2

    func pane(_ rect: NSRect, alpha: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: paneRadius, yRadius: paneRadius)
        NSColor(srgbRed: 0.98, green: 0.99, blue: 1.0, alpha: alpha).setFill()
        path.fill()
    }

    pane(NSRect(x: area.minX, y: area.minY, width: leftWidth, height: area.height), alpha: 0.95)
    pane(NSRect(x: rightX, y: area.minY + rightHalf + gap, width: rightWidth, height: rightHalf), alpha: 0.82)
    pane(NSRect(x: rightX, y: area.minY, width: rightWidth, height: rightHalf), alpha: 0.86)

    // A single accent pane, so the mark has one point of colour.
    let accent = NSBezierPath(roundedRect: NSRect(x: rightX, y: area.minY, width: rightWidth, height: rightHalf),
                              xRadius: paneRadius, yRadius: paneRadius)
    NSColor(srgbRed: 0.35, green: 0.65, blue: 1.0, alpha: 1.0).setFill()
    accent.fill()

    _ = ctx
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// The sizes iconutil expects for a complete .iconset.
let variants: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for variant in variants {
    let rep = drawIcon(in: variant.pixels)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    let path = (outputDir as NSString).appendingPathComponent("\(variant.name).png")
    try? data.write(to: URL(fileURLWithPath: path))
}

print("wrote \(variants.count) sizes to \(outputDir)")
